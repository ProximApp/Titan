import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The two admin shortcuts ON the main page (main_page.dart lines 82-84 and
/// 181-188, both uncovered): the userGroup icon on the canVote-denied
/// surface, and the AdminButton in the section row for a module admin. Both
/// `QR.to(VoteRouter.root + VoteRouter.admin)` into the admin shell, whose
/// open-state panel is what proves the hop landed.
///
/// vote_admin_status_handlers / vote_open_votes own /vote/admin directly
/// from its own deep link — this file is only about the two doors that lead
/// there from /vote.
const voterGroupId = 'voter-group-1';

/// An admin who is ALSO in the granted voter group: `canVoteProvider`
/// intersects the permission's groups with the user's own, so the
/// admin-only shortcut and the section row can appear together.
CoreUser voteAdminVoterFixture() => CoreUser.empty().copyWith(
  groups: [
    CoreGroupSimple.empty().copyWith(id: voteAdminGroupId, name: 'admin_vote'),
    CoreGroupSimple.empty().copyWith(id: voterGroupId, name: 'students'),
  ],
);

/// The reads /vote itself fans out to, plus the ones its admin shell and
/// the section cards reach right after the hop (results and the per-section
/// count panel).
void stubVotePage(
  IntegrationScaffold scaffold, {
  required enums.StatusType status,
  required bool voterAllowed,
  List<ListReturn>? lists,
}) {
  when(() => scaffold.repository.campaignStatusGet())
      .thenAnswer((_) async => chopperResponse(VoteStatus(status: status)));
  when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
    (_) async =>
        chopperListResponse([sectionFixture('s-1', 'Bureau des Sports')]),
  );
  when(() => scaffold.repository.campaignListsGet())
      .thenAnswer((_) async => chopperListResponse(lists ?? <ListReturn>[]));
  when(() => scaffold.repository.campaignVotersGet()).thenAnswer(
    (_) async => chopperResponse(
      voterAllowed
          ? CorePermission(
              permissionName: 'vote',
              groups: const [voterGroupId],
              accountTypes: const [],
            )
          : CorePermission.empty(),
    ),
  );
  when(() => scaffold.repository.campaignVotesGet())
      .thenAnswer((_) async => chopperListResponse(<String>[]));
  when(
    () => scaffold.repository.campaignListsListIdLogoGet(
      listId: any(named: 'listId'),
    ),
  ).thenAnswer(
    (_) async => chopper.Response<List<int>>(
      http.Response('{"detail": "File does not exist"}', 404),
      [],
      error: 'File does not exist',
    ),
  );
  when(() => scaffold.repository.campaignResultsGet()).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesCampaignSchemasCampaignResult>[]),
  );
  when(
    () => scaffold.repository.campaignStatsSectionIdGet(
      sectionId: any(named: 'sectionId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(VoteStats(sectionId: 's-1', count: 7)),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpVoteMain(
    WidgetTester tester, {
    required bool voterAllowed,
    required CoreUser user,
    List<ListReturn>? lists,
  }) async {
    final container = scaffold.makeContainer(user: user);
    addTearDown(container.dispose);
    stubVotePage(
      scaffold,
      status: enums.StatusType.open,
      voterAllowed: voterAllowed,
      lists: lists,
    );
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: VoteRouter.root,
      pumpAndSettle: false,
    );
    // The 2.4s staggered card slide-in: tap targets sit after it.
    await settle(tester, frames: 40);
    return container;
  }

  testWidgets('a non-voter takes the userGroup shortcut to /vote/admin', (
    tester,
  ) async {
    // voterAllowed false → the canVote-denied surface with its shortcut;
    // the admin group still passes the /vote/admin gate.
    await pumpVoteMain(
      tester,
      voterAllowed: false,
      user: voteAdminUserFixture(),
    );

    expect(find.text('You cannot vote'), findsOneWidget);
    await tester.tap(find.byType(CustomIconButton));
    await settle(tester, frames: 20);

    // The admin shell's open-state panel: votes closed from here.
    expect(find.text('Close votes'), findsOneWidget);
  });

  testWidgets('an admin taps the section-row AdminButton into /vote/admin', (
    tester,
  ) async {
    // isVoteAdminProvider (from the user's groups) shows the AdminButton
    // beside the section title while the voter gate still passes.
    await pumpVoteMain(
      tester,
      voterAllowed: true,
      user: voteAdminVoterFixture(),
      lists: [voteListFixture('l-1', 'BDE')],
    );

    expect(find.text('BDE'), findsOneWidget);
    expect(find.byType(AdminButton), findsOneWidget);
    await tester.tap(find.byType(AdminButton));
    await settle(tester, frames: 20);

    expect(find.text('Close votes'), findsOneWidget);
  });
}
