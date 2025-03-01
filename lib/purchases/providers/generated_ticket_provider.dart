import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class TicketGeneratorNotifier extends Notifier<GenerateTicketComplete> {
  @override
  GenerateTicketComplete build() {
    return EmptyModels.empty<GenerateTicketComplete>();
  }

  void setTicketGenerator(GenerateTicketComplete  i) {
    state = i;
  }
}

final ticketGeneratorProvider =
    NotifierProvider<TicketGeneratorNotifier, GenerateTicketComplete>(
      TicketGeneratorNotifier.new,
    );
