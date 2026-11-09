import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/router.dart';

import '../../shared/app_scaffold.dart';

/// `PaymentRouter.module`'s metadata closures.
///
/// The router is registered in `AppRouter`, so every mypayment deep-link test
/// constructs its routes — but none of them evaluates `module.getName` or
/// `module.getDescription`, which are the two lines the module card (and the
/// super-admin module list) read. Mirrors
/// test/recommendation/unit/recommendation_router_structure_test.dart.
void main() {
  // The metadata resolves AppLocalizations through a deferred loadLibrary that
  // only completes for the first genuine load in a file under fake async, so
  // the locales are primed in setUpAll (real zone).
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  testWidgets('the module metadata resolves in a localized context', (
    tester,
  ) async {
    expect(PaymentRouter.module.root, PaymentRouter.root);
    String name = '';
    String description = '';
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = PaymentRouter.module.getName(context);
          description = PaymentRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
      appFonts: false,
    );

    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
    expect(description, isNot(name));
  });
}
