import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:titan/vote/providers/section_id_provider.dart';
import 'package:titan/vote/providers/selected_list_provider.dart';
import 'package:titan/vote/router.dart';
import 'package:titan/vote/ui/pages/main_page/side_item.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart';
import '../vote_fixtures.dart';

const voterGroupId = 'voter-group-1';

/// The sidebar's OTHER arm: switching section with nothing picked.
///
/// Its sibling file drives the warning dialog, which only appears when a list
/// is selected. With no selection the tap must switch straight through —
/// start the slide animation and store the section id — and no dialog may
/// interrupt. That two-line arm was the last reachable code in the file.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('with no list picked the sidebar switches section directly', (
    tester,
  ) async {
    when(() => scaffold.repository.campaignStatusGet()).thenAnswer(
      (_) async => chopperResponse(VoteStatus(status: enums.StatusType.open)),
    );
    when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
      (_) async => chopperListResponse([
        sectionFixture('s-1', 'Bureau des Sports'),
        sectionFixture('s-2', 'Bureau des Arts'),
      ]),
    );
    when(() => scaffold.repository.campaignListsGet()).thenAnswer(
      (_) async => chopperListResponse([voteListFixture('l-1', 'BDE')]),
    );
    when(() => scaffold.repository.campaignVotersGet()).thenAnswer(
      (_) async => chopperResponse(
        CorePermission(
          permissionName: 'vote',
          groups: const [voterGroupId],
          accountTypes: const [],
        ),
      ),
    );
    when(() => scaffold.repository.campaignVotesGet())
        .thenAnswer((_) async => chopperListResponse(const <String>[]));
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());
    when(() => scaffold.repository.campaignResultsGet())
        .thenAnswer((_) async => chopperListResponse([]));

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [CoreGroupSimple.empty().copyWith(id: voterGroupId)],
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
    await settle(tester, frames: 40);

    // Nothing selected: the store is still empty.
    expect(container.read(selectedListProvider).id, '');

    await tester.tap(find.byType(SideItem).last);
    await settle(tester, frames: 12);

    // Straight through, and no warning was raised on the way.
    expect(container.read(sectionIdProvider), 's-2');
    expect(find.byType(CustomDialogBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
