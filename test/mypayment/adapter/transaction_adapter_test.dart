import 'package:flutter_test/flutter_test.dart';

import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;

import 'package:titan/mypayment/adapters/transaction_adapter.dart';
import 'package:titan/mypayment/adapters/store_adapter.dart';

void main() {
  // Handwritten counterpart of the AUTO-GENERATED *_adapter_test.dart files:
  // asserts real FIELD VALUES (direction + zero-checkout semantics) instead of
  // the generated suite's not-null smoke calls. Delete a test here only if the
  // generated file covers the same ground.
  group('mypayment / adapters / transaction_adapter (handwritten values)', () {
    test('TransactionBase.toHistory maps a direct credit transaction', () {
      final tx = models.TransactionBase(
        id: 'tx-1',
        debitedWalletId: 'wallet-debit-1',
        creditedWalletId: 'wallet-credit-1',
        transactionType: enums.TransactionType.direct,
        sellerUserId: null,
        total: 1000,
        creation: DateTime.utc(2026, 1, 5),
        status: enums.TransactionStatus.confirmed,
      );
      final h = tx.toHistory();
      expect(h.id, 'tx-1');
      expect(h.total, 1000);
      expect(h.creation, DateTime.utc(2026, 1, 5));
      expect(h.status, enums.TransactionStatus.confirmed);
      expect(h.type, enums.HistoryType.directTransfer);
      expect(h.direction, enums.HistoryDirection.credited);
      expect(h.otherWalletName, '');
    });

    test('TransactionBase.toHistory maps a request transaction', () {
      final tx = models.TransactionBase(
        id: 'tx-2',
        debitedWalletId: 'wallet-debit-2',
        creditedWalletId: 'wallet-credit-2',
        transactionType: enums.TransactionType.request,
        sellerUserId: null,
        total: 500,
        creation: DateTime.utc(2026, 1, 6),
        status: enums.TransactionStatus.pending,
      );
      final h = tx.toHistory();
      expect(h.id, 'tx-2');
      expect(h.total, 500);
      expect(h.creation, DateTime.utc(2026, 1, 6));
      expect(h.status, enums.TransactionStatus.pending);
      expect(h.type, enums.HistoryType.requestTransaction);
      expect(h.direction, enums.HistoryDirection.credited);
    });
  });

  group('mypayment / adapters / store_adapter (handwritten values)', () {
    test('Store.toUserStore maps the owned fields', () {
      final s = models.Store(
        id: 'store-2',
        name: 'Fridge',
        associationId: 'assoc-2',
        structureId: 'structure-2',
        walletId: 'wallet-2',
        creation: DateTime.utc(2026, 1, 1),
        structure: models.Structure.empty(),
      );
      final us = s.toUserStore();
      expect(us.id, 'store-2');
      expect(us.name, 'Fridge');
      expect(us.associationId, 'assoc-2');
      expect(us.structureId, 'structure-2');
      expect(us.walletId, 'wallet-2');
      expect(us.creation, DateTime.utc(2026, 1, 1));
      expect(us.structure, isA<models.Structure>());
      expect(us.canBank, false);
      expect(us.canSeeHistory, false);
      expect(us.canCancel, false);
      expect(us.canManageSellers, false);
    });
  });
}
