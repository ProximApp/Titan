import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
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
    'deep link to /phonebook/association_detail renders the pre-selected association and its members',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
      );
      when(
        () => scaffold.repository
            .phonebookAssociationsAssociationIdMembersMandateYearGet(
              associationId: 'a-1',
              mandateYear: 2026,
            ),
      ).thenAnswer(
        (_) async =>
            chopperListResponse([member('u-1', 'Bolt', 'Ada', 'Lovelace')]),
      );

      // The detail page renders from client-side state set by the list page.
      container
          .read(associationProvider.notifier)
          .setAssociation(association('a-1', 'Robot Club'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.text('Robot Club'), findsOneWidget);
      expect(find.textContaining('2026 term'), findsOneWidget);
      // MemberCard title: "nickname - roleName".
      expect(find.textContaining('Bolt - President'), findsOneWidget);

      // The card itself is the way into the member's page: it stores the
      // member and routes to /phonebook/member_detail.
      await tester.tap(find.textContaining('Bolt - President'));
      await settle(tester);

      expect(container.read(completeMemberProvider).id, 'u-1');
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('u-1@myem.fr'), findsOneWidget);
      // This member has no promo; the row is skipped instead of throwing on
      // the null (see the null-guard comment on the page).
      expect(find.textContaining('Promotion'), findsNothing);
    },
  );

  testWidgets('the association detail page shows its empty-member state', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer((_) async => chopperListResponse(<MemberComplete>[]));

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No member'), findsOneWidget);
  });
}
