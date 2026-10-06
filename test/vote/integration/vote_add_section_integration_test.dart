import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

const adminVoteGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the add-section form mounts from /vote/admin and creates a section',
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
      when(
        () => scaffold.repository.campaignSectionsGet(),
      ).thenAnswer((_) async => chopperListResponse(<SectionComplete>[]));
      when(
        () => scaffold.repository.campaignListsGet(),
      ).thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
      when(
        () => scaffold.repository.campaignVotersGet(),
      ).thenAnswer((_) async => chopperResponse(CorePermission.empty()));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${VoteRouter.root}${VoteRouter.admin}${VoteRouter.addSection}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The add-section form renders its title and both fields.
      expect(find.text('Add a section'), findsOneWidget);
      expect(find.text('Section name'), findsOneWidget);
      expect(find.text('Section description'), findsOneWidget);

      // Fill and submit: the real POST fires, then the page navigates back.
      when(
        () =>
            scaffold.repository.campaignSectionsPost(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => chopperResponse(
          SectionComplete.empty().copyWith(
            id: 's-new',
            name: 'Culture',
            description: 'Everything culture',
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Culture');
      await tester.enterText(find.byType(TextField).last, 'Everything culture');
      await settle(tester, frames: 4);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 10);

      // The admin page is back and the new section chip is rendered.
      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('Culture'), findsOneWidget);
      // Drain the success-toast timer so nothing stays pending.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
