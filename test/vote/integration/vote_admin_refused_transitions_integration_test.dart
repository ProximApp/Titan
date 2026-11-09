import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/vote/providers/list_list_provider.dart';
import 'package:titan/vote/providers/result_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The vote admin's refused transitions and its refresh pass.
///
/// Every transition here is answered "no" instead of reaching the endpoint:
/// the error toasts only exist for that answer, and a successful HTTP stub
/// can never produce one. The refresh test drives the `Refresher`'s own
/// callback, which reloads the results for a counted campaign and falls back
/// to an empty list when the list read had failed.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAdmin(
    WidgetTester tester, {
    required enums.StatusType status,
    List<dynamic> overrides = const [],
  }) async {
    stubVoteAdmin(
      scaffold,
      status: status,
      lists: [voteListFixture('l-1', 'BDE')],
      withResults: true,
    );
    final container = scaffold.makeContainer(
      user: voteAdminUserFixture(),
      providerOverrides: [
        statusProvider.overrideWith(
          () => FakeVoteStatusActions(
            AsyncValue.data(VoteStatus(status: status)),
          ),
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('a refused count keeps the campaign closed and reports it', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.closed);

    await scaffold.ensureOnScreen(tester, find.text('Count votes'));
    await tester.tap(find.text('Count votes'));
    await pumpFrames(tester);

    expect(find.text('Error counting votes'), findsOneWidget);
    expect(find.text('Votes counted'), findsNothing);
    // Still closed: the count button is what the page offers.
    expect(find.text('Count votes'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused close keeps the campaign open and reports it', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.open);

    await scaffold.ensureOnScreen(tester, find.text('Close votes'));
    await tester.tap(find.text('Close votes'));
    await pumpFrames(tester);

    expect(find.text('Error closing votes'), findsOneWidget);
    expect(find.text('Votes closed'), findsNothing);
    expect(find.text('Close votes'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused reset reports it and leaves the counting panel', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.counting);

    await scaffold.ensureOnScreen(tester, find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester);

    expect(find.text('Error resetting votes'), findsOneWidget);
    expect(find.text('Votes reset'), findsNothing);
    expect(find.text('Show votes'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the revealed graph can be hidden again with its eye control', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.counting);

    await scaffold.ensureOnScreen(tester, find.text('Show votes'));
    await tester.tap(find.text('Show votes'));
    await pumpFrames(tester, 10);
    expect(find.text('Show votes'), findsNothing);

    // Only the revealed panel carries the eye-slash control.
    final eyeSlash = find.byWidgetPredicate(
      (widget) => widget is HeroIcon && widget.icon == HeroIcons.eyeSlash,
    );
    expect(eyeSlash, findsOneWidget);
    await tester.tap(eyeSlash);
    await pumpFrames(tester, 10);

    // Hidden again: the placeholder returns.
    expect(find.text('Show votes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refresh reloads the counted results and survives a failed '
      'list read', (tester) async {
    await pumpAdmin(
      tester,
      status: enums.StatusType.counting,
      overrides: [
        // The pass falls back to an empty list when this read did not land.
        listListProvider.overrideWith(
          () => FakeListListNotifier(
            AsyncValue.error(Exception('offline'), StackTrace.empty),
          ),
        ),
        resultProvider.overrideWith(
          () => FakeResultNotifier(
            const AsyncValue.data(<AppModulesCampaignSchemasCampaignResult>[]),
          ),
        ),
      ],
    );

    // The page's own refresh callback: a counted campaign reloads its
    // results, then walks the sections it just read.
    final refresher = tester.widget<Refresher>(find.byType(Refresher));
    await refresher.onRefresh();
    await pumpFrames(tester, 16);

    expect(find.text('Show votes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
