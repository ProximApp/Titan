import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/ui/pages/users_management_page/users_management_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the users-management sheet and the invite form
/// behind its Add button — `add_user_modal.dart` sat at 0/87 because nothing
/// ever opened the sheet the admin main page wraps it in.
///
/// The page pops the sheet it lives in BEFORE opening its own modal (that is
/// the production wiring in `AdminMainPage`), so these tests mount it inside
/// a bottom sheet exactly like the main page does.
class _GroupListFake extends GroupListNotifier {
  _GroupListFake(this.groups);

  final List<CoreGroupSimple> groups;

  @override
  AsyncValue<List<CoreGroupSimple>> build() => AsyncValue.data(groups);
}

/// Answers every pick with one in-memory CSV, so `PlatformFile.readAsBytes`
/// needs no real file on disk.
class _FakeFilePicker extends FilePickerPlatform {
  _FakeFilePicker(this.result);

  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) async => result;
}

void main() {
  late IntegrationScaffold scaffold;
  late FilePickerPlatform realPicker;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    realPicker = FilePickerPlatform.instance;
  });

  tearDown(() => FilePickerPlatform.instance = realPicker);

  ProviderContainer containerWith({List<CoreGroupSimple> groups = const []}) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        allGroupListProvider.overrideWith(() => _GroupListFake(groups)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> openManagement(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      Consumer(
        builder: (context, ref, _) => ElevatedButton(
          onPressed: () => showCustomBottomModal(
            context: context,
            ref: ref,
            modal: BottomModalTemplate(
              title: 'Users management',
              child: UsersManagementPage(),
            ),
          ),
          child: const Text('open management'),
        ),
      ),
      container,
    );
    await tester.tap(find.text('open management'));
    await tester.pumpAndSettle();
  }

  Future<void> openInviteForm(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await openManagement(tester, container);
    await tester.tap(find.widgetWithText(Button, 'Add'));
    await tester.pumpAndSettle();
  }

  void fakePick(String csv) {
    final bytes = utf8.encode(csv);
    FilePickerPlatform.instance = _FakeFilePicker(
      FilePickerResult([
        PlatformFile(name: 'users.csv', size: bytes.length, bytes: bytes),
      ]),
    );
  }

  /// toastification's auto-close is a 2500ms timer; let it fire so the test
  /// does not end with a pending timer.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
  }

  testWidgets('Add swaps the management sheet for the invite form', (
    tester,
  ) async {
    final container = containerWith();
    await openManagement(tester, container);

    expect(find.widgetWithText(Button, 'Add'), findsOneWidget);
    expect(find.widgetWithText(Button, 'Delete'), findsOneWidget);

    await tester.tap(find.widgetWithText(Button, 'Add'));
    await tester.pumpAndSettle();

    // The management sheet popped first, then the invite form opened.
    expect(find.text('Users management'), findsNothing);
    expect(find.text('Invite users'), findsOneWidget);
    expect(find.text('Import a list'), findsOneWidget);
    expect(find.text('No group'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
    expect(find.text('No user in the CSV file'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete opens the danger modal with its confirm disabled', (
    tester,
  ) async {
    final container = containerWith();
    await openManagement(tester, container);

    await tester.tap(find.widgetWithText(Button, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete users'), findsOneWidget);
    expect(find.text('Import a list'), findsOneWidget);
    // The confirm arm is rendered but must stay disabled — an enabled Delete
    // here would fire a dead handler.
    final confirm = tester.widget<Button>(
      find.widgetWithText(Button, 'Delete'),
    );
    expect(confirm.disabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('importing a CSV counts the addresses and shows the file', (
    tester,
  ) async {
    fakePick('ada@lovelace.fr,alan@turing.uk\nzoe@example.com\n');
    final container = containerWith();
    await openInviteForm(tester, container);

    await tester.tap(find.text('Import a list'));
    await tester.pumpAndSettle();

    expect(find.text('users.csv'), findsOneWidget);
    expect(find.text('3 users in the CSV file'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the group picker fills the row with the chosen group', (
    tester,
  ) async {
    final container = containerWith(
      groups: [
        CoreGroupSimple.empty().copyWith(id: 'g1', name: 'BDE'),
        CoreGroupSimple.empty().copyWith(id: 'g2', name: 'BDS'),
      ],
    );
    await openInviteForm(tester, container);

    await tester.tap(find.text('No group'));
    // The picker waits 150ms before opening.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Choose a group'), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('BDS'), findsOneWidget);

    // The picker rows are whole ListItems (no plus icon, unlike the
    // membership modal's picker): tapping the name records the choice.
    await tester.tap(find.text('BDE'));
    await tester.pumpAndSettle();

    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('BDS'), findsNothing);
    expect(find.text('No group'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inviting without a picked file posts nothing', (tester) async {
    final container = containerWith();
    await openInviteForm(tester, container);

    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    verifyNever(
      () =>
          scaffold.repository.usersBatchCreationPost(body: any(named: 'body')),
    );
    // The form stays open: nothing happened.
    expect(find.text('Invite users'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a clean batch posts every address and toasts', (tester) async {
    List<CoreBatchUserCreateRequest>? sent;
    when(
      () =>
          scaffold.repository.usersBatchCreationPost(body: any(named: 'body')),
    ).thenAnswer((inv) async {
      sent = inv.namedArguments[#body] as List<CoreBatchUserCreateRequest>?;
      return scaffold.repository.ok(BatchResult.empty());
    });

    fakePick('ada@lovelace.fr,alan@turing.uk\n');
    final container = containerWith();
    await openInviteForm(tester, container);

    await tester.tap(find.text('Import a list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    expect(sent, hasLength(2));
    expect(sent!.first.email, 'ada@lovelace.fr');
    expect(sent!.first.defaultGroupId, isNull);
    expect(sent!.last.email, 'alan@turing.uk');
    // Success: toast + the form closed behind it.
    expect(find.text('Invited users'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Invite users'), findsNothing);

    await drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rejected address opens the per-email dialog', (tester) async {
    when(
      () =>
          scaffold.repository.usersBatchCreationPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(
        BatchResult(failed: {'dup@x.fr': 'already exists'}),
      ),
    );

    fakePick('ada@lovelace.fr,dup@x.fr\n');
    final container = containerWith();
    await openInviteForm(tester, container);

    await tester.tap(find.text('Import a list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to send email to the following addresses'),
      findsOneWidget,
    );
    expect(find.text('- dup@x.fr'), findsOneWidget);
    // The form is still under the dialog.
    expect(find.text('Invite users'), findsOneWidget);

    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to send email to the following addresses'),
      findsNothing,
    );
    // DeviceDialogBox's button runs onClick (which pops the dialog) AND
    // pops a second time itself — so dismissing this dialog closes the
    // invite sheet behind it too. The failure branch itself never pops
    // (that is what the pre-dismiss assertion above pins); this is the
    // dialog widget's double-pop, on screen.
    expect(find.text('Invite users'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
