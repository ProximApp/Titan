import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// The booking admin gate is a plain Provider over userProvider.groups.
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

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
  when(() => scaffold.repository.bookingBookingsUsersMeGet())
      .thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
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

  /// The four chip handlers: each row's plus opens a BLANK form, each existing
  /// chip opens that record. Every one of them is a `setRoom`/`setManager`
  /// followed by a `QR.to`, so the chip decides which record the full-page
  /// form edits — a wrong or missing selection would silently pre-fill the
  /// form with the previous room.
  testWidgets('the plus chip opens a blank room form', (tester) async {
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

    // The room row renders before the manager row, so its plus is first.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .first,
    );
    await settle(tester, frames: 12);

    expect(
      QR.currentPath,
      '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.room}',
    );
  });

  testWidgets('an existing room chip opens that room', (tester) async {
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

    // capitalize() lowercases the tail of the room name.
    await tester.tap(find.text('Amphi a'));
    await settle(tester, frames: 12);

    expect(
      QR.currentPath,
      '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.room}',
    );
  });

  testWidgets('the manager chips open the manager form', (tester) async {
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

    await tester.tap(find.text('Amphi'));
    await settle(tester, frames: 12);

    expect(
      QR.currentPath,
      '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.manager}',
    );
  });
}
