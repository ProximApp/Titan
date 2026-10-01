import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/booking/router.dart';

import '../../shared/app_scaffold.dart';

/// The booking admin gate is a plain Provider over userProvider.groups.
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

CoreUser adminUser() => CoreUser.empty().copyWith(
  groups: [
    CoreGroupSimple.empty().copyWith(id: bookingAdminGroupId, name: 'admin'),
  ],
);

Manager manager(String id, String name) =>
    Manager.empty().copyWith(id: id, name: name, groupId: 'grp-1');

void stubBookingAdmin(IntegrationScaffold scaffold) {
  when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
    (_) async => chopperListResponse([
      RoomComplete.empty().copyWith(
        id: 'room-1',
        name: 'Amphi A',
        managerId: 'mgr-1',
      ),
    ]),
  );
  when(
    () => scaffold.repository.bookingManagersGet(),
  ).thenAnswer((_) async => chopperListResponse([manager('mgr-1', 'Amphi')]));
  when(() => scaffold.repository.groupsGet()).thenAnswer(
    (_) async => chopperListResponse([
      CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins'),
    ]),
  );
  when(
    () => scaffold.repository.bookingBookingsUsersMeGet(),
  ).thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
  when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
    (_) async => chopperListResponse(<BookingReturnSimpleApplicant>[]),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /booking/admin renders the room and manager chips',
    (tester) async {
      final container = scaffold.makeContainer(user: adminUser());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubBookingAdmin(scaffold);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${BookingRouter.root}${BookingRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Both chip rows render: rooms (capitalize() lowercases the tail) and
      // managers.
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Amphi a'), findsOneWidget);
      expect(find.text('Amphi'), findsOneWidget);
    },
  );
}
