import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/vote/class/contender.dart';

final contenderProvider = NotifierProvider<ContenderNotifier, Contender>(
  ContenderNotifier.new,
);

class ContenderNotifier extends Notifier<Contender> {
  @override
  Contender build() => Contender.empty();

  void setId(Contender p) {
    state = p;
  }
}
