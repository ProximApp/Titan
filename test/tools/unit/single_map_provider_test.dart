import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/providers/single_map_provider.dart';

class TestMapNotifier extends SingleMapNotifier<String, int> {}

final testMapProvider =
    NotifierProvider<TestMapNotifier, Map<String, AsyncValue<int>?>>(
      TestMapNotifier.new,
    );

void main() {
  group('SingleMapNotifier', () {
    late ProviderContainer container;
    late TestMapNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(testMapProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('starts empty', () {
      expect(container.read(testMapProvider), isEmpty);
    });

    test('loadTList replaces the map with null values', () {
      notifier.loadTList(['a', 'b']);

      expect(container.read(testMapProvider).keys, ['a', 'b']);
      expect(container.read(testMapProvider).values, everyElement(isNull));
    });

    test('addT adds a missing key but keeps an existing one', () {
      notifier.loadTList(['a']);
      notifier.setTData('a', const AsyncValue.data(1));

      notifier.addT('a');
      notifier.addT('b');

      expect(container.read(testMapProvider)['a']!.value, 1);
      expect(container.read(testMapProvider)['b'], null);
    });

    test('setTData sets and notifies listeners', () {
      var notifications = 0;
      container.listen(testMapProvider, (_, _) => notifications++);

      notifier.loadTList(['a']);
      notifier.setTData('a', const AsyncValue.data(42));

      expect(container.read(testMapProvider)['a']!.value, 42);
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('deleteT removes only present keys', () {
      notifier.loadTList(['a', 'b']);

      notifier.deleteT('a');
      expect(container.read(testMapProvider).keys, ['b']);

      notifier.deleteT('zzz');
      expect(container.read(testMapProvider).keys, ['b']);
    });

    test('resetAll clears the values but keeps the keys', () {
      notifier.loadTList(['a', 'b']);
      notifier.setTData('a', const AsyncValue.data(1));

      notifier.resetAll();

      expect(container.read(testMapProvider).keys, ['a', 'b']);
      expect(container.read(testMapProvider).values, everyElement(isNull));
    });

    test('autoLoad loads the value asynchronously', () async {
      notifier.loadTList(['a']);

      await notifier.autoLoad('a', (t) async => AsyncValue.data(t.length));

      expect(container.read(testMapProvider)['a']!.value, 1);
    });
  });
}
