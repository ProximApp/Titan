import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/loan/class/loaner.dart';
import 'package:titan/loan/repositories/loaner_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class UserLoanerListNotifier extends ListNotifier<Loaner> {
  LoanerRepository get loanerRepository => ref.watch(loanerRepositoryProvider);

  @override
  AsyncValue<List<Loaner>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Loaner>>> loadMyLoanerList() async {
    return await loadList(loanerRepository.getMyLoaner);
  }

  Future<bool> addLoaner(Loaner loaner) async {
    return await add(loanerRepository.createLoaner, loaner);
  }

  Future<bool> updateLoaner(Loaner loaner) async {
    return await update(
      loanerRepository.updateLoaner,
      (loaners, loaner) =>
          loaners..[loaners.indexWhere((i) => i.id == loaner.id)] = loaner,
      loaner,
    );
  }

  Future<bool> deleteLoaner(Loaner loaner) async {
    return await delete(
      loanerRepository.deleteLoaner,
      (loans, loan) => loans..removeWhere((i) => i.id == loan.id),
      loaner.id,
      loaner,
    );
  }
}

final userLoanerListProvider =
    NotifierProvider<UserLoanerListNotifier, AsyncValue<List<Loaner>>>(
      UserLoanerListNotifier.new,
    );

final loanerList = Provider<List<Loaner>>((ref) {
  final deliveryProvider = ref.watch(userLoanerListProvider);
  return deliveryProvider.maybeWhen(data: (loans) => loans, orElse: () => []);
});
