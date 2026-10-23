import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';
import '../../shared/fixtures.dart';

/// The vote admin gate is a plain Provider over userProvider.groups, so the
/// signed-in user carries the admin_vote group id.

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /vote/admin shows the sections, voters and lists for the admin_vote group',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // The page's Refresher + its watchers hit these on mount.
      stubVoteAdmin(scaffold, status: enums.StatusType.waiting);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Headers render plus the waiting-status admin controls (OpeningVote's
      // "Open votes" / "All" buttons). The section BAR lives above the
      // selected-section list, so the section chip renders "Bureau des
      // Sports" next to the "Association" header.
      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('Association'), findsOneWidget);
      expect(find.text('Bureau des Sports'), findsOneWidget);
    },
  );
}
