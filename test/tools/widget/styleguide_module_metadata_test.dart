import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/ui/styleguide/router.dart';

/// The router's `Module` carries the name and the blurb the navigation screens
/// print for the styleguide. Both are localization lambdas, so this mounts a
/// translated app and asks the metadata for its strings.
///
/// Kept in its own file: loading the deferred French translation library here
/// ahead of the styleguide page mount changes what that page's own suite sees.
void main() {
  testWidgets('names and describes the module in French', (tester) async {
    await tester.runAsync(
      () => AppLocalizations.delegate.load(const Locale('fr')),
    );
    String? name;
    String? description;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            name = StyleGuideRouter.module.getName(context);
            description = StyleGuideRouter.module.getDescription(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(name, 'StyleGuide');
    expect(
      description,
      isNotEmpty,
      reason: 'the description is what the module cards print',
    );
    expect(description, isNot(name));
  });
}
