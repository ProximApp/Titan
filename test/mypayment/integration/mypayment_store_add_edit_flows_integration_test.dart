import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

/// The add/edit store round trips, which the structure-stores shell only
/// walks up to the form: the association picker modal, the create POST with
/// the selected structure + association, the edit PATCH, and the refusal
/// arm that stays on the form with the error toast.
final bdeStructure = structureFixture('structure-1', 'BDE', 'user-1');

final coop = Association.empty().copyWith(id: 'assoc-1', name: 'Coop');

final fridge = UserStore.empty().copyWith(
  id: 'store-1',
  name: 'Fridge',
  structure: bdeStructure,
);

void stubStorePages(IntegrationScaffold scaffold, {List<UserStore>? stores}) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse(stores ?? <UserStore>[]));
  // The add-edit store page loads the association picker list.
  when(() => scaffold.repository.associationsGet())
      .thenAnswer((_) async => chopperListResponse([coop]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpStores(
    WidgetTester tester, {
    List<UserStore>? stores,
  }) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        myStructures: [bdeStructure],
        selectedStructure: bdeStructure,
      ),
      initialPath: '/mypayment/structureStores',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 20);
    expect(find.text('Store name'), findsOneWidget);
  }

  testWidgets('the add card round-trips: picker, POST, back, toast', (
    tester,
  ) async {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is first.
    stubStorePages(scaffold);
    when(
      () => scaffold.repository.mypaymentStructuresStructureIdStoresPost(
        structureId: any(named: 'structureId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        Store.empty().copyWith(id: 'store-9', name: 'Waffle'),
      ),
    );

    await pumpStores(tester);
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField), 'Waffle');

    // The association picker: two rows, and selecting one both applies the
    // choice (onSelect) and pops the modal.
    await scaffold.openModal(tester, find.text('Select an association'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('No association'), findsOneWidget);
    expect(find.text('Coop'), findsOneWidget);
    await scaffold.tapInModal(tester, find.text('Coop'));
    expect(scaffold.isModalOpen(tester), isFalse);
    // The page row now shows the selection.
    expect(find.text('Coop'), findsOneWidget);

    await tester.tap(find.widgetWithText(WaitingButton, 'Add'));
    await settle(tester, frames: 30);

    verify(
      () => scaffold.repository.mypaymentStructuresStructureIdStoresPost(
        structureId: 'structure-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    // Success: refresh my stores, QR.back() to the list, success toast.
    expect(QR.currentPath, '/mypayment/structureStores');
    expect(find.text('Store successfully added'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the pencil card round-trips the edit PATCH and toasts', (
    tester,
  ) async {
    stubStorePages(scaffold, stores: [fridge]);
    when(
      () => scaffold.repository.mypaymentStoresStoreIdPatch(
        storeId: any(named: 'storeId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await pumpStores(tester);

    expect(find.text('Fridge'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.pencilSquare,
      ),
    );
    await settle(tester, frames: 20);
    expect(find.text('Edit store Fridge'), findsOneWidget);
    // The name controller is pre-filled with the store being edited.
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Fridge',
    );

    await tester.enterText(find.byType(TextFormField), 'Fridge Reloaded');
    await tester.tap(find.widgetWithText(WaitingButton, 'Edit'));
    await settle(tester, frames: 30);

    final body =
        verify(
              () => scaffold.repository.mypaymentStoresStoreIdPatch(
                storeId: 'store-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as StoreUpdate;
    expect(body.name, 'Fridge Reloaded');
    expect(body.associationId, isNull);
    expect(QR.currentPath, '/mypayment/structureStores');
    expect(find.text('Store successfully updated'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused create toasts the error and stays on the form', (
    tester,
  ) async {
    stubStorePages(scaffold);
    when(
      () => scaffold.repository.mypaymentStructuresStructureIdStoresPost(
        structureId: any(named: 'structureId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail(400));

    await pumpStores(tester);
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField), 'Waffle');
    await tester.tap(find.widgetWithText(WaitingButton, 'Add'));
    await settle(tester, frames: 30);

    // The error arm never pops: the form stays up under the toast.
    expect(find.text('Error while adding the store'), findsOneWidget);
    expect(QR.currentPath, '/mypayment/structureStores/addEditStore');
    expect(find.text('Store name'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
