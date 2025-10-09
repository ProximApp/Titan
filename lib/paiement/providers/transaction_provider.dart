import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/refund.dart';
import 'package:titan/paiement/repositories/transaction_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TransactionNotifier extends SingleNotifier<bool> {
  TransactionsRepository get transactionRepository =>
      ref.watch(transactionsRepositoryProvider);

  @override
  AsyncValue<bool> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<bool>> refundTransaction(
    String transactionId,
    Refund refund,
  ) async {
    return await load(
      () => transactionRepository.refundTransaction(transactionId, refund),
    );
  }

  Future<AsyncValue<bool>> cancelTransaction(String transactionId) async {
    return await load(
      () => transactionRepository.cancelTransaction(transactionId),
    );
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<bool>>(
      TransactionNotifier.new,
    );
