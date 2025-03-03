import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class PackTicketNotifier extends Notifier<PackTicketSimple> {
  @override
  PackTicketSimple build() {
    return EmptyModels.empty<PackTicketSimple>();
  }

  void setPackTicket(PackTicketSimple packTicket) {
    state = packTicket;
  }
}

final packTicketProvider =
    NotifierProvider<PackTicketNotifier, PackTicketSimple>(
      () => PackTicketNotifier(),
    );
