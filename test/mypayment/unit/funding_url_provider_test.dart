import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
// `openapi.swagger.dart` re-exports the models, so importing both is the
// `unnecessary_import` the analyze baseline counts.
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/funding_url_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

/// `fundingUrlProvider` is the one half of the top-up hand-off that the
/// widget-level tests cannot see: it is the POST that asks HelloAsso for a
/// payment page, and the button's whole job afterwards is to hand whatever
/// comes back to `launchUrl`.
///
/// It also differs from its two siblings in a way worth pinning explicitly.
/// `MyWalletNotifier.build()` and `TOSNotifier.build()` both call their getter
/// and return `AsyncValue.loading()`; `FundingUrlNotifier.build()` only
/// returns loading and fetches **nothing**. That is why the top-up sheet's
/// cap comes from `tosProvider` and not from here — the funding URL is
/// request-scoped, one POST per attempt, and pre-fetching it would mint a
/// transaction nobody asked for.
void main() {
  late MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockRepository();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  TransferInfo transfer({int amount = 2000}) =>
      TransferInfo.empty().copyWith(amount: amount);

  PaymentUrl paymentUrl() =>
      PaymentUrl.empty().copyWith(url: 'https://helloasso.example/pay');

  void stubPost(Future<chopper.Response<PaymentUrl>> Function() answer) {
    when(
      () => repository.mypaymentTransferInitPost(body: any(named: 'body')),
    ).thenAnswer((_) => answer());
  }

  test('build() does not fetch — the POST is per-attempt', () {
    container.read(fundingUrlProvider);

    expect(container.read(fundingUrlProvider), isA<AsyncLoading<PaymentUrl>>());
    // A funding URL is a transaction: requesting one at build time would mint
    // a HelloAsso session for a top-up the user may never start.
    verifyNever(
      () => repository.mypaymentTransferInitPost(body: any(named: 'body')),
    );
  });

  test('getFundingUrl posts the TransferInfo it was handed, verbatim', () async {
    final posted = <TransferInfo>[];
    when(
      () => repository.mypaymentTransferInitPost(body: any(named: 'body')),
    ).thenAnswer((invocation) async {
      posted.add(invocation.namedArguments[#body] as TransferInfo);
      return chopper.Response(http.Response('body', 200), paymentUrl());
    });

    final result = await container
        .read(fundingUrlProvider.notifier)
        .getFundingUrl(transfer(amount: 95000));

    expect(result, isA<AsyncData<PaymentUrl>>());
    expect(
      (result as AsyncData<PaymentUrl>).value.url,
      'https://helloasso.example/pay',
    );
    // The provider does no arithmetic of its own: the cents conversion and the
    // redirect URL are the BUTTON's job, and a provider that quietly
    // rescaled the amount would make the button's own boundary tests lie.
    expect(posted.single.amount, 95000);
    expect(posted.single.redirectUrl, transfer().redirectUrl);
    expect(container.read(fundingUrlProvider), isA<AsyncData<PaymentUrl>>());
  });

  test(
    'a refused POST becomes an AsyncError carrying the transport error',
    () async {
      stubPost(
        () async => chopper.Response(
          http.Response('{"detail": "refused"}', 500),
          null,
          error: 'funding url refused',
        ),
      );

      final result = await container
          .read(fundingUrlProvider.notifier)
          .getFundingUrl(transfer());

      expect(result, isA<AsyncError<PaymentUrl>>());
      expect(container.read(fundingUrlProvider), isA<AsyncError<PaymentUrl>>());
      // Reading the value off an errored state throws rather than handing back
      // a stale URL, which is what keeps the button's `value.when(data:)` from
      // ever seeing one.
      expect(
        () => container.read(fundingUrlProvider).requireValue,
        throwsA(anything),
      );
    },
  );

  test('a 200 with no body is an error, not an empty PaymentUrl', () async {
    // `load` guards on `data != null` and rethrows `response.error!`. A 200
    // carrying nothing is a real backend failure mode, and treating it as
    // success would hand `Uri.parse('')` to `launchUrl`.
    stubPost(() async => chopper.Response(http.Response('', 200), null));

    final result = await container
        .read(fundingUrlProvider.notifier)
        .getFundingUrl(transfer());

    expect(result, isA<AsyncError<PaymentUrl>>());
  });

  test('a thrown transport error becomes an AsyncError', () async {
    stubPost(() async => throw Exception('network down'));

    final result = await container
        .read(fundingUrlProvider.notifier)
        .getFundingUrl(transfer());

    expect(result, isA<AsyncError<PaymentUrl>>());
    expect(container.read(fundingUrlProvider), isA<AsyncError<PaymentUrl>>());
  });

  test('a good URL is replaced by the next attempt', () async {
    // The button can be pressed again after a failed launch, so the provider
    // must not latch the first URL.
    var call = 0;
    stubPost(() async {
      call++;
      return chopper.Response(
        http.Response('body', 200),
        PaymentUrl.empty().copyWith(url: 'https://example/$call'),
      );
    });
    final notifier = container.read(fundingUrlProvider.notifier);

    await notifier.getFundingUrl(transfer(amount: 1000));
    final second = await notifier.getFundingUrl(transfer(amount: 2000));

    expect((second as AsyncData<PaymentUrl>).value.url, 'https://example/2');
  });
}
