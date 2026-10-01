import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

Finder heroIcon(HeroIcons icon) =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon);

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
  when(() => scaffold.repository.bookingBookingsUsersMeGet())
      .thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
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

  Future<void> pumpManager(
    WidgetTester tester,
    ProviderContainer container,
    List<BookingReturnApplicant> bookings,
  ) async {
    scaffold.setWideSurface(tester);
    stubManager(scaffold, bookings: bookings);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.manager}',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  ProviderContainer managerContainer() => scaffold.makeContainer(
    myManagerRoles: [
      Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
    ],
  );

  Future<void> scrollIn(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await settle(tester, frames: 2);
  }

  Future<void> pumpFrames(WidgetTester tester, {int frames = 6}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('every decision bucket renders, declined and unknown too', (
    tester,
  ) async {
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
      booking('b-2', Decision.approved, DateTime(2026, 1, 2)),
      booking('b-3', Decision.declined, DateTime(2026, 1, 3)),
      booking('b-4', Decision.swaggerGeneratedUnknown, DateTime(2026, 1, 4)),
    ]);

    // One section header per non-empty bucket (len 1 → no plural 's'); the
    // unknown decision falls through its switch case without a bucket.
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Confirmed (1)'), findsOneWidget);
    expect(find.text('Declined (1)'), findsOneWidget);
    expect(find.textContaining('Robotics weekly'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the edit action opens the manager add/edit form', (
    tester,
  ) async {
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
    ]);

    final pencil = heroIcon(HeroIcons.pencil);
    expect(pencil, findsOneWidget);
    await scrollIn(tester, pencil);
    final navigation = _RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(pencil);
    await settle(tester, frames: 2);

    // handleBooking seeds bookingProvider and sends the manager route to its
    // add_edit child. The standalone form tests cover the page itself.
    expect(
      navigation.navigated,
      contains(
        '${BookingRouter.root}${BookingRouter.manager}${BookingRouter.addEdit}',
      ),
    );
    expect(container.read(bookingProvider).id, 'b-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info action opens the manager detail page', (tester) async {
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
    ]);

    final info = heroIcon(HeroIcons.informationCircle);
    expect(info, findsOneWidget);
    await scrollIn(tester, info);
    final navigation = _RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(info);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains(
        '${BookingRouter.root}${BookingRouter.manager}${BookingRouter.detail}',
      ),
    );
    expect(container.read(bookingProvider).id, 'b-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirming from the list PATCHes the approved decision', (
    tester,
  ) async {
    when(
      () => scaffold.repository.bookingBookingsBookingIdReplyDecisionPatch(
        bookingId: any(named: 'bookingId'),
        decision: any(named: 'decision'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
    ]);

    final check = heroIcon(HeroIcons.check);
    expect(check, findsOneWidget);
    await scrollIn(tester, check);
    await tester.tap(check);
    await pumpFrames(tester);
    expect(find.byType(CustomDialogBox), findsOneWidget);

    final confirm = find.descendant(
      of: find.byType(CustomDialogBox),
      matching: find.byType(WaitingButton),
    );
    await tester.tap(confirm);
    await pumpFrames(tester, frames: 10);

    expect(find.byType(CustomDialogBox), findsNothing);
    final captured = verify(
      () => scaffold.repository.bookingBookingsBookingIdReplyDecisionPatch(
        bookingId: 'b-1',
        decision: captureAny(named: 'decision'),
      ),
    ).captured.single;
    expect(captured, Decision.approved);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('declining from the list PATCHes the declined decision', (
    tester,
  ) async {
    when(
      () => scaffold.repository.bookingBookingsBookingIdReplyDecisionPatch(
        bookingId: any(named: 'bookingId'),
        decision: any(named: 'decision'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
    ]);

    final decline = heroIcon(HeroIcons.xMark);
    expect(decline, findsOneWidget);
    await scrollIn(tester, decline);
    await tester.tap(decline);
    await pumpFrames(tester);
    expect(find.byType(CustomDialogBox), findsOneWidget);

    final confirm = find.descendant(
      of: find.byType(CustomDialogBox),
      matching: find.byType(WaitingButton),
    );
    await tester.tap(confirm);
    await pumpFrames(tester, frames: 10);

    expect(find.byType(CustomDialogBox), findsNothing);
    final captured = verify(
      () => scaffold.repository.bookingBookingsBookingIdReplyDecisionPatch(
        bookingId: 'b-1',
        decision: captureAny(named: 'decision'),
      ),
    ).captured.single;
    expect(captured, Decision.declined);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the copy action opens the add form with a blank booking', (
    tester,
  ) async {
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
    ]);

    final copy = heroIcon(HeroIcons.documentDuplicate);
    expect(copy, findsOneWidget);
    await scrollIn(tester, copy);
    final navigation = _RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);
    await tester.tap(copy);
    await settle(tester, frames: 2);

    expect(
      navigation.navigated,
      contains(
        '${BookingRouter.root}${BookingRouter.manager}${BookingRouter.addEdit}',
      ),
    );
    expect(container.read(bookingProvider).id, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the confirmed section header collapses its cards', (
    tester,
  ) async {
    final container = managerContainer();
    addTearDown(container.dispose);
    await pumpManager(tester, container, [
      booking('b-1', Decision.pending, DateTime(2026, 1, 1)),
      booking('b-2', Decision.approved, DateTime(2026, 1, 2)),
    ]);

    expect(find.text('Robotics weekly b-1'), findsWidgets);
    // canToggle sections start COLLAPSED (toggle = useState(!canToggle)),
    // so the confirmed card only exists after its header is tapped.
    expect(find.text('Robotics weekly b-2'), findsNothing);
    final header = find.text('Confirmed (1)');
    await scrollIn(tester, header);
    await tester.tap(header);
    await pumpFrames(tester);

    expect(find.text('Robotics weekly b-2'), findsWidgets);
    expect(find.text('Robotics weekly b-1'), findsWidgets);

    await tester.tap(header);
    await pumpFrames(tester);

    // The toggle hides that section's horizontal list only.
    expect(find.text('Robotics weekly b-2'), findsNothing);
    expect(find.text('Robotics weekly b-1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

/// Records QR.to destinations so callback tests don't depend on loading a
/// second deferred route library in the same widget-test isolate.
class _RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox.shrink());
  }
}
