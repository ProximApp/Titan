import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /booking/detail renders the pre-selected booking', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    scaffold.absorbLayoutOverflows(tester);
    // The main page mounts underneath with an empty list, so no booking
    // card (whose fixed-width rows overflow the layout) is rendered.
    when(
      () => scaffold.repository.bookingRoomsGet(),
    ).thenAnswer((_) async => chopperListResponse(<RoomComplete>[]));
    when(
      () => scaffold.repository.bookingBookingsUsersMeGet(),
    ).thenAnswer((_) async => chopperListResponse(<BookingReturn>[]));
    // The detail page renders the client-side booking state set by the
    // booking lists; the non-admin branch is shown for regular users.
    container
        .read(bookingProvider.notifier)
        .setBooking(
          BookingReturnApplicant.empty().copyWith(
            id: 'booking-1',
            note: 'Bring your own keys',
            room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // Decision enum renders lowercased ('approved') and the note is shown.
    expect(find.text('approved'), findsOneWidget);
    expect(find.textContaining('Bring your own keys'), findsOneWidget);
  });
}
