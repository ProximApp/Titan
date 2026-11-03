import 'package:flutter_test/flutter_test.dart';
import 'package:titan/loan/notification_service.dart';
import 'package:titan/loan/providers/loaner_loan_list_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/loan/router.dart';

/// The notification routing table the push handler reads: which notification
/// keys the loan module claims, where they land, and which providers must be
/// refreshed first. The literal was never evaluated by a test, so a key
/// rename or a wrong root path would have gone unnoticed.
void main() {
  test('routes the three loan notification keys to the loan root', () {
    expect(loanProviders.keys.toList()..sort(), [
      'delayedLoans',
      'loans',
      'userLoans',
    ]);
    for (final entry in loanProviders.entries) {
      expect(
        entry.value.item1,
        LoanRouter.root,
        reason: '${entry.key} must open the loan module',
      );
      expect(entry.value.item2, isNotEmpty, reason: entry.key);
    }
  });

  test('user notifications refresh the user loaners, admin ones the loans', () {
    final userLoans = loanProviders['userLoans']!;
    final delayed = loanProviders['delayedLoans']!;
    final admin = loanProviders['loans']!;

    expect(userLoans.item2, contains(userLoanerListProvider));
    expect(delayed.item2, contains(userLoanerListProvider));
    expect(admin.item2, contains(loanerLoanListProvider));
    // The two audiences are distinct: an admin push must not reload the
    // borrower's own list.
    expect(admin.item2, isNot(contains(userLoanerListProvider)));
  });
}
