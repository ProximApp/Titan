import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/home/ui/day_list.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The three blocks of the calendar page no test pressed: the
/// `Refresher.onRefresh` body, `MonthBar`'s scroll listener (day index,
/// month flip and the lazy "add more days" at the bottom of the axis), and
/// the day-card tap that routes to the event detail — this file's one
/// navigation journey (convention 10).
EventCompleteTicketUrl todayEvent(String id, String name) {
  final start = DateTime.now().add(const Duration(hours: 1));
  return EventCompleteTicketUrl.empty().copyWith(
    id: id,
    name: name,
    start: start,
    end: start.add(const Duration(hours: 2)),
    location: 'Amphi',
    association: Association.empty().copyWith(name: 'BDE'),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('refresh, scroll the day axis and open a day event', (
    tester,
  ) async {
    var fetches = 0;
    when(() => scaffold.repository.calendarEventsConfirmedGet())
        .thenAnswer((_) async {
          fetches++;
          return chopper.Response(http.Response('body', 200), [
            todayEvent('e-1', 'Gala'),
          ]);
        });

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/home',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(find.text('Gala'), findsOneWidget);

    // 1. A held downward drag arms the refresh control (a fling does not).
    //    It also moves the day-axis scroll offset, which is what
    //    MonthBar's listener reads.
    await tester.dragFrom(
      tester.getTopLeft(find.text('Gala')) - const Offset(0, 40),
      const Offset(0, 260),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(fetches, greaterThan(1), reason: 'the refresh must reload');

    // 2. MonthBar listens on the DAY AXIS (DayList's horizontal controller,
    //    86px per day), not on the event column: a horizontal drag indexes
    //    the day list, crosses into the next month (today is late in the
    //    month) and, clamped at the end of the axis, asks the day provider
    //    for more days. Each drag stays modest: BouncingScrollPhysics lets
    //    the axis overshoot while the finger is down, and `days[pixels ~/ 86]`
    //    throws once that overshoot runs past the end of the day list.
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(DayList), const Offset(-300, 0));
      await tester.pump(const Duration(milliseconds: 150));
    }
    // Jumping to the very end instead of dragging further: the finger-drag
    // overshoot that BouncingScrollPhysics allows is exactly what runs
    // `days[pixels ~/ 86]` past the last day, while the resting position at
    // `maxScrollExtent` is what arms `numberDay.add(1)` — the branch a drag
    // never quite reaches.
    final dayAxis = find.descendant(
      of: find.byType(DayList),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(dayAxis).position;
    if (position.maxScrollExtent > 0) {
      position.jumpTo(position.maxScrollExtent - 10);
    }
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);

    // 3. The day card's info button routes to the event detail (the file's
    //    journey) — the card text itself carries no handler.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      ),
    );
    await settle(tester, frames: 15);

    expect(QR.currentPath, contains('/detail'));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
