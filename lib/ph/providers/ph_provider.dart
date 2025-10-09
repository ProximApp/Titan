import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/ph/class/ph.dart';

class PhNotifier extends Notifier<Ph> {
  @override
  Ph build() {
    return Ph.empty();
  }

  void setPh(Ph ph) {
    state = ph;
  }
}

final phProvider = NotifierProvider<PhNotifier, Ph>(PhNotifier.new);
