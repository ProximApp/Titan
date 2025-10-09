import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/super_admin/providers/module_visibility_list_provider.dart';

class IsExpandedListProvider extends Notifier<List<bool>> {
  @override
  List<bool> build() {
    final modules = ref.read(moduleVisibilityListProvider);
    return modules.maybeWhen(
      data: (data) => List.generate(data.length, (index) => false),
      orElse: () => [],
    );
  }

  void toggle(int i) {
    var copy = state.toList();
    copy[i] = !copy[i];
    state = copy;
  }
}

final isExpandedListProvider =
    NotifierProvider<IsExpandedListProvider, List<bool>>(
      IsExpandedListProvider.new,
    );
