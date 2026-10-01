import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/group_id_provider.dart';
import 'package:titan/booking/providers/manager_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/booking/ui/pages/admin_pages/admin_shrink_button.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

/// AddEditManagerPage's twin of booking_admin_room_flows, in its OWN file:
/// qlevar caches the matched route subtree globally, so a deep link to this
/// sibling path (/booking/admin/manager) after any /booking/admin/room test
/// resolves to the admin parent instead of the child (README convention 1).
///
/// Covered handlers: group chip selection, add POST / update PATCH, the
/// delete-confirm CustomDialogBox, the error toasts, and the
/// `managerList.when` error branch. No test drives the page after a
/// SUCCESSFUL save — that arm QR.back()s to the admin parent, and the
/// buttons it would tap next no longer exist (the failed-save paths keep
/// the form up, which is where the dialog flows live, same as the room
/// file).
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final manager = Manager.empty().copyWith(
    id: 'mgr-1',
    name: 'Amphi',
    groupId: 'grp-1',
  );

  ProviderContainer makeAdminContainer() {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: bookingAdminGroupId,
            name: 'admin',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubLoads({List<CoreGroupSimple> groups = const []}) {
    when(() => scaffold.repository.bookingRoomsGet())
        .thenAnswer((_) async => chopperListResponse(<RoomComplete>[]));
    when(() => scaffold.repository.bookingManagersGet())
        .thenAnswer((_) async => chopperListResponse([manager]));
    when(() => scaffold.repository.groupsGet())
        .thenAnswer((_) async => chopperListResponse(groups));
  }

  Future<void> pumpAdmin(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.manager}',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  Finder shrinkButton(String label) => find.descendant(
    of: find.byType(AdminShrinkButton),
    matching: find.text(label),
  );

  Future<void> expectToast(WidgetTester tester, String text) async {
    expect(find.text(text, skipOffstage: false), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('picking a group chip and adding toasts the success', (
    tester,
  ) async {
    stubLoads(
      groups: [CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins')],
    );
    when(
      () => scaffold.repository.bookingManagersPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(manager));
    final container = makeAdminContainer();

    await pumpAdmin(tester, container);

    expect(find.text('Add manager'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Respo Amphi');
    await tester.tap(find.text('Admins'));
    await tester.ensureVisible(shrinkButton('Add'));
    await tester.tap(shrinkButton('Add'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.bookingManagersPost(body: any(named: 'body')),
    ).called(1);
    await expectToast(tester, 'Manager added');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed add toasts the adding error', (tester) async {
    stubLoads();
    when(
      () => scaffold.repository.bookingManagersPost(body: any(named: 'body')),
    ).thenThrow(Exception('post failed'));
    final container = makeAdminContainer();

    await pumpAdmin(tester, container);

    await tester.enterText(find.byType(TextField), 'Respo Amphi');
    await tester.ensureVisible(shrinkButton('Add'));
    await tester.tap(shrinkButton('Add'));
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error while adding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing PATCHes, toasts and goes back', (tester) async {
    stubLoads();
    when(
      () => scaffold.repository.bookingManagersManagerIdPatch(
        managerId: any(named: 'managerId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = makeAdminContainer();
    container.read(managerProvider.notifier).setManager(manager);
    container.read(groupIdProvider.notifier).setId('grp-1');

    await pumpAdmin(tester, container);

    expect(find.text('Edit or delete a manager'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Respo Amphi 2');
    await tester.ensureVisible(shrinkButton('Edit'));
    await tester.tap(shrinkButton('Edit'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.bookingManagersManagerIdPatch(
        managerId: 'mgr-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    await expectToast(tester, 'Manager edited');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed edit toasts, and the delete dialog drives the DELETE', (
    tester,
  ) async {
    stubLoads();
    when(
      () => scaffold.repository.bookingManagersManagerIdPatch(
        managerId: any(named: 'managerId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('patch failed'));
    when(
      () => scaffold.repository.bookingManagersManagerIdDelete(
        managerId: any(named: 'managerId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = makeAdminContainer();
    container.read(managerProvider.notifier).setManager(manager);
    container.read(groupIdProvider.notifier).setId('grp-1');

    await pumpAdmin(tester, container);

    // Failed PATCH: the error toast, still on the form.
    await tester.enterText(find.byType(TextField), 'Respo Amphi 2');
    await tester.ensureVisible(shrinkButton('Edit'));
    await tester.tap(shrinkButton('Edit'));
    await settle(tester, frames: 8);
    await expectToast(tester, 'Error while editing');

    // Cancel first: the dialog pops without calling DELETE.
    await tester.ensureVisible(shrinkButton('Delete'));
    await tester.tap(shrinkButton('Delete'));
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete this manager?\n\n'
        'The manager must not be associated with any room to be deleted',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Cancel'),
      ),
    );
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsNothing);
    verifyNever(
      () => scaffold.repository.bookingManagersManagerIdDelete(
        managerId: any(named: 'managerId'),
      ),
    );

    // Confirm for real: DELETE, toast, back to the admin parent.
    await tester.ensureVisible(shrinkButton('Delete'));
    await tester.tap(shrinkButton('Delete'));
    await settle(tester, frames: 4);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.bookingManagersManagerIdDelete(
        managerId: 'mgr-1',
      ),
    ).called(1);
    await expectToast(tester, 'Manager deleted');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed delete toasts the deleting error', (tester) async {
    stubLoads();
    when(
      () => scaffold.repository.bookingManagersManagerIdDelete(
        managerId: any(named: 'managerId'),
      ),
    ).thenThrow(Exception('delete failed'));
    final container = makeAdminContainer();
    container.read(managerProvider.notifier).setManager(manager);
    container.read(groupIdProvider.notifier).setId('grp-1');

    await pumpAdmin(tester, container);

    await tester.ensureVisible(shrinkButton('Delete'));
    await tester.tap(shrinkButton('Delete'));
    await settle(tester, frames: 4);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error while deleting');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed group list shows the error branch', (tester) async {
    stubLoads();
    // The page's `when` sits on allGroupListProvider (the chip source) —
    // its error arm renders 'Error $error'. After stubLoads so the
    // throwing stub wins.
    when(() => scaffold.repository.groupsGet())
        .thenThrow(Exception('groups failed'));
    final container = makeAdminContainer();

    await pumpAdmin(tester, container);

    expect(find.text('Error Exception: groups failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
