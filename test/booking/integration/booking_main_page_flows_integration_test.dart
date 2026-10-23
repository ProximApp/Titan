import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/booking/ui/pages/manager_page/list_booking.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../booking_fixtures.dart';

/// BookingMainPage's residual paths, none of which the deep-link tests walk
/// (they all mount the page underneath with EMPTY lists and default
/// non-admin roles):
/// * the manager/admin AdminButton rows and their QR navigations,
/// * the Refresher onRefresh closure,
/// * the plus card and the per-card onEdit/onInfo/onCopy callbacks,
/// * the delete confirmation dialog's success AND failure toast branches
///   (displayToastWithContext only exists for that flow).
const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

BookingReturn userBooking() => BookingReturn.empty().copyWith(
  id: 'u-1',
  reason: 'Robotics weekly u-1',
  creation: DateTime(2026, 2, 1),
  decision: Decision.pending,
  start: DateTime(2027, 3, 2, 14),
  end: DateTime(2027, 3, 2, 16),
  room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubMain(IntegrationScaffold s, {bool failDelete = false}) {
    when(() => s.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse([
        RoomComplete.empty().copyWith(
          id: 'room-1',
          name: 'Amphi A',
          managerId: 'mgr-1',
        ),
      ]),
    );
    when(() => s.repository.bookingBookingsUsersMeGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturn>([userBooking()]),
    );
    when(() => s.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
        <BookingReturnSimpleApplicant>[],
      ),
    );
    when(() => s.repository.bookingBookingsUsersMeManageGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnApplicant>(
        <BookingReturnApplicant>[],
      ),
    );
    when(() => s.repository.bookingBookingsBookingIdDelete(bookingId: 'u-1'))
        .thenAnswer(
          (_) async =>
              failDelete ? chopperError<void>(500) : chopperResponseVoid(),
        );
  }

  Future<void> pumpMain(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: BookingRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  testWidgets('the management button routes a manager to the manager page', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myManagerRoles: [
        Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
      ],
    );
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    final management = find.text('Management');
    expect(management, findsOneWidget);
    await tester.tap(management);
    await settle(tester, frames: 30);

    // QR.to('/booking/manager') mounts the manager page: its three
    // ListBooking sections exist even when every bucket is empty.
    expect(find.byType(ListBooking), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin button routes an admin to the room/manager admin', (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: adminUser());
    addTearDown(container.dispose);
    stubMain(scaffold);
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
    await pumpMain(tester, container);

    // The isAdmin button carries the AdminButton default text; isManager is
    // false here, so it is the only one in the row.
    final adminButton = find.text('Admin');
    expect(adminButton, findsOneWidget);

    // qlevar's mock records the real callback destination without waiting
    // for a second deferred library load in this widget-test isolate. The
    // admin page itself is exercised by booking_admin_integration_test.
    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(adminButton);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains('${BookingRouter.root}${BookingRouter.admin}'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh reloads the lists and the plus card opens a '
      'blank request', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    expect(find.text('Robotics weekly u-1'), findsOneWidget);
    expect(find.text('My bookings'), findsOneWidget);

    // Pull down from the outer scroll view's top-left gutter. Starting over
    // the calendar lets Syncfusion's own drag recognizers consume the gesture.
    final outerScroll = find.byType(CustomScrollView).first;
    final scrollTopLeft = tester.getTopLeft(outerScroll);
    await tester.dragFrom(
      scrollTopLeft + const Offset(2, 8),
      const Offset(0, 700),
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);
    // Initial build + the onRefresh closure's reload.
    verify(() => scaffold.repository.bookingBookingsUsersMeGet())
        .called(greaterThanOrEqualTo(2));

    final plus = heroIcon(HeroIcons.plus);
    expect(plus, findsOneWidget);
    await tester.ensureVisible(plus);
    await settle(tester, frames: 2);
    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(plus);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains('${BookingRouter.root}${BookingRouter.addEdit}'),
    );
    expect(container.read(bookingProvider).id, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card edit action seeds the booking and opens the edit '
      'form', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    final pencil = heroIcon(HeroIcons.pencil);
    expect(pencil, findsOneWidget);
    await tester.ensureVisible(pencil);
    await settle(tester, frames: 2);
    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(pencil);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains('${BookingRouter.root}${BookingRouter.addEdit}'),
    );
    expect(container.read(bookingProvider).id, 'u-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card info action opens the booking detail', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    final info = heroIcon(HeroIcons.informationCircle);
    expect(info, findsOneWidget);
    await tester.ensureVisible(info);
    await settle(tester, frames: 2);
    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(info);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains('${BookingRouter.root}${BookingRouter.detail}'),
    );
    expect(container.read(bookingProvider).id, 'u-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card copy action opens a blank request', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    final copy = heroIcon(HeroIcons.documentDuplicate);
    expect(copy, findsOneWidget);
    await tester.ensureVisible(copy);
    await settle(tester, frames: 2);
    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(copy);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains('${BookingRouter.root}${BookingRouter.addEdit}'),
    );
    expect(container.read(bookingProvider).id, isEmpty);
    expect(tester.takeException(), isNull);
  });

  Future<void> confirmDeleteDialog(WidgetTester tester) async {
    expect(find.byType(CustomDialogBox), findsOneWidget);
    final confirm = find.descendant(
      of: find.byType(CustomDialogBox),
      matching: find.byType(WaitingButton),
    );
    await tester.tap(confirm);
    await pumpFrames(tester, frames: 10);
  }

  testWidgets('confirming the delete dialog removes the booking and toasts '
      'the success message', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold);
    await pumpMain(tester, container);

    final trash = heroIcon(HeroIcons.trash);
    expect(trash, findsOneWidget);
    await tester.ensureVisible(trash);
    await settle(tester, frames: 2);
    await tester.tap(trash);
    await pumpFrames(tester);

    await confirmDeleteDialog(tester);

    verify(
      () =>
          scaffold.repository.bookingBookingsBookingIdDelete(bookingId: 'u-1'),
    ).called(1);
    expect(find.byType(CustomDialogBox), findsNothing);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed delete toasts the error branch instead', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubMain(scaffold, failDelete: true);
    await pumpMain(tester, container);

    final trash = heroIcon(HeroIcons.trash);
    expect(trash, findsOneWidget);
    await tester.ensureVisible(trash);
    await settle(tester, frames: 2);
    await tester.tap(trash);
    await pumpFrames(tester);

    await confirmDeleteDialog(tester);

    // value == false walks the else branch: displayToastWithContext with
    // the localized error (the success-only lines above it never run).
    verify(
      () =>
          scaffold.repository.bookingBookingsBookingIdDelete(bookingId: 'u-1'),
    ).called(1);
    expect(find.byType(CustomDialogBox), findsNothing);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });
}

/// Records QR.to destinations without forcing qlevar to load another deferred
/// page in this widget-test isolate.
