import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/vote/class/contender.dart';

final selectedContenderProvider =
    NotifierProvider<SelectedContenderProvider, Contender>(
      SelectedContenderProvider.new,
    );

class SelectedContenderProvider extends Notifier<Contender> {
  @override
  Contender build() => Contender.empty();

  void changeSelection(Contender s) {
    state = s;
  }

  void clear() {
    state = Contender.empty();
  }
}
