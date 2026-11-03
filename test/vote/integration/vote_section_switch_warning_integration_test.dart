import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/vote/providers/section_id_provider.dart';
import 'package:titan/vote/providers/selected_list_provider.dart';
import 'package:titan/vote/router.dart';
import 'package:titan/vote/ui/pages/main_page/side_item.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart';
import '../vote_fixtures.dart';

const voterGroupId = 'voter-group-1';

/// Changing section while a list is picked.
///
/// The sidebar's tap handler has two arms: with nothing selected it just
/// switches section, and with a list selected it warns first — because the
/// choice belongs to the section you were looking at. Only the first arm had
/// ever run: no test selected a list and then touched the sidebar, so the
/// warning dialog and its "clear the selection, then switch" confirmation
/// were dead.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'picking another section with a list selected warns, then clears the choice',
    (tester) async {
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

      // Select the only list: the card's envelope button stores it.
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
      await settle(tester, frames: 8);
      expect(container.read(selectedListProvider).id, 'l-1');

      // Touch another section in the sidebar: the warning appears instead of
      // switching straight away.
      await tester.tap(find.byType(SideItem).last);
      await settle(tester, frames: 10);
      expect(find.byType(CustomDialogBox), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);

      // Confirming drops the picked list and switches to the new section.
      await tester.tap(
        find.descendant(
          of: find.byType(CustomDialogBox),
          matching: find.byType(WaitingButton),
        ),
      );
      await settle(tester, frames: 12);

      expect(container.read(selectedListProvider).id, '');
      expect(container.read(sectionIdProvider), 's-2');
      expect(find.byType(CustomDialogBox), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
