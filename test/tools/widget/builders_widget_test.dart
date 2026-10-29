import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';
import 'package:titan/tools/providers/single_map_provider.dart';
import 'package:titan/tools/ui/builders/async_child.dart';
import 'package:titan/tools/ui/builders/single_auto_loader_child.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

class _Map extends SingleMapNotifier<String, String> {}

final _mapProvider = NotifierProvider<_Map, Map<String, AsyncValue<String>?>>(
  _Map.new,
);

void main() {
  group('SingleAutoLoaderChild', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    testWidgets('a null item schedules the auto-load and shows the loader', (
      tester,
    ) async {
      final notifier = container.read(_mapProvider.notifier);
      final loads = <String>[];

      await pumpWidgetAt(
        tester,
        SingleAutoLoaderChild<String, String>(
          item: notifier.state['k'],
          notifier: notifier,
          mapKey: 'k',
          loader: (key) async {
            loads.add(key);
            return AsyncValue.data('done:$key');
          },
          dataBuilder: (context, value) => Text('data:$value'),
        ),
        container: container,
      );

      expect(find.byType(Loader), findsOneWidget);

      // Let the post-frame autoLoad and its loader future land.
      await tester.pump();
      await tester.pump();

      expect(loads, ['k']);
      expect(notifier.state['k']?.value, 'done:k');
    });

    testWidgets('a present item renders through AsyncChild', (tester) async {
      final notifier = container.read(_mapProvider.notifier);

      await pumpWidgetAt(
        tester,
        SingleAutoLoaderChild<String, String>(
          item: const AsyncValue.data('ready'),
          notifier: notifier,
          mapKey: 'k',
          loader: (key) async => AsyncValue.data('done:$key'),
          dataBuilder: (context, value) => Text('data:$value'),
        ),
        container: container,
      );

      expect(find.text('data:ready'), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });
  });

  group('Async4Children through handleLoadingAndError', () {
    testWidgets('a loading member shows the loader instead of the builder', (
      tester,
    ) async {
      await pumpWidgetAt(
        tester,
        Async4Children<String, int, bool, double>(
          values: Tuple4(
            const AsyncValue.data('a'),
            const AsyncLoading(),
            const AsyncValue.data(true),
            const AsyncValue.data(1.5),
          ),
          builder: (context, a, b, c, d) => const Text('all four'),
        ),
      );

      expect(find.text('all four'), findsNothing);
      expect(find.byType(Loader), findsOneWidget);
    });

    testWidgets('an erroring member shows the default localized error', (
      tester,
    ) async {
      await pumpWidgetAt(
        tester,
        Async4Children<String, int, bool, double>(
          values: Tuple4(
            const AsyncValue.data('a'),
            AsyncValue.error(StateError('boom'), StackTrace.empty),
            const AsyncValue.data(true),
            const AsyncValue.data(1.5),
          ),
          builder: (context, a, b, c, d) => const Text('all four'),
        ),
      );

      expect(find.text('all four'), findsNothing);
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });
}
