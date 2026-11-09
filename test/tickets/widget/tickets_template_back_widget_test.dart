import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tickets/providers/tickets_on_back_provider.dart';
import 'package:titan/tickets/ui/tickets_module.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// `TicketTemplate`'s top bar normally pops the route. A caller that opened
/// the module from somewhere of its own can hand in a `ticketsOnBackProvider`
/// callback instead, and the back arrow must run that callback — after
/// clearing the hand-over, so a second back does not fire it again.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('the back arrow runs the handed-in callback once', (
    tester,
  ) async {
    var calls = 0;
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container.read(ticketsOnBackProvider.notifier).setOnBack(() => calls++);

    await scaffold.pumpWidgetApp(
      tester,
      const TicketTemplate(child: Text('Tickets body')),
      container,
    );
    expect(find.text('Tickets body'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is HeroIcon && widget.icon == HeroIcons.chevronLeft,
      ),
    );
    await tester.pump();

    expect(calls, 1);
    // The hand-over is one-shot: the template clears it while calling it.
    expect(container.read(ticketsOnBackProvider), isNull);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });
}
