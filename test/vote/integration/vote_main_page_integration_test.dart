import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/vote/providers/selected_list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

/// The vote MAIN page (`/vote`) with its ListListCard host and ListCard
/// cards (95 + 89 uncovered lines) — no test touched `/vote` before. The
/// page is status-driven like the admin one: open shows the voting cards
/// (envelope select buttons, already-voted gating), published turns them
/// into result bars with per-list percentages, and the canVote gate
/// short-circuits the whole surface. The slide-in animation (2.4s, one
/// staggered interval per card index) needs raw pumps long enough for
/// every interval to complete before taps hit.
///
/// vote_admin_status_handlers covers /vote/admin; vote_detail covers the
/// detail page directly — the main-page surface is new ground here.
const voterGroupId = 'voter-group-1';

SectionComplete section(String id, String name) =>
    SectionComplete.empty().copyWith(id: id, name: name, description: '');

ListReturn listFixture(
  String id,
  String name, {
  enums.ListType type = enums.ListType.serio,
}) => ListReturn.empty().copyWith(
  id: id,
  name: name,
  description: 'Our program',
  type: type,
  section: section('s-1', 'Bureau des Sports'),
  members: const [],
);

void stubVoteMain(
  IntegrationScaffold scaffold, {
  required enums.StatusType status,
  required List<ListReturn> lists,
  List<String> votedSections = const [],
  bool voterAllowed = true,
  Map<String, int> results = const {},
}) {
  when(
    () => scaffold.repository.campaignStatusGet(),
  ).thenAnswer((_) async => chopperResponse(VoteStatus(status: status)));
  when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
    (_) async => chopperListResponse([section('s-1', 'Bureau des Sports')]),
  );
  when(
    () => scaffold.repository.campaignListsGet(),
  ).thenAnswer((_) async => chopperListResponse(lists));
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
  when(
    () => scaffold.repository.campaignVotesGet(),
  ).thenAnswer((_) async => chopperListResponse(votedSections));
  // ListLogo auto-loads each list's logo; the 404 falls back to the
  // placeholder icon.
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
    (_) async => chopperListResponse([
      for (final entry in results.entries)
        AppModulesCampaignSchemasCampaignResult(
          listId: entry.key,
          count: entry.value,
        ),
    ]),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpMain(
    WidgetTester tester, {
    required enums.StatusType status,
    required List<ListReturn> lists,
    List<String> votedSections = const [],
    bool voterAllowed = true,
    Map<String, int> results = const {},
  }) async {
    stubVoteMain(
      scaffold,
      status: status,
      lists: lists,
      votedSections: votedSections,
      voterAllowed: voterAllowed,
      results: results,
    );
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: voterGroupId, name: 'students'),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: VoteRouter.root,
      pumpAndSettle: false,
    );
    // The 2.4s staggered slide-in: pump past every card's curve interval
    // so the cards sit at their final position for taps.
    await settle(tester, frames: 40);
    return container;
  }

  testWidgets('the open main page renders the section cards and the '
      'see-more FAB hides on tap', (tester) async {
    // Six lists: the FAB height heuristic (h > 0) needs enough content.
    final lists = [
      listFixture('l-1', 'BDE'),
      listFixture('l-2', 'BDA', type: enums.ListType.pipo),
      listFixture('l-3', 'Club Robotic'),
      listFixture('l-4', 'Club Musique'),
      listFixture('l-5', 'Club Jeux'),
      listFixture('l-6', 'Vote blanc', type: enums.ListType.blank),
    ];
    await pumpMain(tester, status: enums.StatusType.open, lists: lists);

    // Cards render with the real endpoint data; the capitalized type sits
    // under the name, and the blank list skips its logo/info button.
    expect(find.text('BDE'), findsOneWidget);
    // The capitalized type renders once per card (4 serio + 1 pipo).
    expect(find.text('Serio'), findsNWidgets(4));
    expect(find.text('BDA'), findsOneWidget);
    expect(find.text('Pipo'), findsOneWidget);
    expect(find.text('Vote blanc'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      ),
      findsNWidgets(5),
    );
    // Six lists clear the FAB threshold; tapping it animates the inner
    // scroll to the bottom and FADES the button out (opacity 0 — the
    // widget stays mounted, so assert the scroll, not the removal).
    expect(find.text('See more'), findsOneWidget);
    await tester.tap(find.text('See more'));
    await settle(tester, frames: 20);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .pixels,
      greaterThan(100),
    );
  });

  testWidgets('the envelope select button selects a list', (tester) async {
    final container = await pumpMain(
      tester,
      status: enums.StatusType.open,
      lists: [listFixture('l-1', 'BDE'), listFixture('l-2', 'BDA')],
    );

    // Two selectable cards; tapping the BDE card's button (scoped to the
    // card containing its name — the raw .first icon resolves to the
    // second card's slot) swaps it for the Selected label and stores the
    // list.
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.envelopeOpen,
      ),
      findsNWidgets(2),
    );
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(of: find.text('BDE'), matching: find.byType(Container))
            .first,
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.envelopeOpen,
        ),
      ),
    );
    await settle(tester, frames: 6);

    expect(container.read(selectedListProvider).id, 'l-1');
    expect(find.text('Selected'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.envelopeOpen,
      ),
      findsOneWidget,
    );
  });

  testWidgets('an already-voted section hides the voting buttons', (
    tester,
  ) async {
    await pumpMain(
      tester,
      status: enums.StatusType.open,
      lists: [listFixture('l-1', 'BDE'), listFixture('l-2', 'BDA')],
      votedSections: const ['s-1'],
    );

    // The section was voted: cards render without any select button or
    // Selected label.
    expect(find.text('BDE'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.envelopeOpen,
      ),
      findsNothing,
    );
    expect(find.text('Selected'), findsNothing);
  });

  testWidgets('the published status turns cards into result bars', (
    tester,
  ) async {
    await pumpMain(
      tester,
      status: enums.StatusType.published,
      lists: [listFixture('l-1', 'BDE'), listFixture('l-2', 'BDA')],
      results: const {'l-1': 12, 'l-2': 4},
    );

    // 12/(12+4) = 75% and 25%: the wide bar carries its label inside,
    // the narrow one on the left side of the card.
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);
    // The info buttons stay available in published mode.
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('a non-voter sees the cannot-vote surface', (tester) async {
    await pumpMain(
      tester,
      status: enums.StatusType.open,
      lists: [listFixture('l-1', 'BDE')],
      voterAllowed: false,
    );

    // The canVote gate short-circuits the whole card surface.
    expect(find.text('You cannot vote'), findsOneWidget);
    expect(find.text('BDE'), findsNothing);
    // The admin shortcut is still there for admins-to-be.
    expect(find.byType(CustomIconButton), findsOneWidget);
  });
}
