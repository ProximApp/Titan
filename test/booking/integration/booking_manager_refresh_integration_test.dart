import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// The manager page's pull-to-refresh reloads the bookings it manages, the
/// rooms and the confirmed bookings. None of the existing manager tests pull,
/// so a forgotten reload would leave a manager looking at stale requests.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('pulling down reloads the managed, room and confirmed lists', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myManagerRoles: [
        Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
      ],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
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
      () => scaffold.repository.bookingBookingsUsersMeManageGet(),
    ).thenAnswer((_) async => chopperListResponse(<BookingReturnApplicant>[]));
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse(<BookingReturnSimpleApplicant>[]),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.manager}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // The first paint settles on its own schedule, so measure only the pull.
    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    await settle(tester, frames: 30);

    // Each list reloads on the pull. The exact counts differ (a provider can
    // rebuild as the page settles), so assert the reload happened at all.
    verify(() => scaffold.repository.bookingBookingsUsersMeManageGet())
        .called(greaterThanOrEqualTo(1));
    verify(() => scaffold.repository.bookingRoomsGet())
        .called(greaterThanOrEqualTo(1));
    verify(() => scaffold.repository.bookingBookingsConfirmedGet())
        .called(greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
    expect(find.text('No current booking'), findsOneWidget);
  });
}
