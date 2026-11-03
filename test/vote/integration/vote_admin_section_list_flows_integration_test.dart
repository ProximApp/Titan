import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/providers/section_id_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../vote_fixtures.dart';

/// The waiting admin shell's section strip and list rows
/// (`section_bar.dart`, `section_list_items.dart`, `admin_page.dart` — the
/// three biggest vote gaps): selecting a section chip stores its id, the
/// selected chip's close icon opens the delete-section confirm in both
/// outcomes, each list card's Edit/Delete bottom modal runs both delete
/// outcomes, and the shell's own pull-to-refresh regroups everything.
///
/// The two hops OUT of this page (list Edit → add-edit form, strip + →
/// add-section form) live in their own files: qlevar keeps the active
/// route branch in process-global state, so a second router-driven hop in
/// the same isolate never renders its page (convention 19).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The two sections and (optionally) the lists under s-1, with the
  /// endpoints this file drives: each DELETE answers its first call and
  /// fails its second, so one test can pin both arms.
  void stubSectionListDeletions({
    required List<SectionComplete> sections,
    required List<ListReturn> lists,
  }) {
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.waiting,
      sections: sections,
      lists: lists,
    );
    // ListCard's ListLogo auto-loads; a 404 falls back to the placeholder.
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());
  }

  var listDeletes = 0;
  var sectionDeletes = 0;

  void stubDeleteOutcomes() {
    listDeletes = 0;
    sectionDeletes = 0;
    when(
      () => scaffold.repository.campaignListsListIdDelete(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async {
      listDeletes++;
      if (listDeletes == 1) return chopperResponseVoid();
      throw Exception('list delete failed');
    });
    when(
      () => scaffold.repository.campaignSectionsSectionIdDelete(
        sectionId: any(named: 'sectionId'),
      ),
    ).thenAnswer((_) async {
      sectionDeletes++;
      if (sectionDeletes == 1) return chopperResponseVoid();
      throw Exception('section delete failed');
    });
  }

  testWidgets(
    'the section strip selects chips and the confirms delete sections and lists in both outcomes',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubSectionListDeletions(
        sections: [
          sectionFixture('s-1', 'Bureau des Sports'),
          sectionFixture('s-2', 'Bureau des Arts'),
        ],
        lists: [
          voteListFixture('l-1', 'Club Robotic'),
          voteListFixture('l-2', 'Club Musique'),
        ],
      );
      stubDeleteOutcomes();

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 30);

      expect(find.text('Bureau des Sports'), findsOneWidget);
      expect(find.text('Bureau des Arts'), findsOneWidget);
      // sectionIdProvider seeds from the first section.
      expect(container.read(sectionIdProvider), 's-1');

      // The shell's own pull-to-refresh: onRefresh re-reads the status and
      // the sections and regroups the lists per section (admin_page's
      // Refresher callback — only a pull reaches it).
      await tester.fling(
        find.byType(CustomScrollView).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester, frames: 6);

      // Selecting the other chip stores its id (section_bar's onTap) and
      // swaps the card area to that section — which has no lists.
      await tester.tap(find.text('Bureau des Arts'));
      await settle(tester, frames: 4);
      expect(container.read(sectionIdProvider), 's-2');
      expect(find.text('Club Robotic'), findsNothing);

      // Back to s-1: its two list cards render.
      await tester.tap(find.text('Bureau des Sports'));
      await settle(tester, frames: 4);
      expect(container.read(sectionIdProvider), 's-1');
      expect(find.text('Club Robotic'), findsOneWidget);
      expect(find.text('Club Musique'), findsOneWidget);

      // List card 1 — the card's Edit/Delete bottom modal (150ms debounce
      // first: a timer schedules no frames, so pumpAndSettle alone never
      // crosses it), then the confirm: DELETE succeeds, the toast confirms
      // and the card is gone.
      await tester.tap(find.text('Club Robotic'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.text('Do you really want to delete this list?'),
        findsNothing,
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settle(tester, frames: 6);
      expect(
        find.text('Do you really want to delete this list?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(listDeletes, 1);
      expect(find.text('Candidate list deleted'), findsOneWidget);
      await scaffold.closeModal(tester); // the card's modal stays open
      expect(find.text('Club Robotic'), findsNothing);
      expect(find.text('Club Musique'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // List card 2 — the same path with a failing DELETE: the error toast
      // fires and the card stays.
      await tester.tap(find.text('Club Musique'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await settle(tester, frames: 6);
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(listDeletes, 2);
      expect(find.text('Error deleting'), findsOneWidget);
      await scaffold.closeModal(tester);
      expect(find.text('Club Musique'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // The selected chip shows the admin close icon: deleting s-1
      // succeeds and takes its strip entry with it.
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester, frames: 6);
      expect(
        find.text('Do you really want to delete this section?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(sectionDeletes, 1);
      expect(find.text('Section deleted'), findsOneWidget);
      expect(find.text('Bureau des Sports'), findsNothing);
      expect(find.text('Bureau des Arts'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // The remaining chip must be selected to expose its close icon, then
      // the failing DELETE keeps it on the strip.
      await tester.tap(find.text('Bureau des Arts'));
      await settle(tester, frames: 4);
      expect(container.read(sectionIdProvider), 's-2');
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester, frames: 6);
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(sectionDeletes, 2);
      expect(find.text('Error deleting'), findsOneWidget);
      expect(find.text('Bureau des Arts'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
