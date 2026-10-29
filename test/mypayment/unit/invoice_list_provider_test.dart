import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/invoice_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

// Module-local name kept so a rename does not grep across 60 files;
// the behaviour is the shared whole-app MockOpenapi.
class MockRepository extends MockOpenapi {}

// The invoices endpoints' load calls are the only ones this file exercises
// through build(); everything else drives a notifier already in data.
class _InvoiceListNotifier extends InvoiceListNotifier {
  @override
  AsyncValue<List<Invoice>> build() => const AsyncValue.loading();
}

void main() {
  group('InvoiceListNotifier', () {
    late MockRepository repo;
    late ProviderContainer container;
    late InvoiceListNotifier notifier;

    final invoice = Invoice.empty().copyWith(
      id: 'inv-1',
      reference: 'FA-001',
      paid: false,
      received: false,
    );

    setUp(() {
      repo = MockRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          invoiceListProvider.overrideWith(_InvoiceListNotifier.new),
        ],
      );
      notifier = container.read(invoiceListProvider.notifier);
      // Every CRUD arm runs through handleState, which needs data state.
      notifier.state = AsyncValue.data([invoice]);
    });

    tearDown(() => container.dispose());

    test('getInvoices passes the date window as day strings', () async {
      when(
        () => repo.mypaymentInvoicesGet(
          page: 1,
          pageSize: 20,
          structuresIds: null,
          startDate: '2026-01-01',
          endDate: '2026-01-31',
        ),
      ).thenAnswer((_) async => repo.okList<Invoice>());

      final result = await notifier.getInvoices(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result, isA<AsyncData<List<Invoice>>>());
      verify(
        () => repo.mypaymentInvoicesGet(
          page: 1,
          pageSize: 20,
          structuresIds: null,
          startDate: '2026-01-01',
          endDate: '2026-01-31',
        ),
      ).called(1);
    });

    test('getInvoices defaults to page 1 with no filters', () async {
      when(
        () => repo.mypaymentInvoicesGet(
          page: 1,
          pageSize: 20,
          structuresIds: null,
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer((_) async => repo.okList<Invoice>());

      final result = await notifier.getInvoices();

      expect(result, isA<AsyncData<List<Invoice>>>());
    });

    test('getStructureInvoices targets the structure endpoint', () async {
      when(
        () => repo.mypaymentInvoicesStructuresStructureIdGet(
          structureId: 'st-1',
          page: 2,
          pageSize: 50,
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer((_) async => repo.okList<Invoice>());

      final result = await notifier.getStructureInvoices(
        'st-1',
        page: 2,
        pageLimit: 50,
      );

      expect(result, isA<AsyncData<List<Invoice>>>());
      verify(
        () => repo.mypaymentInvoicesStructuresStructureIdGet(
          structureId: 'st-1',
          page: 2,
          pageSize: 50,
          startDate: null,
          endDate: null,
        ),
      ).called(1);
    });

    test('createInvoice appends the new invoice to the list', () async {
      final created = Invoice.empty().copyWith(id: 'inv-2');
      when(
        () => repo.mypaymentInvoicesStructuresStructureIdPost(
          structureId: 'st-1',
        ),
      ).thenAnswer((_) async => repo.ok(created));

      final ok = await notifier.createInvoice(
        Structure.empty().copyWith(id: 'st-1'),
      );

      expect(ok, isTrue);
      expect(notifier.state.value, hasLength(2));
      expect(notifier.state.value!.last.id, 'inv-2');
    });

    test(
      'updateInvoicePaidStatus patches paid and replaces in place',
      () async {
        when(
          () => repo.mypaymentInvoicesInvoiceIdPaidPatch(
            invoiceId: 'inv-1',
            paid: true,
          ),
        ).thenAnswer((_) async => repo.okVoid());

        final ok = await notifier.updateInvoicePaidStatus(invoice, true);

        expect(ok, isTrue);
        expect(notifier.state.value!.single.paid, isTrue);
      },
    );

    test(
      'updateInvoiceReceivedStatus patches received and replaces in place',
      () async {
        when(
          () =>
              repo.mypaymentInvoicesInvoiceIdReceivedPatch(invoiceId: 'inv-1'),
        ).thenAnswer((_) async => repo.okVoid());

        final ok = await notifier.updateInvoiceReceivedStatus(invoice, true);

        expect(ok, isTrue);
        expect(notifier.state.value!.single.received, isTrue);
      },
    );

    test('a refused paid patch keeps the previous list', () async {
      when(
        () => repo.mypaymentInvoicesInvoiceIdPaidPatch(
          invoiceId: 'inv-1',
          paid: true,
        ),
      ).thenAnswer((_) async => repo.fail<void>(500));

      final ok = await notifier.updateInvoicePaidStatus(invoice, true);

      expect(ok, isFalse);
      expect(notifier.state.value!.single.paid, isFalse);
    });

    test('deleteInvoice removes the invoice from the list', () async {
      when(() => repo.mypaymentInvoicesInvoiceIdDelete(invoiceId: 'inv-1'))
          .thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteInvoice(invoice);

      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });
  });
}
