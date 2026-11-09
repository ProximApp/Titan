import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

class FavoritesNameNotifier extends Notifier<List<String>> {
  final key = 'favorites';

  @override
  List<String> build() {
    return [];
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(key);

    if (favoritesJson != null) {
      state = favoritesJson;
    }
  }

  void toggleFavorite(String name) {
    if (state.contains(name)) {
      state = state.where((m) => m != name).toList();
    } else {
      state = [...state, name];
    }
    saveFavoritesToSharedPreferences(state);
  }

  /// Moves the favourite at [oldIndex] to [newIndex].
  ///
  /// [newIndex] is the slot the item lands in, which is what this Flutter's
  /// `ReorderableListView.onReorderItem` hands over: it already accounts for
  /// the dragged item no longer occupying its old slot. The previous
  /// `if (oldIndex < newIndex) newIndex -= 1` re-applied that correction, so
  /// dragging a favourite one place down subtracted its own move and the
  /// strip sprang back (a test that drags the first card past the second
  /// pinned it).
  void reorderFavorites(int oldIndex, int newIndex) {
    final copy = state.sublist(0);
    final String item = copy.removeAt(oldIndex);
    copy.insert(newIndex, item);
    state = copy;
    saveFavoritesToSharedPreferences(copy);
  }

  Future<void> saveFavoritesToSharedPreferences(
    List<String> favoritesList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, state);
  }
}

final favoritesNameProvider =
    NotifierProvider<FavoritesNameNotifier, List<String>>(
      FavoritesNameNotifier.new,
    );
