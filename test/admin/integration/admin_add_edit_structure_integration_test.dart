import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/structure_manager_provider.dart';
import 'package:titan/admin/providers/structure_provider.dart';
import 'package:titan/admin/ui/pages/structure_page/add_edit_structure_page/user_search_modal.dart';
import 'package:titan/mypayment/providers/structure_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// The admin structure add-edit page: create, search/select manager, validate,
/// edit, and prefill behavior through the real route shell.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer adminContainer() => scaffold.makeContainer(
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

  Future<void> pumpAddEdit(
    WidgetTester tester,
    ProviderContainer container, {
    List<models.Structure> structures = const [],
  }) async {
    scaffold.setWideSurface(tester);
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async => chopperListResponse<models.MembershipSimple>([
        models.MembershipSimple.empty().copyWith(id: 'm-1', name: 'BDE'),
      ]),
    );
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopperListResponse<models.Structure>(structures),
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
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('NO MEMBERSHIP'), findsOneWidget);
    expect(find.text('Select a manager'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('saving without a manager reports the error without POSTing', (
    tester,
  ) async {
    final container = adminContainer();
    var createCalls = 0;
    when(
      () =>
          scaffold.repository.mypaymentStructuresPost(body: any(named: 'body')),
    ).thenAnswer((_) async {
      createCalls++;
      return chopperResponse(models.Structure.empty());
    });
    await pumpAddEdit(tester, container);

    await tester.enterText(find.byType(TextFormField).first, 'BDE store');
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 8);

    expect(find.text('No manager selected'), findsOneWidget);
    expect(createCalls, 0);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('a complete create form POSTs all selected data', (tester) async {
    final container = adminContainer();
    when(
      () =>
          scaffold.repository.mypaymentStructuresPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(models.Structure.empty()));
    await pumpAddEdit(tester, container);

    container
        .read(structureManagerProvider.notifier)
        .setUser(models.CoreUserSimple.empty().copyWith(id: 'mgr-1'));
    await settle(tester, frames: 4);
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
    await settle(tester, frames: 12);

    final body =
        verify(
              () => scaffold.repository.mypaymentStructuresPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as StructureBase;
    expect(body.name, 'BDE store');
    expect(body.shortId, 'BDE');
    expect(body.managerUserId, 'mgr-1');
    expect(body.siegeAddressCity, 'Lyon');
    expect(find.text('Structure added'), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('the manager picker searches, selects, and closes', (
    tester,
  ) async {
    final container = adminContainer();
    var searchCalls = 0;
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).thenAnswer((_) async {
      searchCalls++;
      return chopperListResponse([
        models.CoreUserSimple.empty().copyWith(
          id: 'mgr-1',
          firstname: 'Anne',
          name: 'Martin',
        ),
      ]);
    });

    await pumpAddEdit(tester, container);
    await tester.tap(find.text('Select a manager'));
    await settle(tester, frames: 16);
    expect(find.byType(UserSearchModal), findsOneWidget);
    final searchField = find.descendant(
      of: find.byType(UserSearchModal),
      matching: find.byType(TextField),
    );
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Anne');
    await settle(tester, frames: 18);
    expect(searchCalls, greaterThanOrEqualTo(1));
    final selectManager = find.descendant(
      of: find.byType(UserSearchModal),
      matching: find.byWidgetPredicate(
        (widget) => widget is HeroIcon && widget.icon == HeroIcons.plus,
      ),
    );
    expect(selectManager, findsOneWidget);
    await tester.tap(selectManager);
    await settle(tester, frames: 18);
    expect(find.byType(UserSearchModal), findsNothing);
    expect(container.read(structureManagerProvider).id, 'mgr-1');
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('invalid short id, IBAN and BIC are rejected', (tester) async {
    final container = adminContainer();
    container
        .read(structureManagerProvider.notifier)
        .setUser(models.CoreUserSimple.empty().copyWith(id: 'mgr-1'));
    var createCalls = 0;
    when(
      () =>
          scaffold.repository.mypaymentStructuresPost(body: any(named: 'body')),
    ).thenAnswer((_) async {
      createCalls++;
      return chopperResponse(models.Structure.empty());
    });
    await pumpAddEdit(tester, container);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BDE store');
    await tester.enterText(fields.at(1), 'TOOLONG');
    await tester.enterText(fields.at(7), 'short-iban');
    await tester.enterText(fields.at(8), 'tiny');
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 8);

    expect(find.text('Short ID must be 3 characters'), findsOneWidget);
    expect(find.text('IBAN must be 27 characters'), findsOneWidget);
    expect(find.text('BIC must be 11 characters'), findsOneWidget);
    expect(createCalls, 0);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('the edit form PATCHes updated fields and membership', (
    tester,
  ) async {
    final container = adminContainer();
    container
        .read(structureManagerProvider.notifier)
        .setUser(
          models.CoreUserSimple.empty().copyWith(
            id: 'mgr-1',
            firstname: 'Anne',
            name: 'Martin',
          ),
        );
    final structure = models.Structure.empty().copyWith(
      id: 'struct-1',
      name: 'BDE store',
      shortId: 'BDE',
      siegeAddressCity: 'Lyon',
      managerUserId: 'mgr-1',
      managerUser: models.CoreUserSimple.empty().copyWith(
        id: 'mgr-1',
        firstname: 'Anne',
        name: 'Martin',
      ),
      associationMembership: models.MembershipSimple.empty().copyWith(
        id: 'm-1',
        name: 'BDE',
      ),
    );
    container.read(structureProvider.notifier).setStructure(structure);
    var patchCalls = 0;
    when(
      () => scaffold.repository.mypaymentStructuresStructureIdPatch(
        structureId: any(named: 'structureId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      patchCalls++;
      return chopperResponseVoid();
    });
    await pumpAddEdit(tester, container, structures: [structure]);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BDE Lille');
    await tester.enterText(fields.at(1), 'BDE');
    await tester.enterText(fields.at(2), '1 rue du Café');
    await tester.enterText(fields.at(3), 'Lyon');
    await tester.enterText(fields.at(4), '69007');
    await tester.enterText(fields.at(5), 'France');
    await tester.enterText(fields.at(7), 'FR7630006000011234567890189');
    await tester.enterText(fields.at(8), 'AGRIFRPP882');
    await tester.tap(find.text('NO MEMBERSHIP'));
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 16);

    final captured = verify(
      () => scaffold.repository.mypaymentStructuresStructureIdPatch(
        structureId: captureAny(named: 'structureId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'struct-1');
    final body = captured[1] as StructureUpdate;
    expect(patchCalls, 1);
    expect(body.name, 'BDE Lille');
    expect(body.associationMembershipId, isNull);
    expect(container.read(structureListProvider).hasError, isFalse);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('the edit form pre-fills from the selected structure', (
    tester,
  ) async {
    final container = adminContainer();
    container
        .read(structureManagerProvider.notifier)
        .setUser(
          models.CoreUserSimple.empty().copyWith(
            id: 'mgr-1',
            firstname: 'Anne',
            name: 'Martin',
          ),
        );
    final structure = models.Structure.empty().copyWith(
      id: 'struct-1',
      name: 'BDE store',
      shortId: 'BDE',
      siegeAddressCity: 'Lyon',
      managerUserId: 'mgr-1',
      managerUser: models.CoreUserSimple.empty().copyWith(
        id: 'mgr-1',
        firstname: 'Anne',
        name: 'Martin',
      ),
      associationMembership: models.MembershipSimple.empty().copyWith(
        id: 'm-1',
        name: 'BDE',
      ),
    );
    container.read(structureProvider.notifier).setStructure(structure);
    await pumpAddEdit(tester, container);

    expect(find.text('Edit structure'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'BDE store',
    );
    expect(find.text('Anne Martin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });
}
