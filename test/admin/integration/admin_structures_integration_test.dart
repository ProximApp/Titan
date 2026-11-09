import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/structure_manager_provider.dart';
import 'package:titan/admin/providers/structure_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:http/http.dart' as http;

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

void main() {
  late IntegrationScaffold scaffold;
  var holderFails = false;
  var holderRequests = 0;
  var deleteFails = false;
  var deleteRequests = 0;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    holderFails = false;
    holderRequests = 0;
    deleteFails = false;
    deleteRequests = 0;
  });

  Future<ProviderContainer> pumpStructures(WidgetTester tester) async {
    when(() => scaffold.repository.mypaymentBankAccountHolderGet())
        .thenAnswer((_) async => chopperResponse(Structure.empty()));
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        Structure.empty().copyWith(
          id: 's-1',
          name: 'BDE',
          managerUserId: 'manager-1',
          managerUser: CoreUserSimple.empty().copyWith(
            id: 'manager-1',
            firstname: 'Anne',
            name: 'Martin',
          ),
        ),
        Structure.empty().copyWith(
          id: 's-2',
          name: 'Club',
          managerUserId: 'manager-2',
          managerUser: CoreUserSimple.empty().copyWith(
            id: 'manager-2',
            firstname: 'Bob',
            name: 'Durand',
          ),
        ),
      ]),
    );
    when(
      () => scaffold.repository.mypaymentBankAccountHolderPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      holderRequests++;
      return holderFails
          ? chopperError<Structure>(500)
          : chopperResponse(
              Structure.empty().copyWith(
                id: 's-1',
                name: 'BDE',
                managerUserId: 'manager-1',
                managerUser: CoreUserSimple.empty().copyWith(
                  id: 'manager-1',
                  firstname: 'Anne',
                  name: 'Martin',
                ),
              ),
            );
    });
    when(
      () => scaffold.repository.mypaymentStructuresStructureIdDelete(
        structureId: any(named: 'structureId'),
      ),
    ).thenAnswer((_) async {
      deleteRequests++;
      return deleteFails ? chopperError<void>(500) : chopperResponseVoid();
    });
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async => chopperListResponse([
        MembershipSimple.empty().copyWith(id: 'membership-1', name: 'BDE'),
      ]),
    );

    final container = scaffold.makeContainer(user: adminUser);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/structures',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/structures');
    expect(find.text('Structures'), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);
    expect(find.text('Bank account holder not defined'), findsOneWidget);
    return container;
  }

  Future<void> openStructure(WidgetTester tester, int index) async {
    await tester.tap(find.byType(ListItem).at(index));
    await settle(tester, frames: 10);
  }

  Future<void> deleteSelected(WidgetTester tester) async {
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 8);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 16);
    expect(find.byType(CustomDialogBox), findsNothing);
    await scaffold.drainToast(tester);
  }

  testWidgets('structures support assignment, deletion, and edit navigation', (
    tester,
  ) async {
    final container = await pumpStructures(tester);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);

    // First assign the BDE as holder and verify the exact API payload.
    await openStructure(tester, 0);
    expect(find.text('Define as bank account holder'), findsOneWidget);
    await tester.tap(find.text('Define as bank account holder'));
    await settle(tester, frames: 12);
    final request =
        verify(
              () => scaffold.repository.mypaymentBankAccountHolderPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as MyPaymentBankAccountHolder;
    expect(request.holderStructureId, 's-1');
    expect(holderRequests, 1);
    await scaffold.drainToast(tester);

    // The action sheet stays open after a holder assignment; switch the API
    // to error and assign the other structure to cover the failure branch.
    await tester.tapAt(const Offset(4, 4));
    await settle(tester, frames: 6);
    holderFails = true;
    await openStructure(tester, 1);
    await tester.tap(find.text('Define as bank account holder'));
    await settle(tester, frames: 12);
    expect(holderRequests, 2);
    expect(find.text('Bank account holder: BDE'), findsOneWidget);
    await scaffold.drainToast(tester);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester, frames: 6);

    // Failed deletion leaves Club available; a succeeding retry removes it.
    deleteFails = true;
    await openStructure(tester, 1);
    await deleteSelected(tester);
    expect(deleteRequests, 1);
    expect(find.text('Club'), findsOneWidget);

    deleteFails = false;
    await openStructure(tester, 1);
    await deleteSelected(tester);
    verify(
      () => scaffold.repository.mypaymentStructuresStructureIdDelete(
        structureId: 's-2',
      ),
    ).called(2);
    expect(deleteRequests, 2);
    expect(find.text('Club'), findsNothing);
    expect(find.text('BDE'), findsOneWidget);

    // Finish on the edit action so this remains one initial deep link and one
    // deferred route journey in the isolate. Do not tear down while the
    // bottom-sheet's navbar show animation is still active.
    await openStructure(tester, 0);
    await tester.tap(find.text('Edit'));
    for (
      var i = 0;
      i < 60 && find.text('Edit structure').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(QR.currentPath, '/admin/structures/add_edit_structure');
    expect(find.text('Edit structure'), findsOneWidget);
    expect(container.read(structureProvider).id, 's-1');
    expect(container.read(structureManagerProvider).id, 'manager-1');
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });
}
