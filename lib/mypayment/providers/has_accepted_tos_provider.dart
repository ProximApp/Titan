import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/mypayment/providers/tos_provider.dart';

class HasAcceptedTosNotifier extends Notifier<bool> {
  @override
  bool build() {
    final tos = ref.watch(tosProvider);
    return tos.maybeWhen(
      orElse: () => false,
      data: (value) => value.acceptedTosVersion == value.latestTosVersion,
    );
  }

  void update(bool s) {
    state = s;
  }
}

final hasAcceptedTosProvider = NotifierProvider<HasAcceptedTosNotifier, bool>(
  HasAcceptedTosNotifier.new,
);
