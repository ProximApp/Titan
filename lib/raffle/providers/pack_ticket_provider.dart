import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/pack_ticket.dart';

class PackTicketNotifier extends Notifier<PackTicket> {
  @override
  PackTicket build() {
    return PackTicket.empty();
  }

  void setPackTicket(PackTicket packTicket) {
    state = packTicket;
  }
}

final packTicketProvider = NotifierProvider<PackTicketNotifier, PackTicket>(
  () => PackTicketNotifier(),
);
