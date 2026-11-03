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

/// The admin invoices page fetches on mount (ledger #8), so its list comes
/// from this stub rather than from a pre-seeded provider.
void stubInvoiceList(
  IntegrationScaffold scaffold, {
  List<Invoice> invoices = const [],
}) {
  when(
    () => scaffold.repository.mypaymentInvoicesGet(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      structuresIds: any(named: 'structuresIds'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse<Invoice>(invoices));
}

/// Same for the structure's own list, which the structure invoices page
/// fetches on mount with the selected structure's id.
void stubStructureInvoiceList(
  IntegrationScaffold scaffold, {
  List<Invoice> invoices = const [],
}) {
  when(
    () => scaffold.repository.mypaymentInvoicesStructuresStructureIdGet(
      structureId: any(named: 'structureId'),
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse<Invoice>(invoices));
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

/// A member's wallet with a predictable balance.
Wallet wallet(int balance) => Wallet.empty().copyWith(balance: balance);

/// The terms-of-service answer the pages render before acceptance.
TOSSignatureResponse tos() => TOSSignatureResponse.empty().copyWith(
  acceptedTosVersion: 0,
  latestTosVersion: 0,
  tosContent: 'Some terms',
);

/// The endpoint set the mypayment home page fans out to on mount: wallet,
/// stores, TOS, requests, structures and the wallet history behind its
/// refresh. (These seven `stub*` helpers used to be seven same-named
/// `stubMyPayment` copies, one per file.)
void stubMainPage(IntegrationScaffold scaffold, {List<History>? historyList}) {
  when(() => scaffold.repository.mypaymentUsersMeWalletGet())
      .thenAnswer((_) async => chopperResponse(wallet(2510)));
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse(<UserStore>[]));
  when(() => scaffold.repository.mypaymentUsersMeTosGet())
      .thenAnswer((_) async => chopperResponse(tos()));
  when(() => scaffold.repository.mypaymentRequestsGet())
      .thenAnswer((_) async => chopperListResponse(<Request$>[]));
  when(() => scaffold.repository.mypaymentStructuresGet())
      .thenAnswer((_) async => chopperListResponse(<Structure>[]));
  when(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
      .thenAnswer((_) async => chopperListResponse(historyList ?? <History>[]));
}

/// The devices page's one read.
void stubDevices(IntegrationScaffold scaffold, {List<WalletDevice>? devices}) {
  when(
    () => scaffold.repository.mypaymentUsersMeWalletDevicesGet(),
  ).thenAnswer((_) async => chopperListResponse(devices ?? <WalletDevice>[]));
}

/// The used-requests list the request-history page filters.
void stubUsedRequests(
  IntegrationScaffold scaffold, {
  List<Request$>? requests,
}) {
  when(() => scaffold.repository.mypaymentRequestsGet(used: true))
      .thenAnswer((_) async => chopperListResponse(requests ?? <Request$>[]));
}

/// The store-admin shell: the signed-in member's one store plus its seller
/// roster (the member must be a seller of `store-1` for the cards to show).
void stubStoreAdmin(IntegrationScaffold scaffold, {List<Seller>? sellers}) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse([userStoreFixture]));
  when(
    () => scaffold.repository.mypaymentStoresStoreIdSellersGet(
      storeId: 'store-1',
    ),
  ).thenAnswer((_) async => chopperListResponse(sellers ?? <Seller>[]));
}

/// The store-stats page: its store plus the date-ranged history the chart
/// plots.
void stubStoreStats(
  IntegrationScaffold scaffold, {
  List<History>? historyList,
}) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse([userStoreFixture]));
  when(
    () => scaffold.repository.mypaymentStoresStoreIdHistoryGet(
      storeId: 'store-1',
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse(historyList ?? <History>[]));
}

/// The structure's store list, plus the association picker list the
/// add-edit store page loads.
void stubStructureStores(
  IntegrationScaffold scaffold, {
  List<UserStore>? stores,
}) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse(stores ?? <UserStore>[]));
  when(() => scaffold.repository.associationsGet())
      .thenAnswer((_) async => chopperListResponse(<Association>[]));
}

/// The transfer form's two reads: the member's stores to pick from and the
/// user search behind its recipient field.
void stubTransferStructure(IntegrationScaffold scaffold) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse([userStoreFixture]));
  when(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
      .thenAnswer((_) async => chopperListResponse(<CoreUserSimple>[]));
}
