import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

/// AssociationAdminEditionModal — the bottom sheet EditableAssociationCard
/// opens on /phonebook/admin (102 uncovered lines). The journey: card tap →
/// modal → the five actions. The FIRST test is the file's one deferred-route
/// journey (card → Edit → the add-edit form): running it first keeps the
/// middleware chain (and the deferred loadLibrary) alive per convention 10
/// — a later isolate state wedges the route-add without mounting the page.
/// The four other actions open a nested ConfirmModal.danger whose onYes
/// fires the real PATCH/DELETE endpoints; their success toasts are broken
/// (ledger #29, hence the never-completing stubs). The deactivate/delete
/// wiring was crossed (ledger #30) and is now FIXED: live → deactivate
/// PATCH, deactivated → DELETE, asserted below. The admin shell render
/// itself lives in phonebook_admin_integration_test.dart — nothing
/// overlaps.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  /// The admin-page list + the fixtures the modal actions read.
  void stubAdminList({bool deactivated = false}) {
    stubPhonebookPictures(scaffold);
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

  /// The confirm actions' success/failure toasts display through the
  /// edition sheet's context, which the sheet popped BEFORE onYes ran — the
  /// l10n lookup on the deactivated element throws a ZONE-uncaught error in
  /// debug (README ledger #29, same family as #21; release silently drops
  /// the toast). That error path cannot be absorbed by FlutterError.onError
  /// filters (the binding asserts on any override plus an uncaught zone
  /// error), so the endpoint stubs below never complete: the wire call is
  /// recorded for verification, and the dead toast continuation never
  /// resumes.
  Future<chopper.Response<void>> neverCompleting(_) =>
      Completer<chopper.Response<void>>().future;

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
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

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
    ).thenAnswer(neverCompleting);

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
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // onYes PATCHed the association with mandateYear + 1 (the success toast
    // is dead code on a popped context, ledger #29).
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
    expect(scaffold.isModalOpen(tester), isFalse);
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
    ).thenAnswer(neverCompleting);

    await pumpAdmin(tester, container);
    await settle(tester);

    await scaffold.openModal(tester, find.text('Robot Club'));
    await scaffold.tapInModal(tester, find.text('Deactivate association'));

    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('This action is irreversible'), findsOneWidget);

    await scaffold.tapInModal(tester, find.text('Confirm'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(scaffold.isModalOpen(tester), isFalse);
    // Ledger #30 fixed: the deactivate PATCH fires, never the DELETE.
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
    ).thenAnswer(neverCompleting);

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
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(scaffold.isModalOpen(tester), isFalse);
    // Ledger #30 fixed: the DELETE fires, never the deactivate PATCH.
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
  });
}
