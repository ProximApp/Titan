import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The feed main page while its news is still loading.
///
/// `main_page.dart` 243 (`onItemTap: (item) {}`) also stays dark, and is dead
/// rather than untested: `FeedTimeline` hands that callback to
/// `TimelineItem`, whose `GestureDetector` wraps nothing but `EventCard` --
/// and `EventCard` has its own always-non-null `onTap` detector inside it, so
/// the inner detector always wins the gesture arena and the outer callback is
/// never invoked. The banner press is covered by the advert journey test.
///
/// The filter button reads the notifier's cached list through
/// `maybeWhen(orElse: () => <News>[])`: before the first answer there is no
/// list, so the sheet opens with empty chip rows instead of crashing or
/// waiting. That is the state a user on a slow network actually sees.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the filter sheet opens while the news is still loading', (
    tester,
  ) async {
    // A future that never completes: the page stays in its loading arm, which
    // is exactly the state the `orElse` branch answers.
    final pending = Completer<chopper.Response<List<News>>>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(
          chopper.Response(http.Response('body', 200), <News>[]),
        );
      }
    });
    when(() => scaffold.repository.feedNewsGet())
        .thenAnswer((_) => pending.future);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is HeroIcon &&
            widget.icon == HeroIcons.adjustmentsHorizontal,
      ),
    );
    await settle(tester, frames: 8);

    // The sheet opened with no chips to offer, and the page survived.
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Association'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
