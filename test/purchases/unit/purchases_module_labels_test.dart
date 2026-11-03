import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/purchases/router.dart';

/// `PurchasesRouter.module` supplies the name and description the home page
/// paints for the purchases tile. Both callbacks read AppLocalizations and
/// were never invoked, so a renamed ARB key would only surface as a crash on
/// the home page at runtime.
void main() {
  testWidgets('the module exposes its translated name and description', (
    tester,
  ) async {
    String? name;
    String? description;
    String? expectedName;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            // The delegate resolves on a later frame; until then there is
            // nothing to read.
            if (l10n == null) {
              return const SizedBox.shrink();
            }
            expectedName = l10n.modulePurchases;
            name = PurchasesRouter.module.getName(context);
            description = PurchasesRouter.module.getDescription(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(name, isNotNull);
    expect(name, expectedName);
    expect(description, isNotEmpty);
  });
}
