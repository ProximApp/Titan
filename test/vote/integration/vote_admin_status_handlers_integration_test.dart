import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

/// The vote admin page's status-machine handler paths (97 uncovered
/// lines). The existing vote tests cover the waiting-status RENDER (shell,
/// open-votes flow, + button journey); everything here is the status-driven
/// branches: the waiting delete-all dialog chain, the open Close-votes
/// handler (with the VoteCount loader), the closed Count-votes handler,
/// and the counting Show-votes toggle with its Publish and Reset dialog
/// chains. Each test boots the page in its own status via the
/// campaignStatusGet stub — the status alone decides which controls
/// render. Same-path deep links per test (the page remounts, as verified
/// in the booking/phonebook rounds).
const adminVoteGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';

SectionComplete section(String id, String name) =>
    SectionComplete.empty().copyWith(id: id, name: name, description: '');

ListReturn listFixture(String id, String name) => ListReturn.empty().copyWith(
  id: id,
  name: name,
  description: 'Our program',
  type: enums.ListType.serio,
  section: section('s-1', 'Bureau des Sports'),
  members: const [],
);

void stubVoteAdmin(
  IntegrationScaffold scaffold, {
  required enums.StatusType status,
  bool withLists = false,
}) {
  when(
    () => scaffold.repository.campaignStatusGet(),
  ).thenAnswer((_) async => chopperResponse(VoteStatus(status: status)));
  when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
    (_) async => chopperListResponse([section('s-1', 'Bureau des Sports')]),
  );
  when(() => scaffold.repository.campaignListsGet()).thenAnswer(
    (_) async =>
        chopperListResponse([if (withLists) listFixture('l-1', 'BDE')]),
  );
  when(
    () => scaffold.repository.campaignVotersGet(),
  ).thenAnswer((_) async => chopperResponse(CorePermission.empty()));
  // VoteBars reads the results (auto-loaded by resultProvider).
  when(() => scaffold.repository.campaignResultsGet()).thenAnswer(
    (_) async => chopperListResponse([
      AppModulesCampaignSchemasCampaignResult(listId: 'l-1', count: 12),
    ]),
  );
  // VoteCount's AutoLoaderChild fetches the selected section's count.
  when(
    () => scaffold.repository.campaignStatsSectionIdGet(
      sectionId: any(named: 'sectionId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(VoteStats(sectionId: 's-1', count: 7)),
  );
  // Each list card auto-loads its logo.
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
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAdmin(
    WidgetTester tester, {
    required enums.StatusType status,
    bool withLists = false,
  }) async {
    stubVoteAdmin(scaffold, status: status, withLists: withLists);
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
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the delete-all dialog wipes the lists through the endpoint', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.waiting, withLists: true);

    // Waiting panel: OpeningVote's open + delete-all actions (the
    // + button journey itself is covered by vote_add_edit_list_test).
    expect(find.text('Open votes'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    await scaffold.ensureOnScreen(tester, find.text('All'));
    when(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('All'));
    await pumpFrames(tester, 8);
    expect(find.text('Delete all'), findsOneWidget);
    expect(
      find.text('Do you really want to delete everything?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);

    verify(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).called(1);
    expect(find.text('All deleted'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the open status shows the live count and the close handler '
      'closes the votes', (tester) async {
    await pumpAdmin(tester, status: enums.StatusType.open, withLists: true);

    // Open: no add button, the section's live vote count is loaded, and
    // the close action is available.
    expect(find.byType(CustomIconButton), findsNothing);
    expect(find.text('7 Votes'), findsOneWidget);
    await scaffold.ensureOnScreen(tester, find.text('Close votes'));
    when(
      () => scaffold.repository.campaignStatusClosePost(),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Close votes'));
    await pumpFrames(tester, 12);

    verify(() => scaffold.repository.campaignStatusClosePost()).called(1);
    expect(find.text('Votes closed'), findsOneWidget);
    // The status flipped to closed: the Count-votes button replaces the
    // close action.
    expect(find.text('Count votes'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the closed status count handler counts and lands in the '
      'counting state', (tester) async {
    await pumpAdmin(tester, status: enums.StatusType.closed, withLists: true);

    await scaffold.ensureOnScreen(tester, find.text('Count votes'));
    when(
      () => scaffold.repository.campaignStatusCountingPost(),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Count votes'));
    await pumpFrames(tester, 12);

    verify(() => scaffold.repository.campaignStatusCountingPost()).called(1);
    expect(find.text('Votes counted'), findsOneWidget);
    // Counting state: the graph placeholder replaces the count buttons.
    expect(find.text('Show votes'), findsOneWidget);
    expect(find.text('Count votes'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('the counting status reveals the graph and publishes through '
      'the dialog', (tester) async {
    await pumpAdmin(tester, status: enums.StatusType.counting, withLists: true);

    // Counting starts with the graph hidden: placeholder + Reset only.
    expect(find.text('Show votes'), findsOneWidget);
    expect(find.textContaining('BDE'), findsWidgets);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Publish'), findsNothing);
    await scaffold.ensureOnScreen(tester, find.text('Show votes'));
    await tester.tap(find.text('Show votes'));
    await pumpFrames(tester, 10);

    // The placeholder is replaced by the graph and the publish row
    // appears and the raw count from the real results endpoint.
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Show votes'), findsNothing);
    // "BDE" renders twice: the list card in the section list above and
    // the chart's bottom-axis label.
    expect(find.text('BDE'), findsNWidgets(2));
    expect(find.text('100.00%'), findsOneWidget);
    expect(find.text('12 Votes'), findsOneWidget);
    await scaffold.ensureOnScreen(tester, find.text('Publish'));
    when(
      () => scaffold.repository.campaignStatusPublishedPost(),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Publish'));
    await pumpFrames(tester, 8);
    expect(
      find.text('Do you really want to publish the votes?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);

    verify(() => scaffold.repository.campaignStatusPublishedPost()).called(1);
    // Published keeps the graph (with its labels) and the Reset action,
    // drops the publish row.
    expect(find.text('Publish'), findsNothing);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('BDE'), findsNWidgets(2));
    expect(find.text('100.00%'), findsOneWidget);
    expect(find.text('12 Votes'), findsOneWidget);
  });

  testWidgets('the reset dialog returns the campaign to waiting', (
    tester,
  ) async {
    await pumpAdmin(tester, status: enums.StatusType.counting, withLists: true);

    await scaffold.ensureOnScreen(tester, find.text('Reset'));
    when(
      () => scaffold.repository.campaignStatusResetPost(),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Reset'));
    await pumpFrames(tester, 8);
    expect(find.text('What do you want to do?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);

    verify(() => scaffold.repository.campaignStatusResetPost()).called(1);
    // Waiting again: the placeholder and the opening controls return, and
    // the lists were reloaded by the handler.
    expect(find.text('Votes reset'), findsOneWidget);
    expect(find.text('Show votes'), findsNothing);
    expect(find.byType(CustomIconButton), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
