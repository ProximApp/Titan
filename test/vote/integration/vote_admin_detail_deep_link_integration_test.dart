import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// `/vote/admin/detail` — the admin's read-only view of one list.
///
/// The route hangs under the admin branch, and every existing detail test
/// deep-links `/vote/detail` (the main page's), so this builder never ran and
/// neither did the page's member cards nor its own list card. Both open a
/// bottom sheet whose Edit and Delete buttons are the page's no-ops: it is a
/// view, not an editor, and those callbacks must stay inert.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the admin detail route renders the list with its members and '
      'the cards stay read-only', (tester) async {
    stubVoteAdmin(scaffold, status: enums.StatusType.waiting);
    when(() => scaffold.repository.campaignListsGet())
        .thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
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

    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    final jane = CoreUserSimple.empty().copyWith(
      id: 'u-1',
      firstname: 'Jane',
      name: 'Doe',
    );
    container
        .read(listProvider.notifier)
        .setId(
          ListReturn.empty().copyWith(
            id: 'l-1',
            name: 'Race List',
            description: 'Assemble to race',
            program: 'A whole program',
            section: sectionFixture('s-1', 'Bureau des Sports'),
            members: [
              ListMemberComplete.empty().copyWith(
                userId: 'u-1',
                user: jane,
                role: 'president',
              ),
            ],
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}${VoteRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    // The page itself, both its heading and the member row.
    expect(find.text('Race List'), findsWidgets);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('A whole program'), findsOneWidget);

    // The page is a view: it hands its cards no-op edit/delete callbacks and
    // mounts them WITHOUT `isAdmin`, so the card's sheet (the only place
    // those callbacks are wired to a button) never opens. Tapping a row must
    // therefore offer nothing to press.
    await scaffold.ensureOnScreen(tester, find.text('Jane Doe'));
    await tester.tap(find.text('Jane Doe'));
    await settle(tester, frames: 12);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);

    // Same for the list card at the bottom of the page (its subtitle is the
    // list type, which no other widget on this page shows).
    await scaffold.ensureOnScreen(tester, find.text('serio'));
    await tester.tap(find.text('serio'));
    await settle(tester, frames: 12);
    expect(find.text('Edit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
