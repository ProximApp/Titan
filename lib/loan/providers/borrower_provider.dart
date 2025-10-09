import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/user/class/simple_users.dart';

class BorrowerNotifier extends Notifier<SimpleUser> {
  @override
  SimpleUser build() {
    final loan = ref.watch(loanProvider);
    return loan.borrower;
  }

  void setBorrower(SimpleUser borrower) {
    state = borrower;
  }
}

final borrowerProvider = NotifierProvider<BorrowerNotifier, SimpleUser>(
  BorrowerNotifier.new,
);
