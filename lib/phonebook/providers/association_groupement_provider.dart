import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

final associationGroupementProvider =
    NotifierProvider<AssociationGroupementNotifier, AssociationGroupement>(
      () => AssociationGroupementNotifier(),
    );

class AssociationGroupementNotifier extends Notifier<AssociationGroupement> {
  @override
  AssociationGroupement build() {
    return EmptyModels.empty<AssociationGroupement>();
  }

  void setAssociationGroupement(AssociationGroupement i) {
    state = i;
  }

  void resetAssociationGroupement() {
    state = EmptyModels.empty<AssociationGroupement>();
  }
}
