import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/others/ui/rollback_page.dart';
import 'package:titan/others/ui/update_page.dart';
import 'package:titan/version/providers/minimal_hyperion_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';

import '../../shared/app_scaffold.dart';

/// The two "your app is wrong" pages, at phone width.
///
/// `UpdatePage` (12 lines) and `RollbackPage` (22) were at **0%** — not
/// merely untested but *unreachable from any test*, which is a stronger and
/// rarer failure. `lib/` decides between "keep going" and "tell the user to
/// update" with one comparison:
///
/// ```dart
/// versionVerifier.whenData((v) => v.minimalTitanVersionCode <= titanVersion)
/// ```
///
/// repeated verbatim in `AuthenticatedMiddleware`, `AppTemplate` and
/// `LoadingPage`, and the update branch is the `!value` arm of it. The shell
/// pinned both sides — `FakeVersionVerifierNotifier` reporting
/// `minimalTitanVersionCode: 1` and `FakeTitanVersionNotifier` returning a
/// hardcoded `999` — so `1 <= 999` was true in every test ever written, and
/// nothing could make it false. Two whole files sat behind a green suite
/// because of two constants (ledger #55).
///
/// Both pages are pure widgets over providers, so they mount here rather than
/// through a journey. `RollbackPage` additionally reads
/// `minimalHyperionVersionProvider`, whose real notifier loads `pubspec.yaml`
/// through `rootBundle` — a file a test asset bundle does not carry — so the
/// container stubs it; the page is otherwise untestable for an unrelated
/// reason.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    ui.Size surface = const ui.Size(360, 640),
  }) async {
    final container = scaffold.makeContainer(
      titanVersion: 1,
      minimalTitanVersionCode: 1000,
      minimalHyperionVersion: '4.2.0',
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      child,
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 4);
    return container;
  }

  /// The localized string a page rendered, resolved through the page's own
  /// element rather than hardcoded English.
  String l10nOf(
    WidgetTester tester,
    Type page,
    String Function(AppLocalizations) get,
  ) => get(AppLocalizations.of(tester.element(find.byType(page)))!);

  testWidgets('UpdatePage tells the user their version is too old', (
    tester,
  ) async {
    final container = await pump(tester, const UpdatePage());

    // Non-vacuity: the page must really be showing the version the provider
    // reported, which is the whole content of the file.
    expect(find.byType(UpdatePage), findsOneWidget);
    expect(
      find.text(l10nOf(tester, UpdatePage, (l) => l.othersTooOldVersion)),
      findsOneWidget,
    );
    // "Version 1" — the CLIENT's version, read from titanVersionProvider. A
    // hardcoded string here would pass; the value is the assertion.
    expect(find.textContaining('1'), findsWidgets);
    expect(container.read(titanVersionProvider), 1);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('UpdatePage fits a 360px phone', (tester) async {
    // The whole surface, not an artificial box: the page is three Spacers
    // around ~100px of icon plus two Texts, so its minimum height is about
    // 300px. Mounting it in a 200px box overflows by 60 - which says nothing
    // about the app, since the page is never given a box that small.
    await pump(tester, const UpdatePage());

    expect(find.byType(UpdatePage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('RollbackPage reports the version and the Hyperion minimum', (
    tester,
  ) async {
    final container = await pump(tester, const RollbackPage());

    expect(find.byType(RollbackPage), findsOneWidget);
    expect(
      find.text(
        l10nOf(tester, RollbackPage, (l) => l.settingsTooRecentVersion),
      ),
      findsOneWidget,
    );
    expect(container.read(minimalHyperionVersionProvider), '4.2.0');
    // Both version lines are built by string interpolation, so the test has
    // to check the rendered text rather than the widget's properties.
    expect(find.textContaining('4.2.0'), findsOneWidget);
    expect(find.textContaining('1'), findsWidgets);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('RollbackPage names the build flavor', (tester) async {
    // The line reads "… $titanVersion, flavor ${getAppFlavor()}", so it asserts
    // the flavor comes from the dart-define the CI command passes.
    await pump(tester, const RollbackPage());

    expect(find.textContaining('prod'), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('RollbackPage fits a 360px phone', (tester) async {
    await pump(tester, const RollbackPage());

    expect(find.byType(RollbackPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the version branch really is open for these containers', (
    tester,
  ) async {
    // The guard against this file quietly becoming vacuous: if the fakes go
    // back to `1 <= 999`, the branch closes again and the two pages above
    // would still pass - they mount directly and never consult the
    // comparison. This asserts the comparison itself, which is the thing the
    // constants used to pin.
    final container = scaffold.makeContainer(
      titanVersion: 1,
      minimalTitanVersionCode: 1000,
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const SizedBox.shrink(),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    final titanVersion = container.read(titanVersionProvider);
    final minimal = container
        .read(versionVerifierProvider)
        .requireValue
        .minimalTitanVersionCode;

    expect(minimal, 1000);
    expect(titanVersion, 1);
    expect(
      minimal <= titanVersion,
      isFalse,
      reason:
          'this is the exact expression lib/ branches on; false means every '
          'test in the suite is now looking at the update path',
    );

    await scaffold.unmountApp(tester);
  });
}
