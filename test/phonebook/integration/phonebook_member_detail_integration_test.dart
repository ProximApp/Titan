import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_list_provider.dart';
import 'package:titan/phonebook/providers/complete_member_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/member_detail renders the pre-selected member',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubPhonebookPictures(scaffold);
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
}
