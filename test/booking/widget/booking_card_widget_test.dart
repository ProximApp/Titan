import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/ui/components/booking_card.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';

import '../../shared/app_scaffold.dart';

/// BookingCard's residual decision branches: the fixed-width sweep mounts
/// the admin card once with the default decision, and the list pages seed
/// EMPTY lists, so the declined case + label, the swaggerGeneratedUnknown
/// fallback case and the non-admin pending delete button are the only
/// unwalked lines left in the widget.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  BookingReturn card(enums.Decision decision) => BookingReturn.empty().copyWith(
    id: 'bk-9',
    reason: 'Réunion de bureau',
    entity: 'BDE',
    note: 'Prévoir les badges',
    start: DateTime(2027, 3, 2, 14),
    end: DateTime(2027, 3, 2, 16),
    room: RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi'),
    decision: decision,
  );

  testWidgets('a declined card takes the declined palette and label', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      BookingCard(booking: card(enums.Decision.declined), isAdmin: true),
      container,
    );

    expect(find.text('Amphi'), findsOneWidget);
    // The decision label ternary falls through to the declined branch.
    expect(find.text('Declined'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown decision falls back without crashing', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      BookingCard(
        booking: card(enums.Decision.swaggerGeneratedUnknown),
        isAdmin: false,
      ),
      container,
    );

    expect(find.text('Amphi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending non-admin card keeps the delete action', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    var deleted = false;
    await scaffold.pumpWidgetApp(
      tester,
      BookingCard(
        booking: card(enums.Decision.pending),
        isAdmin: false,
        onDelete: () async {
          deleted = true;
        },
      ),
      container,
    );

    // The delete WaitingButton only renders for a non-admin PENDING card —
    // no other test in the suite seeds one (the lists are all empty).
    final deleteButton = find.byType(WaitingButton);
    expect(deleteButton, findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(deleteButton);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(deleted, isTrue);
    expect(tester.takeException(), isNull);
  });
}
