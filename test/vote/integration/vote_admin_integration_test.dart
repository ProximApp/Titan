import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

/// The vote admin gate is a plain Provider over userProvider.groups, so the
/// signed-in user carries the admin_vote group id.
const adminVoteGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';

SectionComplete section(String id, String name) =>
    SectionComplete.empty().copyWith(id: id, name: name, description: '');

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /vote/admin shows the sections, voters and lists for the admin_vote group',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: adminVoteGroupId,
              name: 'admin_vote',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // The page's Refresher + its watchers hit these on mount.
      when(() => scaffold.repository.campaignStatusGet()).thenAnswer(
        (_) async =>
            chopperResponse(VoteStatus(status: enums.StatusType.waiting)),
      );
      when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
        (_) async => chopperListResponse([section('s-1', 'Bureau des Sports')]),
      );
      when(
        () => scaffold.repository.campaignListsGet(),
      ).thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
      when(
        () => scaffold.repository.campaignVotersGet(),
      ).thenAnswer((_) async => chopperResponse(CorePermission.empty()));

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
