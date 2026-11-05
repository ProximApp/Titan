import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/login/router.dart';
import 'package:titan/navigation/providers/display_quit_popup.dart';
import 'package:titan/service/providers/firebase_token_expiration_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:titan/user/providers/profile_picture_provider.dart';
import 'package:titan/user/providers/user_provider.dart';
import 'package:titan/l10n/app_localizations.dart';

class QuitDialog extends HookConsumerWidget {
  const QuitDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authTokenProvider.notifier);
    final isCachingNotifier = ref.watch(isCachingProvider.notifier);
    final displayQuitNotifier = ref.watch(displayQuitProvider.notifier);
    // The box already paints the dim and its own full-screen detector, so the
    // wrappers this used to carry were never hit: the only live action on the
    // backdrop is closing the prompt, and it must not pop the page under it.
    return CustomDialogBox(
      onBarrierTap: () => displayQuitNotifier.setDisplay(false),
      descriptions: AppLocalizations.of(context)!.drawerLoginOut,
      title: AppLocalizations.of(context)!.drawerLogOut,
      onYes: () async {
        await auth.deleteToken();
        if (!context.mounted) return;
        if (!kIsWeb) {
          ref.watch(firebaseTokenExpirationProvider.notifier).reset();
        }
        isCachingNotifier.set(false);
        // Invalidate user and profile picture providers to clear cached data
        ref.invalidate(asyncUserProvider);
        ref.invalidate(profilePictureProvider);
        displayToast(
          context,
          TypeMsg.msg,
          AppLocalizations.of(context)!.drawerLogOut,
        );
        displayQuitNotifier.setDisplay(false);
        QR.to(LoginRouter.root);
      },
      onNo: () {
        displayQuitNotifier.setDisplay(false);
      },
    );
  }
}
