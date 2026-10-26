import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/recommendation/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart' show fileNotFound;

/// The RecommendationCard's own actions (36 uncovered lines): the
/// discount-code copy button, the info icon that routes to the detail page,
/// and — on the detail page as a recommendation admin — the trash button's
/// CustomDialogBox confirm, both its success arm (toast + `QR.back()` to the
/// list) and its failure arm (error toast, page stays). The card only
/// renders its admin column when `isMainPage` is false, so the delete lives
/// behind the info-icon hop.
///
/// recommendation_information / recommendation_(add_)edit cover the detail
/// and form pages directly — nothing here overlaps their routes.
const adminRecommendationGroupId = '389215b2-ea45-4991-adc1-4d3e471541cf';

/// A deal carrying the nullable `code` the copy row only renders when set.
Recommendation cardDeal(String id, String title, {String? code}) =>
    Recommendation.empty().copyWith(
      id: id,
      title: title,
      summary: 'Two-for-one tickets',
      description: 'Show your student card at the counter.',
      code: code,
      creation: DateTime(2026, 9, 1),
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the card copies its code, opens the detail, and the admin delete '
    'confirm handles both the failing and the succeeding POST',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: adminRecommendationGroupId,
              name: 'admin_recommandation',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      scaffold.stubClipboard(tester);

      when(() => scaffold.repository.recommendationRecommendationsGet())
          .thenAnswer(
            (_) async => chopperListResponse([
              cardDeal('r-1', 'Cinema deal', code: 'OCA-2026'),
            ]),
          );
      when(
        () => scaffold.repository
            .recommendationRecommendationsRecommendationIdPictureGet(
              recommendationId: any(named: 'recommendationId'),
            ),
      ).thenAnswer((_) async => fileNotFound());
      var deleteCalls = 0;
      when(
        () => scaffold.repository
            .recommendationRecommendationsRecommendationIdDelete(
              recommendationId: 'r-1',
            ),
      ).thenAnswer((_) async {
        deleteCalls++;
        if (deleteCalls == 1) {
          // First confirm fails: the caught error must reach the error arm.
          throw Exception('nope');
        }
        return chopperResponseVoid();
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: RecommendationRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester);

      // The card renders with its code row; the copy button writes the code
      // to the in-memory clipboard and toasts.
      expect(find.text('Cinema deal'), findsOneWidget);
      expect(find.text('OCA-2026'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.copy));
      await settle(tester, frames: 6);
      final copied = await Clipboard.getData(Clipboard.kTextPlain);
      expect(copied?.text, 'OCA-2026');
      expect(find.text('Discount code copied'), findsOneWidget);

      // Drain that toast, then hop to the detail page through the info icon
      // (deferred route: pump past the library load).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
        ),
      );
      await settle(tester, frames: 30);

      expect(
        find.text('Show your student card at the counter.'),
        findsOneWidget,
      );
      // Admin column of the isMainPage:false card.
      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.trash,
        ),
        findsOneWidget,
      );

      // First confirm: DELETE throws → the caught error takes the error arm
      // (toast, no pop) and the detail page stays up.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.trash,
        ),
      );
      await settle(tester, frames: 6);
      expect(
        find.text('Are you sure you want to delete this deal?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(deleteCalls, 1);
      expect(find.text('Error during deletion'), findsOneWidget);
      expect(
        find.text('Show your student card at the counter.'),
        findsOneWidget,
      );

      // Second confirm succeeds: toast + QR.back() lands on the list page,
      // whose detail-only description is gone (the list state dropped the
      // deal too).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.trash,
        ),
      );
      await settle(tester, frames: 6);
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      expect(deleteCalls, 2);
      expect(find.text('Deal deleted'), findsOneWidget);
      expect(find.text('Show your student card at the counter.'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
        findsOneWidget,
      );

      // Drain the toast timers.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
