import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:titan/amap/providers/page_controller_provider.dart';
import 'package:titan/amap/providers/sorted_delivery_product.dart';
import 'package:titan/amap/ui/pages/list_products_page/page_view_dots.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The dot strip under the product pager: one dot per category, and a tap on a
/// dot has to animate the shared page controller to that page.
void main() {
  AppModulesAmapSchemasAmapProductComplete product(String category, int i) =>
      AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        id: 'p-$category-$i',
        name: '$category $i',
        category: category,
        price: 1,
      );

  testWidgets('tapping a dot navigates to that category', (tester) async {
    final container = ProviderContainer(
      overrides: [
        deliveryProductList.overrideWithValue([
          product('boissons', 0),
          product('snacks', 0),
          product('snacks', 1),
          product('desserts', 0),
        ]),
      ],
    );
    addTearDown(container.dispose);
    final pageController = container.read(amapPageControllerProvider);

    await pumpWidgetAt(
      tester,
      const _PagerHost(),
      container: container,
      frames: 8,
    );

    final indicator = find.byType(SmoothPageIndicator);
    expect(indicator, findsOneWidget);
    expect(pageController.page, 0);

    // Three dots of 7 px with the effect's 16 px spacing: the last one starts
    // at 46 px and centres at 49.5 px inside the indicator.
    // Three categories, so three dots: 7 px wide with the effect's 8 px gap,
    // the last one running from 30 to 37 px.
    final rect = tester.getRect(indicator);
    expect(rect.width, moreOrLessEquals(37, epsilon: 0.5));
    await tester.tapAt(Offset(rect.left + 33.5, rect.center.dy));
    await settle(tester, frames: 40);

    expect(pageController.page, closeTo(2, 0.05));
    expect(tester.takeException(), isNull);
  });
}

/// The two dots' menu and the pager share one controller, so the animation has
/// a position to drive; a bare indicator would animate nothing.
class _PagerHost extends StatelessWidget {
  const _PagerHost();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Column(
        children: [
          Expanded(
            child: PageView(
              controller: ref.watch(amapPageControllerProvider),
              children: const [Text('one'), Text('two'), Text('three')],
            ),
          ),
          const Dots(),
        ],
      ),
    );
  }
}
