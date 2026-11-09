import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/providers/single_notifier.dart';

/// Both base notifiers start loading; every subclass in the app calls `load`
/// from its own `build`, so these exercise the defaults they inherit.
class _PlainSingle extends SingleNotifier<int> {}

class _PlainList extends ListNotifier<int> {}

final _singleProvider = NotifierProvider<_PlainSingle, AsyncValue<int>>(
  _PlainSingle.new,
);
final _listProvider = NotifierProvider<_PlainList, AsyncValue<List<int>>>(
  _PlainList.new,
);

void main() {
  test('SingleNotifier starts as AsyncLoading', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(_singleProvider).isLoading, isTrue);
  });

  test('ListNotifier starts as AsyncLoading', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(_listProvider).isLoading, isTrue);
  });
}
