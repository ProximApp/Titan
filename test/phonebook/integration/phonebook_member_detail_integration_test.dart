import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_list_provider.dart';
import 'package:titan/phonebook/providers/complete_member_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/member_detail renders the pre-selected member',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
      );

      // Like the association/vote detail pages, the member detail page
      // renders entirely from client-side state.
      container
          .read(completeMemberProvider.notifier)
          .setCompleteMember(
            member('u-1', 'Bolt', 'Ada', 'Lovelace').copyWith(promo: 26),
          );
      // Kick the association list build before pumping: its cards back the
      // membership cards ("Association" header requires a non-empty list).
      container.read(associationListProvider);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${PhonebookRouter.root}${PhonebookRouter.memberDetail}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Nickname bold header, real name below, promo and email.
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      expect(find.text('u-1@myem.fr'), findsOneWidget);
      // MembershipCard title: "association - roleName".
      expect(find.textContaining('Robot Club - President'), findsOneWidget);
    },
  );

  testWidgets('a membership whose association is gone skips its card', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    // The catalog still answers, but the membership's association is not in
    // it any more (deleted server-side, or a mandate left behind): the
    // unguarded `associations.firstWhere(...)` behind the membership card
    // threw "Bad state: No element" out of build and killed the page — the
    // same orphan shape as the groupement lookup on the association pages.
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-2', 'Robot Club')]),
    );

    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(
          member('u-1', 'Bolt', 'Ada', 'Lovelace').copyWith(promo: 26),
        );
    container.read(associationListProvider);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.memberDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Bolt'), findsOneWidget);
    // No association to title the card with, so it is skipped rather than
    // crashing the page.
    expect(find.textContaining('President'), findsNothing);
  });
}
