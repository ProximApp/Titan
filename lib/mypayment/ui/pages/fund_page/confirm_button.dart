import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/providers/fund_amount_provider.dart';
import 'package:titan/mypayment/providers/funding_url_provider.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/providers/my_wallet_provider.dart';
import 'package:titan/mypayment/providers/tos_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/web-window-callback/web_window_with_callback.dart';
import 'package:url_launcher/url_launcher.dart';

/// Signature of the popup launcher this button hands the HelloAsso URL to.
///
/// The shim is a conditional import: off the browser it resolves to
/// `else.dart`, whose only statement is a throw. So `helloAssoCallback` — the
/// entire web top-up, success and cancelled and blocked-popup alike — could
/// never run in a VM test. This typedef is the seam those tests inject
/// through; production keeps passing the real shim.
typedef FundWebWindowOpener = void Function(
  String windowUrl,
  String windowName, {
  required void Function() completerFutureCallback,
  required Future<void> Function(String) loginCallback,
  void Function()? popupBlockedCallback,
});

class ConfirmFundButton extends ConsumerWidget {
  /// Whether the browser flow is in play. Defaults to [kIsWeb]; the override
  /// exists so the VM test run can reach the web top-up — the redirect URL
  /// that sends the payment provider back to the site, and the HelloAsso
  /// popup callback — which `kIsWeb` makes unreachable there.
  final bool? isWeb;

  /// Opens the HelloAsso popup. Defaults to the real conditional-import shim.
  final FundWebWindowOpener? openWindow;

  const ConfirmFundButton({super.key, this.isWeb, this.openWindow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWebPlatform = isWeb ?? kIsWeb;
    final openWindowShim = openWindow ?? webWindowWithCallback;
    // Resolved once, while the element is alive. The HelloAsso callbacks below
    // fire AFTER this button popped its sheet — the popup outlives the widget
    // that opened it — so a `AppLocalizations.of(context)` inside them looks up
    // an ancestor on a deactivated element and throws: on the web the payment
    // would complete and the user would get no confirmation at all.
    final l10n = AppLocalizations.of(context)!;
    final fundAmount = ref.watch(fundAmountProvider);
    final myWalletNotifier = ref.watch(myWalletProvider.notifier);
    final myHistoryNotifier = ref.watch(myHistoryProvider.notifier);
    final fundAmountNotifier = ref.watch(fundAmountProvider.notifier);
    final fundingUrlNotifier = ref.watch(fundingUrlProvider.notifier);
    final myWallet = ref.watch(myWalletProvider);
    final tos = ref.watch(tosProvider);
    final maxBalanceAmount = tos.maybeWhen(
      orElse: () => 0,
      data: (tos) => tos.maxWalletBalance / 100,
    );
    final walletAmount = myWallet.maybeWhen<double?>(
      orElse: () => null,
      data: (wallet) => wallet.balance / 100,
    );
    final currentAmount = walletAmount ?? 0;

    final redirectUrl = isWebPlatform
        ? "${getTitanURL()}/mypayment"
        : "${getTitanURLScheme()}://mypayment";
    final amountToAdd = double.tryParse(fundAmount.replaceAll(",", ".")) ?? 0;

    final minValidFundAmount =
        fundAmount.isNotEmpty &&
        double.parse(fundAmount.replaceAll(',', '.')) >= 1;
    final maxValidFundAmount =
        walletAmount != null && amountToAdd + currentAmount <= maxBalanceAmount;

    void displayToastWithContext(TypeMsg type, String message) {
      displayToast(context, type, message);
    }

    Future<bool> tryLaunchUrl(String url) async {
      final cantLaunchUrlMsg = l10n.paiementCantLaunchURL;
      try {
        if (await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          return true;
        }
      } catch (_) {}
      displayToastWithContext(TypeMsg.error, cantLaunchUrlMsg);
      return false;
    }

    void helloAssoCallback(String fundingUrl) async {
      openWindowShim(
        fundingUrl,
        "HelloAsso",
        completerFutureCallback: () {},
        popupBlockedCallback: () => displayToastWithContext(
          TypeMsg.error,
          l10n.paiementPleaseAcceptPopup,
        ),
        loginCallback: (String data) async {
          final receivedUri = Uri.parse(data);
          final code = receivedUri.queryParameters["code"];
          if (code == "succeeded") {
            displayToastWithContext(
              TypeMsg.msg,
              l10n.paiementProceedSuccessfully,
            );
            myWalletNotifier.getMyWallet();
            myHistoryNotifier.getHistory();
          } else {
            displayToastWithContext(
              TypeMsg.error,
              l10n.paiementCancelledTransaction,
            );
          }
          // The sheet was already popped when the popup opened, so this is
          // only a pop when the button is still on screen (the callback can
          // also run for a sheet the user dismissed in the meantime).
          if (context.mounted) Navigator.pop(context, code);
        },
      );
    }

    return WaitingButton(
      onTap: () async {
        if (!minValidFundAmount) {
          displayToastWithContext(
            TypeMsg.error,
            l10n.paiementPleaseEnterMinAmount,
          );
          return;
        }
        if (!maxValidFundAmount) {
          displayToastWithContext(
            TypeMsg.error,
            "${l10n.paiementMaxAmount} ${maxBalanceAmount.toStringAsFixed(2)}ʍ",
          );
          return;
        }

        final value = await fundingUrlNotifier.getFundingUrl(
          TransferInfo(
            amount: (double.parse(fundAmount.replaceAll(',', '.')) * 100)
                .round(),
            redirectUrl: redirectUrl,
          ),
        );
        value.when(
          data: (fundingUrl) async {
            if (isWebPlatform) {
              // The sheet stays up while HelloAsso's popup is open. Popping it
              // here, before the popup answered, is what broke the web flow:
              // the callback below fires later, on a deactivated element, so
              // its success/cancelled toast could not be built (displayToast
              // resolves its strings from that context) and its
              // `pop(context, code)` was popping a dead element. It now pops
              // once, with the code, when the popup answers.
              helloAssoCallback(fundingUrl.url);
              fundAmountNotifier.setFundAmount("");
              return;
            }
            if (await tryLaunchUrl(fundingUrl.url)) {
              fundAmountNotifier.setFundAmount("");
              if (context.mounted) Navigator.pop(context);
            }
          },
          loading: () {},
          error: (error, _) {
            displayToastWithContext(TypeMsg.error, error.toString());
          },
        );
      },
      waitingColor: const Color(0xff2e2f5e),
      builder: (Widget child) => Container(
        height: 75,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: (minValidFundAmount && maxValidFundAmount)
              ? Colors.white
              : Colors.grey.shade200.withValues(alpha: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(1, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: child,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: SvgPicture.asset(
              'assets/images/helloasso.svg',
              width: 50,
              height: 50,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.paiementPayWithHA,
            style: TextStyle(
              color: (minValidFundAmount && maxValidFundAmount)
                  ? const Color(0xff2e2f5e)
                  : const Color(0xff2e2f5e).withValues(alpha: 0.5),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
