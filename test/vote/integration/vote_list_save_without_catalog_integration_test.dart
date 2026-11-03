import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/providers/list_list_provider.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// Saving a list while the list CATALOG is not loaded.
///
/// Both save branches read `listListProvider` to find the list to attach a
/// picture to: the edit branch looks it up by id, the create branch takes the
/// catalog's last element. Each has an `orElse` arm for a catalog that is
/// still loading or in error — the state a slow first load leaves behind. The
/// successful tests all run with the catalog loaded, so neither fallback had
/// ever executed.
///
/// The fallback must also be HARMLESS: with no catalog there is no id to
/// upload to, so the save still succeeds and no logo request is made.
class _LoadingCatalog extends ListListNotifier {
  _LoadingCatalog();

  bool added = false;
  bool updated = false;

  @override
  AsyncValue<List<ListReturn>> build() => const AsyncValue.loading();

  @override
  Future<bool> addList(ListBase list) async {
    added = true;
    return true;
  }

  @override
  Future<bool> updateList(ListReturn list) async {
    updated = true;
    return true;
  }
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<_LoadingCatalog> pumpForm(
    WidgetTester tester, {
    ListReturn? editing,
  }) async {
    final catalog = _LoadingCatalog();
    final container = scaffold.makeContainer(
      user: voteAdminUserFixture(),
      providerOverrides: [listListProvider.overrideWith(() => catalog)],
    );
    addTearDown(container.dispose);
    if (editing != null) {
      container.read(listProvider.notifier).setId(editing);
    }
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${VoteRouter.root}${VoteRouter.admin}${VoteRouter.addEditList}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
    return catalog;
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String submit,
    bool fillName = false,
  }) async {
    if (fillName) {
      await tester.enterText(find.byType(TextField).first, 'Liste Test');
    }
    await tester.enterText(find.byType(TextField).at(1), 'Une description');
    await tester.enterText(find.byType(TextField).at(2), 'Un programme');
    await settle(tester, frames: 4);
    await tester.dragUntilVisible(
      find.text(submit),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text(submit));
    await settle(tester, frames: 16);
  }

  testWidgets(
    'a create whose catalog never loaded still saves and uploads nothing',
    (tester) async {
      when(
        () => scaffold.repository.campaignListsListIdLogoPost(
          listId: any(named: 'listId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(AppTypesStandardResponsesResult.empty()),
      );

      final catalog = await pumpForm(tester);
      await fillAndSubmit(tester, submit: 'Add', fillName: true);

      expect(catalog.added, isTrue);
      expect(tester.takeException(), isNull);
      // No id came back from the catalog, so nothing could be uploaded — and
      // nothing was attempted against an empty id.
      verifyNever(
        () => scaffold.repository.campaignListsListIdLogoPost(
          listId: any(named: 'listId'),
          image: any(named: 'image'),
        ),
      );
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('an edit whose catalog never loaded still saves', (tester) async {
    final catalog = await pumpForm(
      tester,
      editing: voteListFixture('l-1', 'BDE'),
    );
    // Edit mode prefills name and description; only the program is empty.
    await fillAndSubmit(tester, submit: 'Edit');

    expect(catalog.updated, isTrue);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
  });
}
