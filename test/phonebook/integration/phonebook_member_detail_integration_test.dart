import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
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

  testWidgets('a member whose promo is already a full year is shown as-is', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );

    // Promos are stored either as the two-digit year (26 → 2026) or already
    // as the full year; the page only adds 2000 to the short form.
    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(
          member('u-1', 'Bolt', 'Ada', 'Lovelace').copyWith(promo: 2026),
        );
    container.read(associationListProvider);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.memberDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Promotion 2026'), findsOneWidget);
  });

  testWidgets('a member with no nickname, a phone and two mandates renders '
      'every detail row, and a membership card opens its association', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club'),
        association('a-2', 'Music Club'),
      ]),
    );

    // No nickname (so the real name is the header), a phone number, a promo
    // below 100 (the +2000 arm) and TWO mandates (the plural header).
    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(
          MemberComplete(
            id: 'u-2',
            name: 'Lovelace',
            firstname: 'Ada',
            accountType: enums.AccountType.student,
            schoolId: 'school-1',
            email: 'u-2@myem.fr',
            phone: '+33 6 12 34 56 78',
            promo: 26,
            memberships: [
              MockMembershipComplete.any.copyWith(
                id: 'm-1',
                userId: 'u-2',
                associationId: 'a-1',
                mandateYear: 2026,
                roleName: 'President',
                memberOrder: 0,
              ),
              MockMembershipComplete.any.copyWith(
                id: 'm-2',
                userId: 'u-2',
                associationId: 'a-2',
                mandateYear: 2025,
                roleName: 'Treasurer',
                memberOrder: 1,
              ),
            ],
          ),
        );
    container.read(associationListProvider);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.memberDetail}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    expect(find.textContaining('Ada Lovelace'), findsWidgets);
    expect(find.text('+33 6 12 34 56 78'), findsOneWidget);
    expect(find.textContaining('Promotion 2026'), findsOneWidget);
    // Two mandates: the plural header, and one card per association.
    expect(find.text('Associations'), findsOneWidget);
    expect(find.textContaining('Robot Club - President'), findsOneWidget);
    expect(find.textContaining('Music Club - Treasurer'), findsOneWidget);

    // Tapping a membership card selects that association (the card also
    // routes to it, which the shell's navigator handles).
    await scaffold.ensureOnScreen(
      tester,
      find.textContaining('Music Club - Treasurer'),
    );
    await tester.tap(find.textContaining('Music Club - Treasurer'));
    await settle(tester, frames: 24);

    expect(container.read(associationProvider).id, 'a-2');
    expect(tester.takeException(), isNull);
  });

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
