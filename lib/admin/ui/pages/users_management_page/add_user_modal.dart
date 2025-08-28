import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/admin/providers/user_invitation_provider.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/paiement/ui/pages/main_page/account_card/device_dialog_box.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

class AddUsersModalContent extends HookConsumerWidget {
  const AddUsersModalContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFileName = useState<String?>(null);
    final mailList = useState<List<String>>([]);
    final userInvitationNotifier = ref.watch(userInvitationProvider.notifier);

    void displayToastWithContext(TypeMsg type, String msg) {
      displayToast(context, type, msg);
    }

    final localizeWithContext = AppLocalizations.of(context)!;

    final navigatorWithContext = Navigator.of(context);

    return BottomModalTemplate(
      title: localizeWithContext.adminInviteUsers,
      child: Column(
        children: [
          Text(
            localizeWithContext.adminImportUsersDescription,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Button.secondary(
            text: selectedFileName.value ?? localizeWithContext.adminImportList,
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;

                selectedFileName.value = file.name;

                if (file.path != null) {
                  String fileContent = '';
                  if (kIsWeb) {
                    fileContent = file.bytes != null
                        ? String.fromCharCodes(file.bytes!)
                        : '';
                  } else {
                    fileContent = await File(file.path!).readAsString();
                  }
                  mailList.value = fileContent
                      .split('\n')
                      .map((e) => e.split(','))
                      .flattened
                      .where((e) => e.isNotEmpty)
                      .toList();
                }
              }
            },
          ),
          const SizedBox(height: 20),
          Text(
            localizeWithContext.adminInviteUsersCounter(mailList.value.length),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          WaitingButton(
            builder: (child) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: ColorConstants.tertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConstants.onTertiary),
              ),
              child: Center(child: child),
            ),
            onTap: () async {
              if (selectedFileName.value == null) return;
              await tokenExpireWrapper(ref, () async {
                final value = await userInvitationNotifier.createUsers(
                  mailList.value,
                );
                if (value.isEmpty) {
                  displayToastWithContext(
                    TypeMsg.msg,
                    localizeWithContext.adminInvitedUsers,
                  );
                  navigatorWithContext.pop();
                } else {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) => DeviceDialogBox(
                      descriptions: value.map((e) => '- $e').join('\n'),
                      title: AppLocalizations.of(context)!.adminEmailFailed,
                      buttonText: "Compris",
                      onClick: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }
              });
            },
            child: Text(
              localizeWithContext.adminInvite,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withAlpha(selectedFileName.value == null ? 100 : 255),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
