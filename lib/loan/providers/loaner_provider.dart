import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/tools/builders/empty_models.dart';

final loanerProvider = Provider((ref) {
  final loanerId = ref.watch(loanerIdProvider);
  final loanerList = ref.watch(userLoanerListProvider);
  return loanerList.maybeWhen(
    data: (loanerList) =>
        loanerList.firstWhere((loaner) => loaner.id == loanerId),
    orElse: () => EmptyModels.empty<Loaner>(),
  );
});
