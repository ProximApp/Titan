import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

BookingReturnApplicant booking(
  String id,
  Decision decision,
  DateTime creation,
) => BookingReturnApplicant.empty().copyWith(
  id: id,
  reason: 'Robotics weekly $id',
  decision: decision,
  creation: creation,
  room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
);

void stubManager(
  IntegrationScaffold scaffold, {
  List<BookingReturnApplicant>? bookings,
}) {
  when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
    (_) async => chopperListResponse([
      RoomComplete.empty().copyWith(
        id: 'room-1',
        name: 'Amphi A',
        managerId: 'mgr-1',
      ),
    ]),
  );
  when(() => scaffold.repository.bookingBookingsUsersMeManageGet()).thenAnswer(
    (_) async => chopperListResponse(bookings ?? <BookingReturnApplicant>[]),
  );
  when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
    (_) async => chopperListResponse(<BookingReturnSimpleApplicant>[]),
  );
  when(
    () => scaffold.repository.bookingBookingsUsersMeGet(),
  ).thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /booking/manager renders the empty state', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      // The manager-route gate (isManagerProvider) derives from this.
      myManagerRoles: [
        Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
      ],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // The manager cards hit the known BookingCard overflow (README #11).
    scaffold.absorbLayoutOverflows(tester);
    stubManager(scaffold);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.manager}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No current booking'), findsOneWidget);
  });

  testWidgets(
    'deep link to /booking/manager renders bookings grouped by decision',
    (tester) async {
      final container = scaffold.makeContainer(
        myManagerRoles: [
          Manager.empty().copyWith(
            id: 'mgr-1',
            name: 'Amphi',
            groupId: 'grp-1',
          ),
        ],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // The manager cards hit the known BookingCard overflow (README #11).
      scaffold.absorbLayoutOverflows(tester);
      stubManager(
        scaffold,
        bookings: [
          booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
          booking('b-2', Decision.approved, DateTime(2026, 1, 2)),
        ],
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${BookingRouter.root}${BookingRouter.manager}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // ListBooking renders the title with its count.
      expect(find.textContaining('Pending'), findsWidgets);
      expect(find.textContaining('Confirmed'), findsWidgets);
      expect(find.textContaining('Robotics weekly'), findsWidgets);
    },
  );
}
