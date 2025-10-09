import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/structure.dart';
import 'package:titan/paiement/repositories/bank_account_holder_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class BankAccountHolderNotifier extends SingleNotifier<Structure> {
  BankAccountHolderRepository get bankAccountHolderRepository =>
      ref.watch(bankAccountHolderRepositoryProvider);

  @override
  AsyncValue<Structure> build() {
    getBankAccountHolder();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Structure>> getBankAccountHolder() async {
    return await load(bankAccountHolderRepository.getBankAccountHolder);
  }

  Future<bool> updateBankAccountHolder(Structure structure) async {
    return await add(
      (_) => bankAccountHolderRepository.updateBankAccountHolder(structure),
      structure,
    );
  }
}

final bankAccountHolderProvider =
    NotifierProvider<BankAccountHolderNotifier, AsyncValue<Structure>>(
      BankAccountHolderNotifier.new,
    );
