import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class PhNotifier extends Notifier<PaperComplete> {
  @override
  PaperComplete build() {
    return EmptyModels.empty<PaperComplete>();
  }

  void setPh(PaperComplete ph) {
    state = ph;
  }
}

final phProvider = NotifierProvider<PhNotifier, PaperComplete>(PhNotifier.new);
