import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../booking_fixtures.dart';
import '../../shared/app_scaffold.dart';

Manager manager(String id, String name) =>
    Manager.empty().copyWith(id: id, name: name, groupId: 'grp-1');

/// `/booking/admin`'s two failure arms.
///
/// The page renders each chip row from its own provider, and each provider has
/// a `data:` arm, a `loading:` arm and an `error:` arm. Only the happy path
/// was ever driven, so neither error arm had a test: a backend that refuses
/// the room list or the manager list leaves the OTHER row perfectly usable,
/// and the page must say so instead of taking the whole screen down. That is
/// exactly the shape of a real incident — one endpoint 500s and an admin
/// cannot edit anything, including the half that still works.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Everything the admin page mounts, minus the two lists under test.
  void stubAdminShell() {
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
    final container = scaffold.makeContainer(user: adminUser());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAdminShell();

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  testWidgets('a failing room list leaves the manager row usable', (
    tester,
  ) async {
    when(() => scaffold.repository.bookingRoomsGet())
        .thenThrow(Exception('rooms down'));
    when(
      () => scaffold.repository.bookingManagersGet(),
    ).thenAnswer((_) async => chopperListResponse([manager('mgr-1', 'Amphi')]));

    await pumpAdmin(tester);

    // The rooms row reports the failure instead of blanking the page...
    expect(find.textContaining('Error'), findsOneWidget);
    // ...and the managers row still renders from its own provider, which is
    // the half that must survive a single failing endpoint.
    expect(find.text('Amphi'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
  });

  testWidgets('a failing manager list leaves the room row usable', (
    tester,
  ) async {
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

    await pumpAdmin(tester);

    expect(find.textContaining('Error'), findsOneWidget);
    // capitalize() lowercases the tail, so the room chip reads "Amphi a".
    expect(find.text('Amphi a'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
  });
}
