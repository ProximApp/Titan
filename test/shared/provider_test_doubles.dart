import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';

/// Deterministic loaner-id override for provider tests.
class FixedLoanerIdProvider extends LoanerIdProvider {
  FixedLoanerIdProvider(this.id);

  final String id;

  @override
  String build() => id;
}

/// Pre-seeds loaner access for tests of pages and gates without repository IO.
class FakeUserLoanerListNotifier extends UserLoanerListNotifier {
  FakeUserLoanerListNotifier(this.loaners);

  final List<Loaner> loaners;

  @override
  AsyncValue<List<Loaner>> build() => AsyncValue.data(loaners);
}
