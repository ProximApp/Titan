import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';
import '../../shared/fixtures.dart';

/// The vote admin gate is a plain Provider over userProvider.groups, so the
/// signed-in user carries the admin_vote group id.

/// Stubs the four endpoints the admin page loads on mount, with a
/// configurable campaign status — the status drives which controls render.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the open-votes flow posts the real endpoint and the admin page switches to the open state',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubVoteAdmin(scaffold, status: enums.StatusType.waiting);

      // The opening flow reloads the lists after opening.
      when(() => scaffold.repository.campaignListsGet())
          .thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
      var openCalled = 0;
      when(() => scaffold.repository.campaignStatusOpenPost())
          .thenAnswer((_) async {
            openCalled++;
            return chopperResponseVoid();
          });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Waiting state: the OpeningVote panel with its three destructive /
      // opening buttons, plus the status switch and the add-section chip.
      // (votePipo is "Fake" in en; "Pipo" is the fr string.)
      expect(find.text('Open votes'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Fake'), findsOneWidget);
      expect(find.text('Lists'), findsOneWidget);

      // Open through the real endpoint: the status flips and the page
      // re-renders into the open state.
      await tester.tap(find.text('Open votes'));
      await settle(tester, frames: 12);
      expect(openCalled, 1);
      // The open state swaps the opening panel for the vote counter and the
      // close button; the waiting-only opening panel is gone.
      expect(find.text('Close votes'), findsOneWidget);
      expect(find.text('Open votes'), findsNothing);
      // The success toast confirms the branch ran; drain its timer.
      expect(find.text('Votes opened'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
