import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class NewAdminNotifier extends Notifier<CoreUserSimple> {
  @override
  CoreUserSimple build() => EmptyModels.empty<CoreUserSimple>();

  void updateNewAdmin(CoreUserSimple newAdmin) {
    state = newAdmin;
  }

  void resetNewAdmin() {
    state = EmptyModels.empty<CoreUserSimple>();
  }
}

final newAdminProvider = NotifierProvider<NewAdminNotifier, CoreUserSimple>(
  NewAdminNotifier.new,
);
