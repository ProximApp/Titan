import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/class/history_interval.dart';
import 'package:titan/mypayment/providers/barcode_provider.dart';
import 'package:titan/mypayment/providers/bypass_provider.dart';
import 'package:titan/mypayment/providers/fund_amount_provider.dart';
import 'package:titan/mypayment/providers/last_time_scanned.dart';
import 'package:titan/mypayment/providers/new_admin_provider.dart';
import 'package:titan/mypayment/providers/ongoing_transaction.dart';
import 'package:titan/mypayment/providers/pay_amount_provider.dart';
import 'package:titan/mypayment/providers/refund_amount_provider.dart';
import 'package:titan/mypayment/providers/selected_interval_provider.dart';
import 'package:titan/mypayment/providers/selected_store_provider.dart';
import 'package:titan/mypayment/providers/selected_structure_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/mypayment/providers/seller_rights_list_providder.dart';
import 'package:titan/tools/repository/repository.dart';

class FakeOpenapi extends Fake implements Openapi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      // selectedStoreProvider watches myStoresProvider, whose build() touches
      // the repository; a fake keeps that read off the network. updateStore()
      // also persists the last-used store id through shared_preferences.
      overrides: [repositoryProvider.overrideWithValue(FakeOpenapi())],
    );
  });

  tearDown(() => container.dispose());

  group('BarcodeNotifier', () {
    test('starts empty and parses a json barcode', () {
      expect(container.read(barcodeProvider), null);

      final notifier = container.read(barcodeProvider.notifier);
      final scanInfo = notifier.updateBarcode(
        jsonEncode(ScanInfo.empty().copyWith(id: 'scan-1', tot: 250).toJson()),
      );

      expect(scanInfo.id, 'scan-1');
      expect(container.read(barcodeProvider)!.tot, 250);

      notifier.clearBarcode();
      expect(container.read(barcodeProvider), null);
    });
  });

  group('LastTimeScannedNotifier', () {
    test('updates and clears the last scanned date', () {
      final notifier = container.read(lastTimeScannedProvider.notifier);
      expect(container.read(lastTimeScannedProvider), null);

      final date = DateTime(2026, 9, 25, 12);
      notifier.updateLastTimeScanned(date);
      expect(container.read(lastTimeScannedProvider), date);

      notifier.clearLastTimeScanned();
      expect(container.read(lastTimeScannedProvider), null);
    });
  });

  group('amount providers', () {
    test('fund, pay and refund amounts default to empty strings', () {
      expect(container.read(fundAmountProvider), '');
      expect(container.read(payAmountProvider), '');
      expect(container.read(refundAmountProvider), '');
    });

    test('fund, pay and refund amounts can be set', () {
      container.read(fundAmountProvider.notifier).setFundAmount('10.00');
      container.read(payAmountProvider.notifier).setPayAmount('2.50');
      container.read(refundAmountProvider.notifier).setRefundAmount('1.00');

      expect(container.read(fundAmountProvider), '10.00');
      expect(container.read(payAmountProvider), '2.50');
      expect(container.read(refundAmountProvider), '1.00');
    });
  });

  group('BypassNotifier', () {
    test('defaults to false and can be toggled', () {
      expect(container.read(bypassProvider), false);

      container.read(bypassProvider.notifier).setBypass(true);
      expect(container.read(bypassProvider), true);
    });
  });

  group('SellerRightsListNotifier', () {
    test('defaults to owner only and updates one right', () {
      expect(container.read(sellerRightsListProvider), [
        true,
        false,
        false,
        false,
        false,
      ]);

      container.read(sellerRightsListProvider.notifier).updateRights(2, true);

      expect(container.read(sellerRightsListProvider), [
        true,
        false,
        true,
        false,
        false,
      ]);

      container.read(sellerRightsListProvider.notifier).clearRights();
      expect(container.read(sellerRightsListProvider), [
        true,
        false,
        false,
        false,
        false,
      ]);
    });
  });

  group('NewAdminNotifier', () {
    test('defaults to empty and can be updated and reset', () {
      final notifier = container.read(newAdminProvider.notifier);
      expect(container.read(newAdminProvider).id, '');

      final admin = CoreUserSimple.empty().copyWith(id: 'admin-1');
      notifier.updateNewAdmin(admin);
      expect(container.read(newAdminProvider).id, 'admin-1');

      notifier.resetNewAdmin();
      expect(container.read(newAdminProvider).id, '');
    });
  });

  group('SelectedStructureNotifier', () {
    test('defaults to empty and can be set', () {
      final notifier = container.read(selectedStructureProvider.notifier);
      expect(container.read(selectedStructureProvider).id, '');

      final structure = Structure.empty().copyWith(id: 'structure-1');
      notifier.setStructure(structure);
      expect(container.read(selectedStructureProvider).id, 'structure-1');
    });
  });

  group('SelectedStoreNotifier', () {
    test('defaults to empty and can be set', () {
      final notifier = container.read(selectedStoreProvider.notifier);
      expect(container.read(selectedStoreProvider).id, '');

      final store = UserStore.empty().copyWith(id: 'store-1');
      notifier.updateStore(store);
      expect(container.read(selectedStoreProvider).id, 'store-1');
    });
  });

  group('SelectedIntervalNotifier', () {
    test('defaults to the current month', () {
      final interval = container.read(selectedIntervalProvider);
      final now = DateTime.now();
      expect(interval.start.year, now.year);
      expect(interval.start.month, now.month - 1);
      expect(interval.end.day, now.day);
    });

    test('start and end can be updated and cleared', () {
      final notifier = container.read(selectedIntervalProvider.notifier);

      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      notifier.updateStart(start);
      expect(container.read(selectedIntervalProvider).start, start);

      notifier.updateEnd(end);
      expect(container.read(selectedIntervalProvider).end, end);

      notifier.clearSelectedInterval();
      final cleared = container.read(selectedIntervalProvider);
      expect(cleared.start.year, DateTime.now().year);
      expect(cleared.end.year, DateTime.now().year);
    });
  });

  group('HistoryInterval', () {
    test('contains dates inside the interval only', () {
      final interval = HistoryInterval(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31, 23, 59, 59),
      );

      expect(interval.contains(DateTime(2026, 1, 1)), true);
      expect(interval.contains(DateTime(2026, 1, 15)), true);
      expect(interval.contains(DateTime(2026, 1, 31, 23, 59, 59)), true);
      expect(interval.contains(DateTime(2025, 12, 31)), false);
      expect(interval.contains(DateTime(2026, 2, 1)), false);
    });

    test('toString describes the interval', () {
      final interval = HistoryInterval(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31),
      );

      expect(interval.toString(), contains('2026-01-01'));
      expect(interval.toString(), contains('2026-01-31'));
    });
  });

  group('OngoingTransaction', () {
    test('starts loading, can be updated and cleared', () {
      final notifier = container.read(ongoingTransactionProvider.notifier);
      expect(container.read(ongoingTransactionProvider).isLoading, true);

      final history = History.empty().copyWith(id: 'tx-1');
      notifier.updateOngoingTransaction(AsyncValue.data(history));
      expect(container.read(ongoingTransactionProvider).value!.id, 'tx-1');

      notifier.clearOngoingTransaction();
      expect(container.read(ongoingTransactionProvider).isLoading, true);
    });
  });
}
