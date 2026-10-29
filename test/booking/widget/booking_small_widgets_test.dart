import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/ui/calendar/calendar_dialog_button.dart';
import 'package:titan/booking/ui/pages/booking_pages/checkbox_entry.dart';
import 'package:titan/booking/ui/pages/detail_pages/contact_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Widget coverage for the three leaf widgets no page test reaches on its
/// own: the detail page's contact button, the calendar dialog's mail/sms
/// buttons (which end in `launchUrl`) and the "All day" checkbox entry.
void main() {
  group('ContactButton', () {
    testWidgets('renders its child inside the rounded container', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ContactButton(child: Icon(Icons.mail))),
        ),
      );

      expect(find.byIcon(Icons.mail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CalendarDialogButton', () {
    testWidgets('tapping a button with a uri launches it', (tester) async {
      final fake = FakeUrlLauncher();
      stubUrlLauncher(fake);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarDialogButton(
              uri: 'mailto:jb@example.com',
              icon: HeroIcons.atSymbol,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CalendarDialogButton));
      await tester.pump();

      expect(fake.launched, ['mailto:jb@example.com']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a button with a null uri launches nothing', (
      tester,
    ) async {
      final fake = FakeUrlLauncher();
      stubUrlLauncher(fake);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarDialogButton(
              uri: null,
              icon: HeroIcons.chatBubbleBottomCenterText,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CalendarDialogButton));
      await tester.pump();

      expect(fake.launched, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('CheckBoxEntry', () {
    testWidgets('tapping the row toggles the notifier', (tester) async {
      final valueNotifier = ValueNotifier<bool>(false);
      addTearDown(valueNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckBoxEntry(title: 'All day', valueNotifier: valueNotifier),
          ),
        ),
      );

      expect(valueNotifier.value, false);

      await tester.tap(find.text('All day'));
      await tester.pump();

      expect(valueNotifier.value, true);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the checkbox itself flips the value and calls onChanged', (
      tester,
    ) async {
      final valueNotifier = ValueNotifier<bool>(false);
      addTearDown(valueNotifier.dispose);
      var changed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckBoxEntry(
              title: 'All day',
              valueNotifier: valueNotifier,
              onChanged: () => changed++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(valueNotifier.value, true);
      expect(changed, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
