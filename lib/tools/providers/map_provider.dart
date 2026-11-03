import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MapNotifier<T, E> extends Notifier<Map<T, AsyncValue<List<E>>?>> {
  @override
  Map<T, AsyncValue<List<E>>?> build() {
    return <T, AsyncValue<List<E>>?>{};
  }

  void loadTList(List<T> tList) async {
    Map<T, AsyncValue<List<E>>?> tMap = {};
    for (T l in tList) {
      tMap[l] = null;
    }
    state = tMap;
  }

  void addT(T t) async {
    state = {...state, t: null};
  }

  void addE(T t, E e) {
    final current = state[t];
    if (current == null) {
      state = {
        ...state,
        t: AsyncValue.data([e]),
      };
      return;
    }
    current.maybeWhen(
      data: (eList) {
        state = {
          ...state,
          t: AsyncValue.data(eList + [e]),
        };
      },
      orElse: () {
        state = {
          ...state,
          t: AsyncValue.data([e]),
        };
      },
    );
  }

  void deleteT(T t) {
    if (state.containsKey(t)) {
      state = Map.of(state)..remove(t);
    }
  }

  void setTData(T t, AsyncValue<List<E>> asyncEList) async {
    state = {...state, t: asyncEList};
  }

  void resetTData() async {
    final next = Map.of(state);
    for (T l in next.keys) {
      next[l] = null;
    }
    state = next;
  }

  bool deleteE(T t, int index) {
    // `state[t]` is null both for a key this map never held and for one
    // loadTList/addT/resetTData deliberately reset, and an empty list has no
    // index to remove. A delete with nothing to delete reports failure — the
    // callers (advert poster and amap delivery-order cards) only toast on it.
    final current = state[t];
    if (current == null) {
      return false;
    }
    return current.maybeWhen(
      data: (eList) {
        if (index < 0 || index >= eList.length) {
          return false;
        }
        final next = List<E>.of(eList)..removeAt(index);
        state = {...state, t: AsyncValue.data(next)};
        return true;
      },
      orElse: () => false,
    );
  }

  Future<void> autoLoad(T t, Future<E> Function(T t) loader) async {
    setTData(t, const AsyncLoading());
    loader(t).then((value) {
      setTData(t, AsyncData([value]));
    });
  }

  Future<void> autoLoadList(
    T t,
    Future<AsyncValue<List<E>>> Function(T t) loader,
  ) async {
    setTData(t, const AsyncLoading());
    loader(t).then((value) {
      setTData(t, value);
    });
  }
}
