import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/loan/class/loan.dart';
import 'package:titan/loan/repositories/loan_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class LoanListNotifier extends ListNotifier<Loan> {
  LoanRepository get loanRepository => ref.watch(loanRepositoryProvider);

  @override
  AsyncValue<List<Loan>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Loan>>> loadLoanList() async {
    return await loadList(loanRepository.getMyLoanList);
  }

  Future<bool> addLoan(Loan loan) async {
    return await add(loanRepository.createLoan, loan);
  }

  Future<bool> updateLoan(Loan loan) async {
    return await update(loanRepository.updateLoan, (loans, loan) {
      final index = loans.indexWhere((l) => l.id == loan.id);
      loans[index] = loan;
      return loans;
    }, loan);
  }

  Future<bool> deleteLoan(Loan loan) async {
    return await delete(
      loanRepository.deleteLoan,
      (loans, loan) => loans..removeWhere((i) => i.id == loan.id),
      loan.id,
      loan,
    );
  }

  Future<bool> returnLoan(Loan loan) async {
    return await delete(
      loanRepository.returnLoan,
      (loans, loan) => loans..removeWhere((i) => i.id == loan.id),
      loan.id,
      loan,
    );
  }
}

final loanListProvider =
    NotifierProvider<LoanListNotifier, AsyncValue<List<Loan>>>(
      LoanListNotifier.new,
    );
