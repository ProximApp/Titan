import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/class/ticket_generator.dart';

class TicketGeneratorNotifier extends Notifier<TicketGenerator> {
  @override
  TicketGenerator build() {
    return TicketGenerator.empty();
  }

  void setTicketGenerator(TicketGenerator i) {
    state = i;
  }
}

final ticketGeneratorProvider =
    NotifierProvider<TicketGeneratorNotifier, TicketGenerator>(
      TicketGeneratorNotifier.new,
    );
