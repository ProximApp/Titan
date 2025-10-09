import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/loan/class/loan.dart';
import 'package:titan/loan/class/loaner.dart';
import 'package:titan/tools/providers/map_provider.dart';

class AdminHistoryLoanListNotifier extends MapNotifier<Loaner, Loan> {}

final adminHistoryLoanListProvider =
    NotifierProvider<
      AdminHistoryLoanListNotifier,
      Map<Loaner, AsyncValue<List<Loan>>?>
    >(() => AdminHistoryLoanListNotifier());
