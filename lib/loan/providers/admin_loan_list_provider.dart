import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/loan/class/loan.dart';
import 'package:titan/loan/class/loaner.dart';
import 'package:titan/tools/providers/map_provider.dart';

class AdminLoanListNotifier extends MapNotifier<Loaner, Loan> {}

final adminLoanListProvider =
    NotifierProvider<
      AdminLoanListNotifier,
      Map<Loaner, AsyncValue<List<Loan>>?>
    >(() => AdminLoanListNotifier());
