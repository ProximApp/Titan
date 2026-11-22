import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// AssociationAdminEditionModal — the bottom sheet EditableAssociationCard
/// opens on /phonebook/admin (102 uncovered lines). The journey: card tap →
/// modal → the five actions. The FIRST test is the file's one deferred-route
/// journey (card → Edit → the add-edit form): running it first keeps the
/// middleware chain (and the deferred loadLibrary) alive per convention 10
/// — a later isolate state wedges the route-add without mounting the page.
/// The four other actions open a nested ConfirmModal.danger whose onYes
/// fires the real PATCH/DELETE endpoints; the toasts render through the
/// root-navigator context the modal captures at build time (ledger #29
/// fixed), so the stubs complete normally and the tests assert the toast
/// text.
/// overlaps.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  /// The admin-page list + the fixtures the modal actions read.
  void stubAdminList({bool deactivated = false}) {
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club').copyWith(deactivated: deactivated),
      ]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );
  }

  /// The confirm actions' toasts display through the edition modal's
  /// build-time root-navigator context — completing stubs let onYes
  /// run to the end.
  Future<chopper.Response<void>> okVoid(_) async => chopperResponseVoid();

  Future<void> pumpAdmin(WidgetTester tester, ProviderContainer container) =>
      scaffold.pumpApp(
        tester,
        container,
        initialPath: '${PhonebookRouter.root}${PhonebookRouter.admin}',
        pumpAndSettle: false,
      );

  ProviderContainer adminContainer() => scaffold.makeContainer(
    user: CoreUser.empty().copyWith(
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: phonebookAdminGroupId,
          name: 'admin_phonebook',
        ),
      ],
    ),
  );

  testWidgets('the edit button routes to the pre-filled association form', (
    tester,
  ) async {
    stubAdminList();
    final container = adminContainer();

    await pumpAdmin(tester, container);
    await settle(tester);
    expect(find.text('Robot Club'), findsOneWidget);

    await scaffold.openModal(tester, find.text('Robot Club'));
    // The sheet closes itself, sets associationProvider/associationGroupement
    // and routes to the deferred add-edit page (tapInModal pumps the
    // transitions).
    await scaffold.tapInModal(tester, find.text('Edit'));
    // The deferred add-edit library loads asynchronously: the route is
    // added before the page builds, so pump until the form mounts.
    await settle(tester, frames: 12);

    expect(scaffold.isModalOpen(tester), isFalse);
    // Edit-mode title and submit button are both phonebookEdit ("Edit"),
    // plus the fields prefilled from the selected association (probed by
    // controller value: the fields render EditableText, not Text).
    expect(find.text('Edit'), findsNWidgets(2));
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'Robot Club');
    expect(fields[1].controller!.text, 'We build robots');
    // The selected groupement reached the bar (the modal set it).
    expect(find.text('Clubs'), findsOneWidget);
  });

  testWidgets('the edition modal offers the admin actions for a live '
      'association', (tester) async {
    stubAdminList();
    final container = adminContainer();

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    expect(scaffold.isModalOpen(tester), isTrue);
    // Modal title + card title underneath render the same name.
    expect(find.text('Robot Club'), findsNWidgets(2));
    // Phonebook-admin actions; the plain-admin "Manage groups" branch is
    // not rendered without the full-admin group.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Manage members'), findsOneWidget);
    expect(find.text('Switch to 2027 term'), findsOneWidget);
    expect(find.text('Deactivate association'), findsOneWidget);
    expect(find.text('Manage groups'), findsNothing);

    await scaffold.closeModal(tester);
    expect(scaffold.isModalOpen(tester), isFalse);
  });

  testWidgets('the term-year switch confirms and PATCHes the next mandate', (
    tester,
  ) async {
    stubAdminList();
    final container = adminContainer();
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
        associationId: 'a-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(okVoid);

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Switch to 2027 term'));

    // The nested danger confirm sheet replaced the edition modal.
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Switch to 2027 term'), findsOneWidget);
    expect(find.text('This action is irreversible'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    // Confirm pops the sheet itself before running onYes, so the sheet is
    // gone while the PATCH is in flight.
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    // onYes PATCHed the association with mandateYear + 1 and the success
    // toast renders on the surviving root-navigator context
    final captured =
        verify(
              () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
                associationId: 'a-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as AssociationEdit;
    expect(captured.mandateYear, 2027);
    expect(captured.name, 'Robot Club');
    expect(captured.description, 'We build robots');
    expect(find.text('Association updated'), findsOneWidget);
    expect(scaffold.isModalOpen(tester), isFalse);
    await scaffold.drainToast(tester);
  });

  testWidgets('the live association deactivate button deactivates', (
    tester,
  ) async {
    stubAdminList();
    final container = adminContainer();
    // Ledger #30 fixed: the LIVE association's "Deactivate association"
    // button runs the deactivate PATCH.
    when(
      () =>
          scaffold.repository.phonebookAssociationsAssociationIdDeactivatePatch(
            associationId: 'a-1',
          ),
    ).thenAnswer(okVoid);

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Deactivate association'));

    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('This action is irreversible'), findsOneWidget);

    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    expect(scaffold.isModalOpen(tester), isFalse);
    // Ledger #30 fixed: the deactivate PATCH fires (never the DELETE) and
    // the success toast renders on the surviving context.
    verify(
      () =>
          scaffold.repository.phonebookAssociationsAssociationIdDeactivatePatch(
            associationId: 'a-1',
          ),
    ).called(1);
    verifyNever(
      () => scaffold.repository.phonebookAssociationsAssociationIdDelete(
        associationId: any(named: 'associationId'),
      ),
    );
    expect(find.text('Association deactivated'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the deactivated association delete button deletes', (
    tester,
  ) async {
    stubAdminList(deactivated: true);
    final container = adminContainer();
    // Ledger #30 fixed: the DEACTIVATED association's "Delete association"
    // button runs the DELETE (which requires deactivated=true — reachable
    // now).
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdDelete(
        associationId: 'a-1',
      ),
    ).thenAnswer(okVoid);

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    // The deactivated ternary flips the danger button to the delete label.
    expect(find.text('Delete association'), findsOneWidget);
    expect(find.text('Deactivate association'), findsNothing);
    await scaffold.tapInModal(tester, find.text('Delete association'));

    // The delete description replaces the irreversible-action one.
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(
      find.text('This will erase all association history'),
      findsOneWidget,
    );
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    expect(scaffold.isModalOpen(tester), isFalse);
    verify(
      () => scaffold.repository.phonebookAssociationsAssociationIdDelete(
        associationId: 'a-1',
      ),
    ).called(1);
    verifyNever(
      () =>
          scaffold.repository.phonebookAssociationsAssociationIdDeactivatePatch(
            associationId: any(named: 'associationId'),
          ),
    );
    expect(find.text('Association deleted'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused deactivation reports it instead of claiming success', (
    tester,
  ) async {
    stubAdminList();
    final container = adminContainer();
    // The association stays live because the backend refuses the PATCH: the
    // sheet must say so, and must not print the success toast that would leave
    // the admin believing a live association was retired.
    when(
      () =>
          scaffold.repository.phonebookAssociationsAssociationIdDeactivatePatch(
            associationId: any(named: 'associationId'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Deactivate association'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(find.text('Error during deactivation'), findsOneWidget);
    expect(find.text('Association deactivated'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused delete reports it instead of claiming success', (
    tester,
  ) async {
    stubAdminList(deactivated: true);
    final container = adminContainer();
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdDelete(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Delete association'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(find.text('Error deleting'), findsOneWidget);
    expect(find.text('Association deleted'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused term-year switch reports it instead of moving the '
      'mandate', (tester) async {
    stubAdminList();
    final container = adminContainer();
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Switch to 2027 term'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(find.text('Error during update'), findsOneWidget);
    expect(find.text('Association updated'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a full admin who is not a phonebook admin gets only Manage '
      'groups', (tester) async {
    stubAdminList();
    // The `if (isAdmin)` branch (line 92) needs the FULL-admin group and NOT
    // the phonebook one — every other test in this file seeds
    // phonebookAdminGroupId, so the button and its route were never rendered.
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    addTearDown(container.dispose);

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Manage groups'), findsOneWidget);
    // The phonebook-admin actions are phonebook-only, so they are absent here.
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Manage members'), findsNothing);
    expect(find.text('Deactivate association'), findsNothing);
    expect(find.text('Switch to 2027 term'), findsNothing);

    await scaffold.tapInModal(tester, find.text('Manage groups'));
    await settle(tester, frames: 12);

    // The action pops the sheet and routes to the groups editor.
    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('Manage groups'), findsNothing);
  });

  testWidgets('the Manage members action routes to the membership editor', (
    tester,
  ) async {
    stubAdminList();
    final container = adminContainer();

    await pumpAdmin(tester, container);
    await settle(tester);

    // The button was only ever asserted PRESENT: un-tapped, its onPressed
    // (the association/groupement seeding, the pop and the route) stayed
    // uncovered, so a broken target or a missing provider write would have
    // gone unnoticed.
    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Manage members'));
    await settle(tester, frames: 12);

    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('Manage members'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
