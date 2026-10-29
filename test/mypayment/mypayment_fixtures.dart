import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../shared/app_scaffold.dart';

/// A registered wallet device with a predictable wallet and creation stamp;
/// two device files carried identical copies.
WalletDevice device(
  String id,
  String name, {
  WalletDeviceStatus status = WalletDeviceStatus.active,
}) => WalletDevice.empty().copyWith(
  id: id,
  name: name,
  walletId: 'wallet-1',
  creation: DateTime(2026, 1, 5),
  status: status,
);

/// Stubs the wallet read the payment cards and payment delegates mount with.
void stubWallet(IntegrationScaffold scaffold, int balance) {
  when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
    (_) async => chopperResponse(
      Wallet.empty().copyWith(id: 'wallet-1', balance: balance),
    ),
  );
}

/// InvoiceCard previews the invoice PDF on build; both invoice list pages
/// stub the same bytes answer.
void stubInvoicePreviews(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.mypaymentInvoicesInvoiceIdGet(
      invoiceId: any(named: 'invoiceId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopper.Response(http.Response.bytes([1, 2, 3], 200), [1, 2, 3]),
  );
}

/// Create a structure managed by the supplied user.
Structure structureFixture(String id, String name, String userId) =>
    Structure.empty().copyWith(
      id: id,
      name: name,
      managerUserId: userId,
      managerUser: CoreUserSimple.empty().copyWith(id: userId),
    );

/// Create a confirmed direct transaction with predictable common fields.
History historyFixture(String id, HistoryDirection direction, int total) =>
    History.empty().copyWith(
      id: id,
      type: HistoryType.directTransaction,
      direction: direction,
      otherWalletName: 'BDE',
      total: total,
      creation: DateTime(2026, 1, 5, 12, 30),
      status: TransactionStatus.confirmed,
    );

/// Compatibility fixture for tests written before the shared naming cleanup.
History history(String id, HistoryDirection direction, int total) =>
    historyFixture(id, direction, total);

/// Compatibility fixture for tests written before the shared naming cleanup.
Structure structure(String id, String name, String userId) =>
    structureFixture(id, name, userId);

/// A store fixture used by mypayment pages and shared card layout tests.
final userStoreFixture = UserStore.empty().copyWith(
  id: 'store-1',
  name: 'Fridge',
  structureId: 'structure-1',
  structure: Structure.empty().copyWith(id: 'structure-1', name: 'BDE'),
);
