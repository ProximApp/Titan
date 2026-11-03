import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/l10n/app_localizations.dart';

/// `FeedRouter.module` carries the label and the description the all-modules
/// page and the settings catalog print. Both are callbacks that resolve an
/// `AppLocalizations` from the context they are handed, so they only work
/// inside a localized tree — which is why they are read here, not by touching
/// the `Module` object's fields.
void main() {
  testWidgets('the feed module metadata resolves in a localized context', (
    tester,
  ) async {
    String? name;
    String? description;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        home: Builder(
          builder: (context) {
            name = FeedRouter.module.getName(context);
            description = FeedRouter.module.getDescription(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(name, 'Events');
    expect(description, isNotEmpty);
    expect(description, isNot('Feed'));
    expect(FeedRouter.module.root, '/feed');
  });
}
