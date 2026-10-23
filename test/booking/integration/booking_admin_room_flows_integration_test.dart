import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/room_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// AddEditRoomPage's uncovered handlers: every AdminShrinkButton onTap was
/// never driven — manager chip selection, add POST / update PATCH, the
/// delete-confirm CustomDialogBox (cancel AND confirm), and all five toast
/// outcomes (added / edited / deleted / each error).
///
/// The manager twin lives in its own file (booking_admin_manager_flows):
/// qlevar caches the matched route subtree globally, so a deep link to a
/// SIBLING path (/booking/admin/manager) after any test in this file ran
/// resolves to the admin parent instead of the child (README convention 1).
///
/// `update`/`delete` in ListNotifierAPI rewrite the list IN PLACE
/// (`newList[indexWhere(...)] = t`), so the edit/delete tests seed the GET
/// with the SAME object the form edits — an empty list would RangeError
/// instead of saving.
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final room = RoomComplete.empty().copyWith(
    id: 'room-1',
    name: 'Amphi A',
    managerId: 'mgr-1',
  );
  final manager = Manager.empty().copyWith(
    id: 'mgr-1',
    name: 'Amphi',
    groupId: 'grp-1',
  );

  final path =
      '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.room}';

  testWidgets('picking a manager chip and adding toasts the success', (
    tester,
  ) async {
    stubLoads(scaffold, managers: [manager]);
    when(() => scaffold.repository.bookingRoomsPost(body: any(named: 'body')))
        .thenAnswer((_) async => chopperResponse(room));
    final container = makeAdminContainer(scaffold);

    await pumpAdmin(scaffold, tester, container, path: path);

    expect(find.text('Add room'), findsOneWidget);
    // The name lives in the AdminEntry TextField's controller.
    await tester.enterText(find.byType(TextField), 'Salle C');
    await tester.tap(find.text('Amphi'));
    await tester.ensureVisible(shrinkButton('Add'));
    await tester.tap(shrinkButton('Add'));
    await settle(tester, frames: 8);

    verify(() => scaffold.repository.bookingRoomsPost(body: any(named: 'body')))
        .called(1);
    await expectToast(tester, 'Room added');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed add toasts the adding error', (tester) async {
    stubLoads(scaffold, managers: [manager]);
    when(() => scaffold.repository.bookingRoomsPost(body: any(named: 'body')))
        .thenThrow(Exception('post failed'));
    final container = makeAdminContainer(scaffold);

    await pumpAdmin(scaffold, tester, container, path: path);

    await tester.enterText(find.byType(TextField), 'Salle C');
    await tester.ensureVisible(shrinkButton('Add'));
    await tester.tap(shrinkButton('Add'));
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error while adding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing PATCHes, toasts and goes back', (tester) async {
    stubLoads(scaffold, rooms: [room], managers: [manager]);
    when(
      () => scaffold.repository.bookingRoomsRoomIdPatch(
        roomId: any(named: 'roomId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = makeAdminContainer(scaffold);
    container.read(roomProvider.notifier).setRoom(room);

    await pumpAdmin(scaffold, tester, container, path: path);

    expect(find.text('Edit or delete a room'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Amphi B');
    await tester.ensureVisible(shrinkButton('Edit'));
    await tester.tap(shrinkButton('Edit'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.bookingRoomsRoomIdPatch(
        roomId: 'room-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    await expectToast(tester, 'Room edited');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed edit toasts, and the delete dialog drives the DELETE', (
    tester,
  ) async {
    stubLoads(scaffold, rooms: [room], managers: [manager]);
    when(
      () => scaffold.repository.bookingRoomsRoomIdPatch(
        roomId: any(named: 'roomId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('patch failed'));
    when(
      () => scaffold.repository.bookingRoomsRoomIdDelete(
        roomId: any(named: 'roomId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = makeAdminContainer(scaffold);
    container.read(roomProvider.notifier).setRoom(room);

    await pumpAdmin(scaffold, tester, container, path: path);

    // Failed PATCH: the error toast, still on the form (so the delete
    // buttons below are still there).
    await tester.enterText(find.byType(TextField), 'Amphi B');
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
        'Are you sure you want to delete this room?\n\n'
        'The room must have no current or upcoming bookings to be deleted',
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
      () => scaffold.repository.bookingRoomsRoomIdDelete(
        roomId: any(named: 'roomId'),
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

    verify(() => scaffold.repository.bookingRoomsRoomIdDelete(roomId: 'room-1'))
        .called(1);
    await expectToast(tester, 'Room deleted');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed delete toasts the deleting error', (tester) async {
    stubLoads(scaffold, rooms: [room], managers: [manager]);
    when(
      () => scaffold.repository.bookingRoomsRoomIdDelete(
        roomId: any(named: 'roomId'),
      ),
    ).thenThrow(Exception('delete failed'));
    final container = makeAdminContainer(scaffold);
    container.read(roomProvider.notifier).setRoom(room);

    await pumpAdmin(scaffold, tester, container, path: path);

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
}
