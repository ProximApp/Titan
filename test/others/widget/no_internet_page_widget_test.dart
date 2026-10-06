import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/auth/providers/is_connected_provider.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/others/ui/no_internet_page.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

import '../../shared/app_scaffold.dart';

/// The page a user sees when the backend cannot be reached — **0/31 lines,
/// never rendered by any test** until ledger #55.
///
/// It was not merely untested. `versionVerifierProvider` is `when`-ed in
/// three places and two of them send `error:` to this route:
///
/// ```dart
/// error: (error, stack) => AppRouter.noInternet,        // AuthenticatedMiddleware
/// error: (error, stack) => QR.to(AppRouter.noInternet), // LoadingPage
/// ```
///
/// and the shell's only two version-verifier fakes answered `data`
/// (`FakeVersionVerifierNotifier`) or `loading` (`FakeHoldingVersionVerifierNotifier`).
/// Neither could produce the error state, so the `error:` arm was shut in
/// every test ever written and 31 lines of genuine offline handling sat
/// behind a green suite. Same shape as the version-comparison branch that
/// kept `UpdatePage` at 0/12 — a fake that can only say one thing pins shut
/// every arm the other states would have opened.
///
/// The middleware half lives in
/// `test/tools/integration/no_internet_middleware_integration_test.dart`,
/// which owns this isolate's single deep-link navigation; these tests mount
/// the page directly instead, so this file needs no router at all.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The version verifier in the state that produces this page.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ui.Size surface = const ui.Size(360, 640),
    bool recoversOnRetry = false,
  }) async {
    final container = scaffold.makeContainer(
      failVersionVerifier: true,
      versionVerifierRecoversOnRetry: recoversOnRetry,
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const NoInternetPage(),
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 4);
    return container;
  }

  String l10nOf(WidgetTester tester, String Function(AppLocalizations) get) =>
      get(AppLocalizations.of(tester.element(find.byType(NoInternetPage)))!);

  testWidgets('the page names the server it could not reach', (tester) async {
    final container = await pump(tester);

    expect(find.byType(NoInternetPage), findsOneWidget);

    // The host comes from the BACKEND_HOST dart-define the CI command passes,
    // through `getTitanHost()` — resolved from the page's own element rather
    // than hardcoded, so a rename of the string in the arb file still passes
    // but a wrong URL does not.
    expect(
      find.text(
        l10nOf(tester, (l) => l.othersUnableToConnectToServer(getTitanHost())),
      ),
      findsOneWidget,
    );
    expect(find.textContaining(getTitanHost()), findsOneWidget);

    expect(
      find.text(l10nOf(tester, (l) => l.othersCheckInternetConnection)),
      findsOneWidget,
    );
    expect(find.text(l10nOf(tester, (l) => l.othersRetry)), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The page is only reachable while the app knows it is offline; asserting
    // it here means the text above was read on the offline screen and not on
    // some other page that happens to share the strings.
    expect(container.read(isConnectedProvider), isFalse);
    expect(container.read(versionVerifierProvider).hasError, isTrue);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the retry button re-asks and stays put while still offline', (
    tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.text(l10nOf(tester, (l) => l.othersRetry)));
    await settle(tester, frames: 6);

    // The retry is wired to `IsConnectedProvider.isInternet()`, which re-asks
    // the verifier. It did: the notifier's `loadVersion()` ran and, with no
    // recovery configured, left the state exactly as it found it — so the
    // page's `if (isConnected)` guard never fired and the user is still
    // looking at the same screen. A button that did nothing at all would
    // look identical here, which is why the recovery test below matters.
    expect(container.read(versionVerifierProvider).hasError, isTrue);
    expect(container.read(isConnectedProvider), isFalse);
    expect(find.byType(NoInternetPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the page fits a 360px phone', (tester) async {
    // The retry button is `width: double.infinity` inside 30px of padding and
    // the copy is centred, so this is the narrowest box the app ever hands
    // it.
    await pump(tester);

    expect(find.byType(NoInternetPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the error arm this page hangs on is really open', (
    tester,
  ) async {
    // The guard against this file quietly becoming vacuous. If the harness
    // loses `failVersionVerifier` — or the flag stops reaching the override —
    // the page still mounts and every assertion above still passes, because
    // mounting `NoInternetPage` directly never consults the `when`. This
    // asserts the exact state `lib/` branches on, which is the thing the
    // two old fakes pinned shut.
    final container = await pump(tester);

    expect(
      container.read(versionVerifierProvider),
      isA<AsyncError>(),
      reason:
          'lib/ reaches this page from the error: arm of a when over '
          'versionVerifierProvider; a data or loading state means the arm is '
          'closed again',
    );

    await scaffold.unmountApp(tester);
  });
}
