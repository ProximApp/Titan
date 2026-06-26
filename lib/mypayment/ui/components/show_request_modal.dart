import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/providers/payment_requests_provider.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/paiment_delegate_modal.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

Future<void> showRequestModal({
  required BuildContext context,
  required WidgetRef ref,
  required Request$ request,
  VoidCallback? onSuccess,
}) async {
  final keyService = ref.read(keyServiceProvider);
  final paymentRequestsNotifier = ref.read(paymentRequestsProvider.notifier);

  await showCustomBottomModal(
    context: context,
    ref: ref,
    onCloseCallback: () {
      ref.read(navbarVisibilityProvider.notifier).show();
    },
    modal: PaimentDelegateModal(
      itemTitle: request.name,
      itemDescription: request.storeNote ?? '',
      itemPrice: request.total,
      itemExpirationDate: request.expirationDate,
      onConfirm: () async {
        final keyId = await keyService.getKeyId();
        final keyPair = await keyService.getKeyPair();
        if (keyId == null || keyPair == null) {
          if (context.mounted) {
            Navigator.of(context).pop();
            displayToast(
              context,
              TypeMsg.error,
              AppLocalizations.of(context)!.paiementPaymentRequestError,
            );
          }
          return;
        }
        final now = DateTime.now();
        final data = jsonEncode({
          "id": request.id,
          "tot": request.total,
          "iat": now.toUtc().toIso8601String(),
          "key": keyId,
          "store": true,
        });
        final signature = base64Encode(
          (await keyService.signMessage(keyPair, data.codeUnits)).bytes,
        );
        final validation = SignedContent(
          id: request.id,
          tot: request.total,
          iat: now,
          key: keyId,
          store: true,
          signature: signature,
        );
        final success = await paymentRequestsNotifier.acceptRequest(
          request,
          validation,
        );
        if (context.mounted) {
          Navigator.of(context).pop();
          displayToast(
            context,
            success ? TypeMsg.msg : TypeMsg.error,
            success
                ? AppLocalizations.of(context)!.paiementPaymentRequestAccepted
                : AppLocalizations.of(context)!.paiementPaymentRequestError,
          );
          if (success) onSuccess?.call();
          ref.read(navbarVisibilityProvider.notifier).show();
        }
      },
      onRefuse: () async {
        final success = await paymentRequestsNotifier.refuseRequest(request);
        if (context.mounted) {
          Navigator.of(context).pop();
          displayToast(
            context,
            success ? TypeMsg.msg : TypeMsg.error,
            success
                ? AppLocalizations.of(context)!.paiementPaymentRequestRefused
                : AppLocalizations.of(context)!.paiementPaymentRequestError,
          );
          ref.read(navbarVisibilityProvider.notifier).show();
        }
      },
    ),
  );
}
