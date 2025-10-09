import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/paiement/class/transaction.dart';

class OngoingTransaction extends Notifier<AsyncValue<Transaction>> {
  @override
  AsyncValue<Transaction> build() {
    return const AsyncValue.loading();
  }

  void updateOngoingTransaction(AsyncValue<Transaction> transaction) {
    state = transaction;
  }

  void clearOngoingTransaction() {
    state = const AsyncValue.loading();
  }
}

final ongoingTransactionProvider =
    NotifierProvider<OngoingTransaction, AsyncValue<Transaction>>(
      OngoingTransaction.new,
    );
