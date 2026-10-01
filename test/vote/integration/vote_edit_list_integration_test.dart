import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

const adminVoteGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';

SectionComplete section(String id, String name) =>
    SectionComplete.empty().copyWith(id: id, name: name, description: '');

/// The card's Edit journey in its own file: navigation to the deferred
/// add-edit route after another journey wedges the router stack in the same
/// process (README convention 10 — one journey per file).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the list card opens an edit modal and the form is prefilled in edit mode',
    (tester) async {
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
      when(() => scaffold.repository.campaignStatusGet()).thenAnswer(
        (_) async =>
            chopperResponse(VoteStatus(status: enums.StatusType.waiting)),
      );
      when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
        (_) async => chopperListResponse([section('s-1', 'Bureau des Sports')]),
      );
      const listName = 'Liste Pique-Assiette';
      final existing = ListReturn.empty().copyWith(
        id: 'l-1',
        name: listName,
        description: 'Des repas, de la convivialité',
        type: enums.ListType.serio,
        program: 'Un banquet par mois',
        section: section('s-1', 'Bureau des Sports'),
      );
      when(
        () => scaffold.repository.campaignListsGet(),
      ).thenAnswer((_) async => chopperListResponse([existing]));
      when(
        () => scaffold.repository.campaignVotersGet(),
      ).thenAnswer((_) async => chopperResponse(CorePermission.empty()));
      // ListCard mounts fetch each list's logo; the 404 reads as "no bytes"
      // and falls back to the placeholder icon.
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

      ListEdit? capturedEdit;
      String? capturedListId;
      when(
        () => scaffold.repository.campaignListsListIdPatch(
          listId: any(named: 'listId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedEdit = inv.namedArguments[#body] as ListEdit;
        capturedListId = inv.namedArguments[#listId] as String;
        return chopperResponseVoid();
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The list card renders once the sections AND lists loads have both
      // landed (the per-section map refills on each): poll for it.
      for (var i = 0; i < 20 && find.text(listName).evaluate().isEmpty; i++) {
        await settle(tester, frames: 4);
      }
      expect(find.text(listName), findsOneWidget);
      // The subtitle is the raw enum name (lowercase).
      expect(find.textContaining('serio'), findsOneWidget);

      // Tap the card → bottom sheet with Edit / Delete. The card's onTap
      // delays 150ms before showing the sheet, so one more pump cycle is
      // needed after openModal's own pumps.
      await scaffold.openModal(tester, find.text(listName));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(scaffold.isModalOpen(tester), isTrue);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // onEdit pushes the add-edit page while the sheet stays mounted
      // (offstage under the new opaque route), so no manual pop here. The
      // deferred route polls until the form mounts.
      await scaffold.tapInModal(tester, find.text('Edit'));
      for (
        var i = 0;
        i < 20 && find.text('Add a list').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Add a list'), findsOneWidget);
      // Edit mode: the submit button reads "Edit" (the sheet's Edit is
      // offstage under the new page) and the Name controller is prefilled.
      expect(find.text('Edit'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        listName,
      );

      // Rename and submit (button below the fold — scroll to it).
      await tester.enterText(
        find.byType(TextField).first,
        'Liste Pique-Assiette v2',
      );
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Edit'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 12);

      // The real PATCH fired with the new name and the existing list id.
      expect(capturedEdit, isNotNull);
      expect(capturedEdit!.name, 'Liste Pique-Assiette v2');
      expect(capturedEdit!.description, 'Des repas, de la convivialité');
      expect(capturedListId, 'l-1');
      // Back on the admin page with the success toast; drain it.
      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('List edited'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
