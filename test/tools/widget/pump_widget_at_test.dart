import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';

import '../../shared/app_scaffold.dart';

/// Contract tests for [pumpWidgetAt], the general "any widget, any size"
/// mount: the surface really is the requested viewport, the locale really
/// pins the strings, and the provider scope appears only when a container
/// is passed.
void main() {
  // Both arb libraries primed before any test resolves a locale: the
  // deferred loadLibrary() behind AppLocalizations only completes for the
  // FIRST genuine load in a file (see localization_round_trip_test.dart).
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  testWidgets('honors a custom surface, without a provider scope', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      LayoutBuilder(
        builder: (context, constraints) =>
            Text('w=${constraints.maxWidth.round()}'),
      ),
      surface: const Size(500, 800),
    );

    // The viewport is the requested size, in logical pixels at DPR 1...
    expect(tester.getSize(find.byType(Scaffold)), const Size(500, 800));
    // ...and the widget laid out inside it sees exactly that width.
    expect(find.text('w=500'), findsOneWidget);
    // No container, no scope — the tree starts at ToastificationWrapper.
    expect(find.byType(UncontrolledProviderScope), findsNothing);
  });

  testWidgets('defaults to the 360x640 phone and pins the locale', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      const Text('bonjour le monde'),
      locale: const Locale('fr', 'FR'),
    );

    expect(tester.getSize(find.byType(Scaffold)), const Size(360, 640));
    expect(find.text('bonjour le monde'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.text('bonjour le monde'))),
      const Locale('fr', 'FR'),
      reason:
          'a MaterialApp that ignored the locale would make a '
          'round-trip measure the same strings twice.',
    );
  });

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('mounts under a provider scope when given a container', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    // A provider the seeded container has never seen: if the scope were
    // missing or wired to a different container, this watch would throw
    // instead of rendering.
    final answer = Provider((_) => 42);

    await pumpWidgetAt(
      tester,
      Consumer(
        builder: (context, ref, child) => Text('n=${ref.watch(answer)}'),
      ),
      container: container,
    );

    expect(find.byType(UncontrolledProviderScope), findsOneWidget);
    expect(find.text('n=42'), findsOneWidget);
  });
}
