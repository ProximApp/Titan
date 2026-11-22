import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';

/// The module's settings/notifications metadata: `Module.getName` is what
/// the topics screen groups notifications under and what the settings list
/// labels the entry with, so both closures have to resolve the localized
/// strings for the root page that owns them.
void main() {
  testWidgets('the phonebook module metadata resolves its labels', (
    tester,
  ) async {
    late BuildContext context;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(PhonebookRouter.module.root, PhonebookRouter.root);
    expect(PhonebookRouter.module.getName(context), 'Phonebook');
    expect(PhonebookRouter.module.getDescription(context), isNotEmpty);
  });
}
