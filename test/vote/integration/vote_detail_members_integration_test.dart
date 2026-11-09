import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart';

/// The detail page's MEMBERS block.
///
/// The existing detail test seeds a list with no members, so the page always
/// took the `list.members.isNotEmpty ? … : const SizedBox()` empty arm. A
/// candidate list with running mates is the normal case, and it is the only
/// thing that renders the member cards and their edit/delete hooks.
///
/// (The card's `onEdit`/`onDelete` closures are deliberately inert here and
/// `ListCard` is built without `isAdmin`, so those two bodies are unreachable
/// from this page — not untested.)
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ListMemberComplete member(String firstname, String name, String role) =>
      ListMemberComplete.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(firstname: firstname, name: name),
        role: role,
      );

  testWidgets('a list with members renders one card per running mate', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    // The main page mounts underneath with no lists, so no card or logo
    // fetch competes with the detail page's state.
    when(() => scaffold.repository.campaignListsGet())
        .thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());

    container
        .read(listProvider.notifier)
        .setId(
          ListReturn.empty().copyWith(
            id: 'list-1',
            name: 'Race List',
            description: 'Assemble to race',
            program: 'Free pizza on Tuesdays',
            section: SectionComplete.empty().copyWith(
              name: 'Bureau des Sports',
            ),
            members: [
              member('Ada', 'Lovelace', 'President'),
              member('Alan', 'Turing', 'Treasurer'),
            ],
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // One MemberCard per member: name from the user, role as the subtitle.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('President'), findsOneWidget);
    expect(find.text('Alan Turing'), findsOneWidget);
    expect(find.text('Treasurer'), findsOneWidget);
    // The program line still renders under them.
    expect(find.text('Free pizza on Tuesdays'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
