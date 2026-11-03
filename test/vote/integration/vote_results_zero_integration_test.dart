import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';
import 'package:titan/vote/ui/pages/admin_page/vote_bars.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The admin results chart (`VoteBars`) as it renders on the PUBLISHED
/// panel, for the two result shapes no fixture ever produced: a section
/// nobody voted in (every count 0) and a section with no lists at all.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpPublished(
    WidgetTester tester, {
    required List<ListReturn> lists,
    required List<AppModulesCampaignSchemasCampaignResult> results,
  }) async {
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.published,
      lists: lists,
      withResults: true,
    );
    // Re-stub over the fixture's `count: 12` so the chart sees the shape
    // this test is about.
    when(() => scaffold.repository.campaignResultsGet())
        .thenAnswer((_) async => chopperListResponse(results));
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
  }

  testWidgets('a section nobody voted in shows 0.00%, not NaN', (tester) async {
    await pumpPublished(
      tester,
      lists: [voteListFixture('l-1', 'BDE')],
      results: [
        AppModulesCampaignSchemasCampaignResult(listId: 'l-1', count: 0),
      ],
    );

    expect(find.textContaining('NaN'), findsNothing);
    expect(find.text('0.00%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty section renders the chart without throwing', (
    tester,
  ) async {
    await pumpPublished(
      tester,
      lists: const [],
      results: [
        AppModulesCampaignSchemasCampaignResult(listId: 'l-1', count: 0),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(VoteBars), findsOneWidget);
  });
}
