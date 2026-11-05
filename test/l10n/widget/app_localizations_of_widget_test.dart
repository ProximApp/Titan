import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';

/// `AppLocalizations.of` is how every screen reads its strings: it must answer
/// for the app's locale once the deferred library has loaded.
///
/// The translations arrive through a deferred import, and a fake-async pump
/// never completes that real load — `Localizations` simply keeps rendering
/// nothing — so each case warms its own library inside `runAsync` first.
Future<void> pumpLocale(WidgetTester tester, Locale locale) async {
  await tester.runAsync(() => AppLocalizations.delegate.load(locale));

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) =>
            Text(AppLocalizations.of(context)?.moduleSeedLibrary ?? 'loading'),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('of() answers with the French strings under a fr locale', (
    tester,
  ) async {
    await pumpLocale(tester, const Locale('fr'));

    expect(find.text('Grainothèque'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
  });

  testWidgets('of() answers with the English strings under an en locale', (
    tester,
  ) async {
    await pumpLocale(tester, const Locale('en'));

    expect(find.text('Seed Library'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
  });
}
