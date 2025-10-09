import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/advert/class/advert.dart';

class AdvertNotifier extends Notifier<Advert> {
  @override
  Advert build() {
    return Advert.empty();
  }

  void setAdvert(Advert i) {
    state = i;
  }
}

final advertProvider = NotifierProvider<AdvertNotifier, Advert>(
  AdvertNotifier.new,
);
