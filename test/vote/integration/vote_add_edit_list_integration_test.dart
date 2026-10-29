import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';
import '../../shared/fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the + button opens the add-list form and creates a list through the real campaignListsPost',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubVoteAdmin(scaffold, status: enums.StatusType.waiting);
      // ListCard mounts fetch each list's logo; the 404 reads as "no bytes"
      // and falls back to the placeholder icon.
      when(
        () => scaffold.repository.campaignListsListIdLogoGet(
          listId: any(named: 'listId'),
        ),
      ).thenAnswer((_) async => fileNotFound());

      ListBase? capturedList;
      when(
        () => scaffold.repository.campaignListsPost(body: any(named: 'body')),
      ).thenAnswer((inv) async {
        capturedList = inv.namedArguments[#body] as ListBase;
        return chopperResponse(
          ListReturn.empty().copyWith(
            id: 'l-new',
            name: 'Liste Pique-Assiette',
            section: sectionFixture('s-1', 'Bureau des Sports'),
            type: enums.ListType.serio,
          ),
        );
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Waiting state shows the + button next to the Lists header.
      expect(find.text('Lists'), findsOneWidget);
      expect(find.byType(CustomIconButton), findsOneWidget);

      // The + navigates to the add-edit page (deferred route: poll).
      await tester.tap(find.byType(CustomIconButton));
      for (
        var i = 0;
        i < 20 && find.text('Add a list').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Add a list'), findsOneWidget);
      // Create mode: empty name field and the "No member" empty state.
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '',
      );
      expect(find.text('No member'), findsOneWidget);

      // Fill the required fields (Name, Description, Program — all three
      // are non-optional TextEntry validators). The section defaults to the
      // one selected on the admin page before the + was tapped.
      await tester.enterText(
        find.byType(TextField).first,
        'Liste Pique-Assiette',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'Des repas, de la convivialité',
      );
      await tester.enterText(
        find.byType(TextField).at(2),
        'Un banquet par mois',
      );
      await settle(tester, frames: 4);

      // Submit: the real POST fires with the form values, the page pops back
      // to the admin page and the success toast shows. The submit button
      // sits below the fold — scroll it into view first.
      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      expect(capturedList, isNotNull);
      expect(capturedList!.name, 'Liste Pique-Assiette');
      expect(capturedList!.description, 'Des repas, de la convivialité');
      expect(capturedList!.program, 'Un banquet par mois');
      expect(capturedList!.sectionId, 's-1');
      expect(capturedList!.type, enums.ListType.serio);
      // Back on the admin page with the success toast.
      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('List added'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
