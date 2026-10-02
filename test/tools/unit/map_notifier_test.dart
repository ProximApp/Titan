import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/map_provider.dart';

class MockE {}

class MockT {}

class MockMapNotifier extends MapNotifier<MockT, MockE> {
  MockMapNotifier() : super();

  void testLoadTlist(List<MockT> tList) async {
    return loadTList(tList);
  }

  void testAddT(MockT t) async {
    return addT(t);
  }

  void testAddE(MockT t, MockE e) {
    return addE(t, e);
  }

  void testDeleteT(MockT t) {
    return deleteT(t);
  }

  void testSetTData(MockT t, AsyncValue<List<MockE>> asyncEList) async {
    return setTData(t, asyncEList);
  }

  bool testDeleteE(MockT t, int index) => deleteE(t, index);

  void testResetTData() => resetTData();
}

final mockMapNotifierProvider =
    NotifierProvider<MockMapNotifier, Map<MockT, AsyncValue<List<MockE>>?>>(
      MockMapNotifier.new,
    );

/// The same notifier keyed by `String`, so a test can name a key and revisit
/// it. `MockT` has identity equality, so two `MockT()` are different map keys.
final keyedMapNotifierProvider =
    NotifierProvider<
      MapNotifier<String, MockE>,
      Map<String, AsyncValue<List<MockE>>?>
    >(() => MapNotifier<String, MockE>());

MockMapNotifier makeNotifier() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(mockMapNotifierProvider.notifier);
}

