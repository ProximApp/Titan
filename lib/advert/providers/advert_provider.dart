import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class AdvertNotifier extends Notifier<AdvertComplete> {
  @override
  AdvertComplete build() {
    return EmptyModels.empty<AdvertComplete>();
  }

  void setAdvert(AdvertComplete i) {
    state = i;
  }
}

final advertProvider = NotifierProvider<AdvertNotifier, AdvertComplete>(
  AdvertNotifier.new,
);
