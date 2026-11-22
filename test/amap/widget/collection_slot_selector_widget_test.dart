import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/providers/order_provider.dart';
import 'package:titan/amap/ui/pages/main_page/collection_slot_selector.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The two halves of the collection-slot strip: the selected one paints its
/// rounded white background, the other one is transparent and only reacts to
/// a tap by writing its slot into the order being built.
void main() {
  testWidgets('tapping a slot writes it into the order', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      container: container,
      const Row(
        children: [
          CollectionSlotSelector(collectionSlot: AmapSlotType.midi),
          CollectionSlotSelector(collectionSlot: AmapSlotType.soir),
        ],
      ),
    );

    expect(container.read(orderProvider).collectionSlot, AmapSlotType.midi);

    await tester.tap(find.byType(CollectionSlotSelector).last);
    await settle(tester, frames: 2);

    expect(container.read(orderProvider).collectionSlot, AmapSlotType.soir);
    expect(container.read(orderProvider), isA<OrderReturn>());
    expect(tester.takeException(), isNull);
  });
}
