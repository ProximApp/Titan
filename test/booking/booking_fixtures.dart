import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/booking/ui/pages/admin_pages/admin_shrink_button.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../shared/app_scaffold.dart';

/// The booking admin gate group — the shared main admin group.
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// A booking admin: `user-1` carrying the admin group.
CoreUser adminUser() => CoreUser.empty().copyWith(
  groups: [
    CoreGroupSimple.empty().copyWith(id: bookingAdminGroupId, name: 'admin'),
  ],
);

/// Container pre-seeded with the admin user and disposed on teardown.
ProviderContainer makeAdminContainer(IntegrationScaffold scaffold) {
  final container = scaffold.makeContainer(user: adminUser());
  addTearDown(container.dispose);
  return container;
}

/// Finder for the [HeroIcon] of the given icon.
Finder heroIcon(HeroIcons icon) =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon);

/// Finder for a label inside the admin shrink button.
Finder shrinkButton(String label) => find.descendant(
  of: find.byType(AdminShrinkButton),
  matching: find.text(label),
);

/// Asserts a toast shows, then lets its 3s lifetime elapse.
Future<void> expectToast(WidgetTester tester, String text) async {
  expect(find.text(text, skipOffstage: false), findsOneWidget);
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
}

/// Raw pump loop for chains that never settle.
Future<void> pumpFrames(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Route mock that records every navigation it is asked to perform.
class RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox.shrink());
  }
}

/// Stubs the three reads the booking admin mount fans out to; [managers]
/// backs the manager cards, [groups] the group-chip catalog.
void stubLoads(
  IntegrationScaffold scaffold, {
  List<RoomComplete> rooms = const [],
  List<Manager> managers = const [],
  List<CoreGroupSimple> groups = const [],
}) {
  when(() => scaffold.repository.bookingRoomsGet())
      .thenAnswer((_) async => chopperListResponse(rooms));
  when(() => scaffold.repository.bookingManagersGet())
      .thenAnswer((_) async => chopperListResponse(managers));
  when(() => scaffold.repository.groupsGet())
      .thenAnswer((_) async => chopperListResponse(groups));
}

/// Pushes an admin page — the manager route unless [path] says otherwise.
Future<void> pumpAdmin(
  IntegrationScaffold scaffold,
  WidgetTester tester,
  ProviderContainer container, {
  String? path,
}) async {
  scaffold.setWideSurface(tester);
  await scaffold.pumpApp(
    tester,
    container,
    initialPath:
        path ??
        '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.manager}',
    pumpAndSettle: false,
  );
  await settle(tester);
}

/// Pushes the add-edit form — the booking one unless [path] says otherwise.
Future<void> pumpAddEdit(
  IntegrationScaffold scaffold,
  WidgetTester tester,
  ProviderContainer container, {
  String path = '/booking/add_edit',
}) async {
  scaffold.setWideSurface(tester);
  await scaffold.pumpApp(
    tester,
    container,
    initialPath: path,
    pumpAndSettle: false,
  );
  await pumpFrames(tester, frames: 12);
}

/// Stubs the add-edit pages' four reads: the two rooms, the user's own
/// bookings ([mine]), the confirmed list, and the managed list ([managed]).
void stubBookingEndpoints(
  IntegrationScaffold scaffold, {
  List<BookingReturn> mine = const [],
  List<BookingReturnApplicant> managed = const [],
}) {
  when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
    (_) async => chopperListResponse<RoomComplete>([
      RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
      RoomComplete.empty().copyWith(id: 'room-2', name: 'Salle B'),
    ]),
  );
  when(() => scaffold.repository.bookingBookingsUsersMeGet())
      .thenAnswer((_) async => chopperListResponse<BookingReturn>(mine));
  when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
    (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
      <BookingReturnSimpleApplicant>[],
    ),
  );
  when(() => scaffold.repository.bookingBookingsUsersMeManageGet()).thenAnswer(
    (_) async => chopperListResponse<BookingReturnApplicant>(managed),
  );
}
