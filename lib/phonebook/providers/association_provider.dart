import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

//  Rework for stateNotifier
class AssociationNotifier extends Notifier<AssociationComplete> {
  @override
  AssociationComplete build() {
    return EmptyModels.empty<AssociationComplete>();
  }

  void setAssociation(AssociationComplete association) {
    state = association;
  }

  void resetAssociation() {
    state = EmptyModels.empty<AssociationComplete>();
  }
}

final associationProvider = NotifierProvider<AssociationNotifier, AssociationComplete>(
  () {
    return AssociationNotifier();
  },
);
