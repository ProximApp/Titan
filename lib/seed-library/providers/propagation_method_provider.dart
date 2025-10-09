import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/tools/functions.dart';

final propagationMethodProvider =
    NotifierProvider<PropagationMethodNotifier, PropagationMethod>(
      PropagationMethodNotifier.new,
    );

class PropagationMethodNotifier extends Notifier<PropagationMethod> {
  @override
  PropagationMethod build() => PropagationMethod.graine;

  void setPropagationMethod(PropagationMethod i) {
    state = i;
  }
}
