import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// The room form picks its manager from `managerList`. When that list fails
/// the form has to say so rather than render an empty strip, which is what
/// the error arm exists for — and what no test ever reached.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a failing manager list surfaces its error on the room form', (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: adminUser());
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
    when(() => scaffold.repository.bookingManagersGet())
        .thenThrow(Exception('managers down'));
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins'),
      ]),
    );
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse(<BookingReturnSimpleApplicant>[]),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.room}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);

    // The manager strip reports the failure; the rest of the form stays up.
    expect(find.textContaining('Error'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
