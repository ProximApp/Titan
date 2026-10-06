import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/structure_manager_provider.dart';
import 'package:titan/admin/providers/structure_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// The admin structure add-edit page
/// (`/admin/structures/add_edit_structure`, 165 executable lines — the
/// admin module's biggest uncovered file).
///
/// Create mode (empty `structureProvider`): the manager chip row shows
/// "Select a manager" until a user is chosen through the search modal;
/// the save button validates the form and posts through
/// StructureListNotifier.createStructure (`mypaymentStructuresPost`).
/// The admin gate is pre-seeded through `user.groups` (see
/// admin_integration_test).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer adminContainer() {
    return scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(
        id: 'me',
        groups: [
          models.CoreGroupSimple.empty().copyWith(
            id: adminGroupId,
            name: 'admin',
          ),
        ],
      ),
    );
  }

  Future<void> pumpAddEdit(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async => chopperListResponse<models.MembershipSimple>([
        models.MembershipSimple.empty().copyWith(id: 'm-1', name: 'BDE'),
      ]),
    );
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopperListResponse<models.Structure>(<models.Structure>[]),
    );
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/structures/add_edit_structure',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the create form renders its fields and membership chips', (
    tester,
  ) async {
    final container = adminContainer();

    await pumpAddEdit(tester, container);

    expect(find.text('Add structure'), findsOneWidget);
    expect(find.text('Head office address'), findsOneWidget);
    expect(find.text('Bank details'), findsOneWidget);
    // The membership chips come from the real memberships endpoint plus
    // the built-in "no membership" empty row.
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('NO MEMBERSHIP'), findsOneWidget);
    // Create mode: the manager row invites to pick a user.
    expect(find.text('Select a manager'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('saving without a manager shows the error toast', (tester) async {
    final container = adminContainer();

    await pumpAddEdit(tester, container);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'BDE store');
    await scaffold.unfocus(tester);

    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('No manager selected'), findsOneWidget);
    verifyNever(
      () =>
          scaffold.repository.mypaymentStructuresPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a complete create form posts the structure and toasts success', (
    tester,
  ) async {
    final container = adminContainer();
    when(
      () =>
          scaffold.repository.mypaymentStructuresPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(models.Structure.empty()));

    await pumpAddEdit(tester, container);

    // Pick the manager through the structure manager provider (the
    // user-search modal path ends in the same notifier write).
    container
        .read(structureManagerProvider.notifier)
        .setUser(models.CoreUserSimple.empty().copyWith(id: 'mgr-1'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // Field order: name, shortId, street, city, zipcode, country, siret
    // (optional), IBAN (27 chars, required), BIC (11 chars, required).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BDE store');
    await tester.enterText(fields.at(1), 'BDE');
    await tester.enterText(fields.at(2), '1 rue du Café');
    await tester.enterText(fields.at(3), 'Lyon');
    await tester.enterText(fields.at(4), '69007');
    await tester.enterText(fields.at(5), 'France');
    await tester.enterText(fields.at(7), 'FR7630006000011234567890189');
    await tester.enterText(fields.at(8), 'AGRIFRPP882');

    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final captured =
        verify(
              () => scaffold.repository.mypaymentStructuresPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as StructureBase;
    expect(captured.name, 'BDE store');
    expect(captured.shortId, 'BDE');
    expect(captured.managerUserId, 'mgr-1');
    expect(captured.siegeAddressCity, 'Lyon');
    expect(find.text('Structure added'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the edit form pre-fills from the selected structure', (
    tester,
  ) async {
    final container = adminContainer();
    container
        .read(structureProvider.notifier)
        .setStructure(
          models.Structure.empty().copyWith(
            id: 'struct-1',
            name: 'BDE store',
            shortId: 'BDE',
            siegeAddressCity: 'Lyon',
            associationMembership: models.MembershipSimple.empty().copyWith(
              id: 'm-1',
              name: 'BDE',
            ),
          ),
        );

    await pumpAddEdit(tester, container);

    expect(find.text('Edit structure'), findsOneWidget);
    // The pre-filled name field carries the structure's name.
    final fields = find.byType(TextFormField);
    final nameField = tester.widget<TextFormField>(fields.first);
    expect(nameField.controller!.text, 'BDE store');
    // Edit mode shows the manager line instead of the picker.
    expect(find.text('Structure administrator'), findsOneWidget);
    // Reset the selection so later tests start clean.
    container.read(structureProvider.notifier).resetStructure();
  });
}
