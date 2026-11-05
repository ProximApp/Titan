import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';

/// The generated delegate is the only way the app gets its strings, and both
/// translations load through a deferred import: a wrong locale code or a
/// broken library load would surface as a blank UI rather than a compile
/// error, so these pin the lookup itself.
///
/// `app_localizations.dart` is fully covered here. The per-language files stay
/// at their handful of executed getters by design: they are generated, every
/// string is its own getter, and only the ones the suite reads ever run —
/// exercising all ~3300 of them would test the generator, not the app.
void main() {
  group('lookupAppLocalizations', () {
    test('loads the French library', () async {
      final l10n = await lookupAppLocalizations(const Locale('fr'));

      expect(l10n, isA<AppLocalizations>());
      expect(l10n.moduleSeedLibrary, 'Grainothèque');
      expect(l10n.moduleSeedLibraryDescription, 'Consulter la grainothèque');
    });

    test('loads the English library', () async {
      final l10n = await lookupAppLocalizations(const Locale('en'));

      expect(l10n.moduleSeedLibrary, 'Seed Library');
      expect(l10n.moduleSeedLibraryDescription, 'View the seed library');
    });

    test('rejects a locale the app does not ship', () async {
      // The lookup throws before it returns a future, so the closure form is
      // what actually catches it.
      expect(
        () => lookupAppLocalizations(const Locale('es')),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('unsupported locale'),
          ),
        ),
      );
    });
  });

  group('the delegate', () {
    test('supports exactly the shipped languages', () {
      final delegate = AppLocalizations.delegate;

      expect(delegate.isSupported(const Locale('fr')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('es')), isFalse);
      // Reloading on every rebuild would re-run the deferred load.
      expect(delegate.shouldReload(delegate), isFalse);
    });

    test('load() answers with the resolved translations', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      expect(l10n.moduleSeedLibrary, 'Grainothèque');
    });

    test('declares the locales it advertises', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toList();

      expect(codes, containsAll(<String>['en', 'fr']));
    });
  });
}
