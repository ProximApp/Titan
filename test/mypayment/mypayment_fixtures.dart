import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/device_provider.dart';
import 'package:titan/mypayment/providers/funding_url_provider.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/providers/ongoing_transaction.dart';
import 'package:titan/mypayment/providers/should_display_tos_dialog.dart';
import 'package:titan/mypayment/providers/tos_provider.dart';
import 'package:titan/mypayment/providers/transaction_provider.dart';

import '../shared/app_scaffold.dart';

/// The user's payment history pinned to a list, so the stats widgets and
/// their derived totals build without a repository call. Four stats widget
/// files carried identical copies.
class FakeHistoryNotifier extends MyHistoryNotifier {
  FakeHistoryNotifier(this.histories);

  final List<History> histories;

  @override
  AsyncValue<List<History>> build() => AsyncValue.data(histories);
}

/// The states the wallet-device read can answer with.
///
/// `DeviceNotifier.getDevice` goes through `SingleNotifierAPI.load`, which
/// answers data for any HTTP reply and lets a transport failure throw — so the
/// account card's `loading` and `error` arms can never come out of a stubbed
/// endpoint. Handing the notifier the answer is how those defensive arms are
/// walked.
class FakeDeviceNotifier extends DeviceNotifier {
  FakeDeviceNotifier(this.answer);

  final AsyncValue<WalletDevice> answer;

  @override
  Future<AsyncValue<WalletDevice>> getDevice(String deviceId) async => answer;
}

/// The same seam for the transaction notifier: the refund sheet and the scan
/// cancel each read a `maybeWhen`/`when` off the answer, and both files keep
/// defensive arms for a loading or errored answer.
class FakeTransactionNotifier extends TransactionNotifier {
  FakeTransactionNotifier({this.refundAnswer, this.cancelAnswer});

  final AsyncValue<bool>? refundAnswer;
  final AsyncValue<bool>? cancelAnswer;

  @override
  Future<AsyncValue<bool>> refundTransaction(
    String transactionId,
    RefundInfo refund,
  ) async => refundAnswer!;

  @override
  Future<AsyncValue<bool>> cancelTransaction(String transactionId) async =>
      cancelAnswer!;
}

/// A transfer-creation call pinned to the state a test needs, so the top-up
/// button's defensive `loading` arm can be walked.
class FakeFundingUrlNotifier extends FundingUrlNotifier {
  FakeFundingUrlNotifier(this.answer);

  final AsyncValue<PaymentUrl> answer;

  @override
  Future<AsyncValue<PaymentUrl>> getFundingUrl(TransferInfo info) async =>
      answer;
}

/// An ongoing transaction that KEEPS the state it was built with.
///
/// The scanner paints this provider, and the real notifier resets it to
/// loading whenever the scan sheet closes, so an overlay that is still pending
/// or still failed *while a code is on screen* needs a notifier whose resets
/// and updates do nothing.
class FakeOngoingTransaction extends OngoingTransaction {
  FakeOngoingTransaction(this.initial);

  final AsyncValue<History> initial;

  @override
  AsyncValue<History> build() => initial;

  @override
  void updateOngoingTransaction(AsyncValue<History> transaction) {}

  @override
  void clearOngoingTransaction() {}
}

/// Terms of service pinned to a state, without the read `TOSNotifier.build`
/// fires.
class FakeTosNotifier extends TOSNotifier {
  FakeTosNotifier(this.answer);

  final AsyncValue<TOSSignatureResponse> answer;

  @override
  AsyncValue<TOSSignatureResponse> build() => answer;
}

/// The main page's "show the new terms" flag, pinned.
///
/// The real notifier derives the flag from the terms themselves, so a dialog
/// mounted while the terms are still loading (its `orElse` arms) can only be
/// reached by pinning the flag.
class FakeShouldDisplayTosDialog extends ShouldDisplayTosDialog {
  FakeShouldDisplayTosDialog(this.answer);

  final bool answer;

  @override
  bool build() => answer;
}

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

/// A store the signed-in member runs: every store-card action is available
/// (scan, manage the sellers, see the history) and they are the structure's
/// manager, so the card's hand-over button renders too.
UserStore managedStoreFixture({
  String id = 'store-1',
  String name = 'Fridge',
}) => UserStore.empty().copyWith(
  id: id,
  name: name,
  structureId: 'structure-1',
  canBank: true,
  canManageSellers: true,
  canSeeHistory: true,
  structure: Structure.empty().copyWith(
    id: 'structure-1',
    name: 'BDE',
    managerUserId: 'user-1',
    managerUser: CoreUserSimple.empty().copyWith(id: 'user-1'),
  ),
);

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
void stubMainPage(
  IntegrationScaffold scaffold, {
  List<History>? historyList,
  List<Request$>? requests,
  List<Structure>? structures,
  Structure? bankAccountHolder,
  List<UserStore>? userStores,
}) {
  when(() => scaffold.repository.mypaymentUsersMeWalletGet())
      .thenAnswer((_) async => chopperResponse(wallet(2510)));
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse(userStores ?? <UserStore>[]));
  when(() => scaffold.repository.mypaymentUsersMeTosGet())
      .thenAnswer((_) async => chopperResponse(tos()));
  when(() => scaffold.repository.mypaymentRequestsGet())
      .thenAnswer((_) async => chopperListResponse(requests ?? <Request$>[]));
  when(
    () => scaffold.repository.mypaymentStructuresGet(),
  ).thenAnswer((_) async => chopperListResponse(structures ?? <Structure>[]));
  when(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
      .thenAnswer((_) async => chopperListResponse(historyList ?? <History>[]));
  if (bankAccountHolder != null) {
    when(() => scaffold.repository.mypaymentBankAccountHolderGet())
        .thenAnswer((_) async => chopperResponse(bankAccountHolder));
  }
}

/// The wallet-device read the account card performs for the key id this
/// install holds: answers the one device, in [status].
void stubWalletDevice(
  IntegrationScaffold scaffold,
  WalletDeviceStatus status, {
  String id = 'device-1',
}) {
  when(
    () => scaffold.repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
      walletDeviceId: any(named: 'walletDeviceId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(device(id, 'Phone', status: status)),
  );
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
