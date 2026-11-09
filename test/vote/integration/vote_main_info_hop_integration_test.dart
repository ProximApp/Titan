import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The candidate card's info button: the one way a voter reaches a list's
/// detail page from the ballot. Tapping it records the list as the selection
/// and routes to `/vote/detail`, which is exactly the couple of lines the
/// deep-link tests skip by landing on the detail page directly.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the info button on a candidate card opens that list detail', (
    tester,
  ) async {
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.open,
      sections: [sectionFixture('s-1', 'Bureau des Sports')],
      lists: [voteListFixture('l-1', 'BDE')],
    );
    // The main page gates the ballot on the voter permission and loads the
    // sections the voter already voted in.
    when(() => scaffold.repository.campaignVotersGet()).thenAnswer(
      (_) async => chopperResponse(
        CorePermission(
          permissionName: 'vote',
          groups: const ['voter-group-1'],
          accountTypes: const [],
        ),
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

    // The ballot is open to the group the voters endpoint names.
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: 'voter-group-1',
            name: 'students',
          ),
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
    // The cards slide in over 2.4s, one staggered interval each.
    await settle(tester, frames: 40);

    final info = find.byWidgetPredicate(
      (widget) =>
          widget is HeroIcon && widget.icon == HeroIcons.informationCircle,
    );
    expect(info, findsOneWidget);
    await scaffold.ensureOnScreen(tester, info);
    await tester.tap(info);
    await settle(tester, frames: 24);

    // The detail page renders the list that was tapped.
    expect(find.text('BDE'), findsWidgets);
    expect(container.read(listProvider).id, 'l-1');
    expect(tester.takeException(), isNull);
  });
}
