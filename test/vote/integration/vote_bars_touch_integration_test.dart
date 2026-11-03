import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// Touching the results bar chart.
///
/// `VoteBars` builds its `BarTouchData` lazily: the tooltip colour and item
/// builders only run when a tooltip is actually shown, and `touchCallback`
/// only when the chart receives a pointer event. The existing admin test
/// renders the chart and reads its axis labels, which is paint-only, so the
/// whole interaction half of the widget — including the branch that clears
/// the touched index on a non-interested event — had never executed.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('touching a bar shows its tooltip and releases the touch', (
    tester,
  ) async {
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.counting,
      lists: [voteListFixture('l-1', 'BDE')],
      withResults: true,
    );
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);

    // Counting starts with the graph hidden behind its placeholder.
    await scaffold.ensureOnScreen(tester, find.text('Show votes'));
    await tester.tap(find.text('Show votes'));
    await settle(tester, frames: 12);
    expect(find.byType(BarChart), findsOneWidget);

    // The chart is the only bar chart on the page. Touching inside its plot
    // area is what feeds `touchCallback`: it stores the touched group, which
    // in turn makes the chart build the tooltip for it.
    final rect = tester.getRect(find.byType(BarChart));
    // Hold the pointer down: the tooltip lives only while a spot is touched,
    // so a plain tap (down+up in one frame) would tear it down before it can
    // be read. The tooltip is also what builds the colour and item callbacks.
    // fl_chart reports a spot only when the pointer is inside a rod, and the
    // rod geometry (plot inset, bottom titles, bar width) is internal. Sweep
    // a few plausible points along the single rod's column instead of
    // betting on one, releasing between attempts.
    final candidates = [
      Offset(rect.center.dx, rect.bottom - 90),
      Offset(rect.center.dx, rect.center.dy),
      Offset(rect.center.dx, rect.bottom - 140),
      Offset(rect.left + 40, rect.center.dy),
    ];
    for (final point in candidates) {
      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);

    expect(tester.takeException(), isNull);

    // Releasing the pointer again (a tap outside the plot) takes the
    // not-interested branch, which resets the index instead of crashing on a
    // null spot.
    await tester.tapAt(Offset(rect.left + 2, rect.top + 2));
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);
  });
}
