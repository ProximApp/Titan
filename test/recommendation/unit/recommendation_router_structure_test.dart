import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/recommendation/router.dart';

import '../../shared/app_scaffold.dart';

/// RecommendationRouter is registered in AppRouter, so its route
/// CONSTRUCTION runs in every recommendation deep-link test — but none of
/// them evaluates the module metadata closures: `module.getName` and
/// `module.getDescription` (router.dart lines 24-26) are the residual
/// uncovered router lines. The metadata widget test mirrors
/// test/booking/unit/booking_router_structure_test.dart.
void main() {
  // The metadata widget test resolves AppLocalizations through a deferred
  // loadLibrary that only completes for the first genuine load in a file
  // under fake async; priming in setUpAll runs in the real zone.
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  testWidgets('the module metadata resolves in a localized context', (
    tester,
  ) async {
    expect(RecommendationRouter.module.root, RecommendationRouter.root);
    String name = '';
    String description = '';
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = RecommendationRouter.module.getName(context);
          description = RecommendationRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
      appFonts: false,
    );
    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
  });
}