void main() {
  group('Testing MapNotifier : loadTList', () {
    test('Should initiate to AsyncLoading', () {
      final notifier = makeNotifier();
      expect(notifier.state, isA<Map>());
    });

    test('Should state be AsyncData when loading data', () async {
      final notifier = makeNotifier();
      final data = [MockT(), MockT()];
      notifier.testLoadTlist(data);
      expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
      expect(notifier.state.keys.toList(), data);
      expect(notifier.state.values.first, isA<AsyncValue<List<MockE>>?>());
    });
  });

  group('Testing MapNotifier : addT', () {
    test('Should updates state on success', () async {
      final notifier = makeNotifier();
      final data = <MockT, AsyncValue<List<MockE>>?>{
        MockT(): const AsyncLoading(),
        MockT(): const AsyncValue.data(<MockE>[]),
      };
      notifier.state = data;
      final newData = MockT();
      notifier.testAddT(newData);
      expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
      expect(notifier.state.keys.contains(newData), isTrue);
    });

    test(
      'Should sets state on loading when start state is AsyncLoading',
      () async {
        final notifier = makeNotifier();
        final newData = MockT();
        notifier.testAddT(newData);
        expect(notifier.state, isA<Map>());
      },
    );
  });

  group('Testing MapNotifier : addE', () {
    test(
      'Should returns true and updates state on success when value is AsyncData',
      () async {
        final notifier = makeNotifier();
        final key = MockT();
        final data = <MockT, AsyncValue<List<MockE>>>{
          MockT(): const AsyncLoading(),
          key: const AsyncValue.data(<MockE>[]),
        };
        notifier.state = data;
        final newData = MockE();
        final newDataList = [newData];
        notifier.testAddE(key, newData);
        expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
        expect(
          notifier.state[key]!.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          newDataList,
        );
      },
    );

    test(
      'Should returns true and updates state on success when value is AsyncLoading',
      () async {
        final notifier = makeNotifier();
        final key = MockT();
        final data = <MockT, AsyncValue<List<MockE>>>{
          MockT(): const AsyncLoading(),
          key: const AsyncLoading(),
        };
        notifier.state = data;
        final newData = MockE();
        final newDataList = [newData];
        notifier.testAddE(key, newData);
        expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
        expect(
          notifier.state[key]!.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          newDataList,
        );
      },
    );

    test(
      'Should returns true and updates state on success when value is AsyncError',
      () async {
        final notifier = makeNotifier();
        final key = MockT();
        final data = <MockT, AsyncValue<List<MockE>>>{
          MockT(): const AsyncLoading(),
          key: AsyncError("test", StackTrace.current),
        };
        notifier.state = data;
        final newData = MockE();
        final newDataList = [newData];
        notifier.testAddE(key, newData);
        expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
        expect(
          notifier.state[key]!.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          newDataList,
        );
      },
    );
  });

  group('Testing MapNotifier : deleteT', () {
    test('Should returns true and updates state', () async {
      final notifier = makeNotifier();
      final key = MockT();
      final data = <MockT, AsyncValue<List<MockE>>>{
        MockT(): const AsyncLoading(),
        key: const AsyncValue.data(<MockE>[]),
      };
      notifier.state = data;
      notifier.testDeleteT(key);
      expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
      expect(notifier.state.keys.contains(key), isFalse);
    });

    test(
      'Should returns true and does not touch state when key is not in map',
      () async {
        final notifier = makeNotifier();
        final key = MockT();
        final data = <MockT, AsyncValue<List<MockE>>>{
          MockT(): const AsyncLoading(),
          key: const AsyncLoading(),
        };
        notifier.state = data;
        notifier.testDeleteT(MockT());
        expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
        expect(notifier.state.keys, data.keys);
      },
    );
  });

  group('Testing MapNotifier : setTData', () {
    test('Should returns true and updates state', () async {
      final notifier = makeNotifier();
      final key = MockT();
      final data = <MockT, AsyncValue<List<MockE>>>{
        MockT(): const AsyncLoading(),
        key: const AsyncValue.data(<MockE>[]),
      };
      final newData = AsyncValue.data([MockE()]);
      notifier.state = data;
      notifier.testSetTData(key, newData);
      expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
      expect(notifier.state[key]!, newData);
    });

    test(
      'Should returns true and does not touch state when key is not in map',
      () async {
        final notifier = makeNotifier();
        final key = MockT();
        final data = <MockT, AsyncValue<List<MockE>>>{
          MockT(): const AsyncLoading(),
        };
        final newData = AsyncValue.data([MockE()]);
        notifier.state = data;
        notifier.testSetTData(key, newData);
        expect(notifier.state, isA<Map<MockT, AsyncValue<List<MockE>>?>>());
        expect(notifier.state[key]!, newData);
      },
    );
  });

  // Every test above asserts the CONTENTS of the state, which is why the
  // in-place-mutation family hid here for so long: mutating the map really
  // does change what `container.read` returns, so a content assertion passes
  // while the app stays frozen. What is missing from every one of them is the
  // notification.
  //
  // `ProviderElement.defaultUpdateShouldNotify` is `previous != next`, and for
  // a `Map` or `List` `==` is identity. So the old `state = state;` lines —
  // written to "poke" Riverpod after an in-place `state[t] = ...` — compared
  // the map to itself, returned false, and notified nobody. `addE` and
  // `deleteE` were the two that did it, and both have production callers:
  // `advertPostersNotifier.deleteE` and `deliveryOrdersNotifier.deleteE`.
  //
  // A `String`-keyed notifier is used here because `MockT` has identity
  // equality, so two `MockT()` are different map keys and "the same key"
  // cannot be expressed.
  group('MapNotifier notifies on every mutation', () {
    ProviderContainer watchingContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Build first so the first state assignment is not what we measure.
      container.read(keyedMapNotifierProvider);
      return container;
    }

    test('addE notifies exactly once when the key already has a list', () {
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.setTData('a', AsyncData([MockE()]));

      var notifications = 0;
      container.listen(
        keyedMapNotifierProvider,
        (previous, next) => notifications++,
      );

      notifier.addE('a', MockE());

      expect(notifications, 1, reason: 'addE must notify its listeners');
    });

    test('addE notifies when it has to create the entry', () {
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      // A still-loading entry, not a null one: `addE` unwraps `state[t]!`, so
      // a key that exists but has never loaded throws. That is documented
      // as-is by the feed provider's own tests and is not what this is about.
      notifier.setTData('a', const AsyncLoading());

      var notifications = 0;
      container.listen(
        keyedMapNotifierProvider,
        (previous, next) => notifications++,
      );

      notifier.addE('a', MockE());

      expect(notifications, 1);
      expect(notifier.state['a']!.value, hasLength(1));
    });

    test('deleteE notifies', () {
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.setTData('a', AsyncData([MockE(), MockE(), MockE()]));

      var notifications = 0;
      container.listen(
        keyedMapNotifierProvider,
        (previous, next) => notifications++,
      );

      expect(notifier.deleteE('a', 1), isTrue);

      expect(notifications, 1, reason: 'deleteE must notify its listeners');
    });

    test('deleteT notifies', () {
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.addT('a');

      var notifications = 0;
      container.listen(
        keyedMapNotifierProvider,
        (previous, next) => notifications++,
      );

      notifier.deleteT('a');

      expect(notifications, 1);
    });

    test('resetTData notifies', () {
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.setTData('a', AsyncData([MockE()]));

      var notifications = 0;
      container.listen(
        keyedMapNotifierProvider,
        (previous, next) => notifications++,
      );

      notifier.resetTData();

      expect(notifications, 1);
    });

    test('a listener sees the PREVIOUS value, not the mutated one', () {
      // The other half of the bug: mutating in place corrupts the snapshot a
      // listener is holding, so `previous` and `next` both describe the new
      // world and no diff is possible. A map that never notifies is only half
      // the story; the one it does notify has to be immutable.
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.setTData('a', AsyncData([MockE(), MockE(), MockE()]));

      final seen = <int>[];
      container.listen(keyedMapNotifierProvider, (previous, next) {
        seen.add(previous?['a']?.value?.length ?? -1);
      });

      notifier.deleteE('a', 0);
      notifier.addE('a', MockE());

      // Two mutations, two notifications, and the FIRST one was handed a
      // 3-element list — not the 2-element one the old in-place `removeAt`
      // had already produced before Riverpod was even asked.
      expect(seen, [3, 2]);
      expect(
        seen.first,
        3,
        reason: 'the previous snapshot was mutated in place',
      );
      expect(notifier.state['a']!.value, hasLength(3));
    });

    test('the map object itself is replaced, never mutated', () {
      // The identity check is the real invariant: if `state` is still the
      // same Map object after a mutation, some caller still holds the old
      // state and sees the change without being told.
      final container = watchingContainer();
      final notifier = container.read(keyedMapNotifierProvider.notifier);
      notifier.setTData('a', AsyncData([MockE()]));
      final before = notifier.state;

      notifier.addE('a', MockE());
      expect(identical(before, notifier.state), isFalse);

      final afterAdd = notifier.state;
      notifier.deleteE('a', 0);
      expect(identical(afterAdd, notifier.state), isFalse);

      final afterDelete = notifier.state;
      notifier.deleteT('a');
      expect(identical(afterDelete, notifier.state), isFalse);
    });
  });
}
