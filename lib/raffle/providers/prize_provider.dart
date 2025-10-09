import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/prize.dart';

class PrizeNotifier extends Notifier<Prize> {
  @override
  Prize build() => Prize.empty();

  void setPrize(Prize lot) {
    state = lot;
  }
}

final prizeProvider = NotifierProvider<PrizeNotifier, Prize>(PrizeNotifier.new);
