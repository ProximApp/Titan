import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// Two admin-page handlers the chip tests never reached: the pull-to-refresh
/// (which reloads rooms AND the confirmed bookings) and the MANAGER row's plus
/// chip (the existing tests only press the room row's).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubAdmin() {
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse([
        RoomComplete.empty().copyWith(
          id: 'room-1',
          name: 'Amphi A',
          managerId: 'mgr-1',
        ),
      ]),
    );
    when(() => scaffold.repository.bookingManagersGet()).thenAnswer(
      (_) async => chopperListResponse([
        Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
      ]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins'),
      ]),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse(<BookingReturnSimpleApplicant>[]),
    );
  }

  Future<void> pumpAdmin(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser());
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  testWidgets('pulling down reloads the rooms and the confirmed bookings', (
    tester,
  ) async {
    stubAdmin();
    await pumpAdmin(tester);

    // The first paint settles on its own schedule, so measure only the pull.
    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    await settle(tester, frames: 30);

    verify(() => scaffold.repository.bookingRoomsGet()).called(1);
    verify(() => scaffold.repository.bookingBookingsConfirmedGet()).called(1);
    expect(tester.takeException(), isNull);
    expect(find.text('Amphi a'), findsOneWidget);
  });

  testWidgets('the manager row plus chip opens a blank manager form', (
    tester,
  ) async {
    stubAdmin();
    await pumpAdmin(tester);

    // Room row comes first, manager row second.
    final pluses = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
    );
    expect(pluses, findsNWidgets(2));
    await tester.tap(pluses.at(1));
    await settle(tester, frames: 12);

    expect(
      QR.currentPath,
      '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.manager}',
    );
    expect(tester.takeException(), isNull);
  });
}
