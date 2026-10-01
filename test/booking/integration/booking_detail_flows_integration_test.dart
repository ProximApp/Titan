import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/booking/ui/pages/detail_pages/contact_button.dart';
import 'package:titan/booking/ui/pages/detail_pages/detail_booking.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// DetailBookingPage's residual: the whole isAdmin branch (applicant name,
/// mailto header, entity line, phone number/fallback, and the tel/sms
/// contact rows with their launchUrl catch paths). The root deep link only
/// ever renders isAdmin: false, and no test walks the manager-gated detail
/// route, so none of this block — nor the displayToastWithoutContext catch
/// closure it feeds — had ever executed.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  BookingReturnApplicant fullBooking({String? phone}) =>
      BookingReturnApplicant.empty().copyWith(
        id: 'b-9',
        reason: 'Réunion de bureau',
        entity: 'BDE',
        note: 'Prévoir le vidéoprojecteur',
        start: DateTime(2027, 5, 4, 14),
        end: DateTime(2027, 5, 4, 16),
        room: RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi'),
        applicant: Applicant.empty().copyWith(
          id: 'a-1',
          name: 'Delaunay',
          firstname: 'Jean-Baptiste',
          email: 'jb@example.com',
          phone: phone,
        ),
        decision: enums.Decision.approved,
      );

  Future<void> pumpDetail(
    WidgetTester tester,
    BookingReturnApplicant booking,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container.read(bookingProvider.notifier).setBooking(booking);
    await scaffold.pumpWidgetApp(
      tester,
      const DetailBookingPage(isAdmin: true),
      container,
    );
    await settle(tester);
  }

  testWidgets('the admin block renders and handles launcher failures', (
    tester,
  ) async {
    final launcher = FakeUrlLauncher(
      launchError: StateError('test launcher failure'),
    );
    stubUrlLauncher(launcher);
    await pumpDetail(tester, fullBooking(phone: '0601020304'));

    expect(find.text('Jean-Baptiste Delaunay'), findsOneWidget);
    expect(find.text('jb@example.com'), findsOneWidget);
    expect(find.textContaining('BDE'), findsOneWidget);
    expect(find.text('0601020304'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // mailto header: the fake throws an explicit platform failure, exercising
    // the page's catch → toast branch without using a platform channel.
    await tester.ensureVisible(find.text('jb@example.com'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('jb@example.com'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await scaffold.drainToast(tester);

    // tel: and sms: contact rows, each exercising the same catch branch.
    final contactButtons = find.byType(ContactButton);
    expect(contactButtons, findsNWidgets(2));

    await tester.ensureVisible(contactButtons.at(0));
    await settle(tester, frames: 2);
    await tester.tap(contactButtons.at(0));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await scaffold.drainToast(tester);

    await tester.ensureVisible(contactButtons.at(1));
    await settle(tester, frames: 2);
    await tester.tap(contactButtons.at(1));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(launcher.launched, [
      'mailto:jb@example.com',
      'tel:0601020304',
      'sms:0601020304',
    ]);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a booking without phone shows the fallback and skips the dial', (
    tester,
  ) async {
    final launcher = FakeUrlLauncher();
    stubUrlLauncher(launcher);
    await pumpDetail(tester, fullBooking());

    expect(find.text('Number not provided'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The phone button still renders; its guard short-circuits on the null
    // phone, so no launcher call and no toast.
    final phoneButton = find.byType(ContactButton).at(0);
    await tester.ensureVisible(phoneButton);
    await settle(tester, frames: 2);
    await tester.tap(phoneButton);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(launcher.launched, isEmpty);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
  });
}
