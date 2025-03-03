import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class LoanNotifier extends Notifier<Loan> {
  @override
  Loan build() {
    return EmptyModels.empty<Loan>();
  }

  Future<bool> setLoan(Loan loan) async {
    state = loan;
    return true;
  }
}

final loanProvider = NotifierProvider<LoanNotifier, Loan>(LoanNotifier.new);
