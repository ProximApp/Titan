import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class ManagerNotifier extends Notifier<Manager> {
  @override
  Manager build() {
    return EmptyModels.empty<Manager>();
  }

  void setManager(Manager manager) {
    state = manager;
  }
}

final managerProvider = NotifierProvider<ManagerNotifier, Manager>(
  ManagerNotifier.new,
);
