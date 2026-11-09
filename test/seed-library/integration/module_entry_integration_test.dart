import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/navigation/ui/all_module_page.dart';
import 'package:titan/seed-library/router.dart';
import 'package:titan/settings/providers/module_list_provider.dart';

import '../../shared/app_scaffold.dart';

/// `seed-library/router.dart:52-53` are the closures that build this module's
/// tile title and subtitle. Every other seed-library test deep-links straight
/// into the module, so the two `AppLocalizations` lookups never ran — an
/// untranslated module would have gone unnoticed.
///
/// The all-modules page is the only screen that reads them, and the existing
/// tests for it override `modulesProvider` with fakes, so this file feeds it
/// the module's own `Module` instance.
class _SeedLibraryOnlyNotifier extends ModulesNotifier {
  @override
  List<Module> build() => [SeedLibraryRouter.module];
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the module lists itself with a localized name and summary', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      userId: 'user-1',
      providerOverrides: [
        modulesProvider.overrideWith(_SeedLibraryOnlyNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const AllModulePage(),
      container: container,
      surface: const ui.Size(600, 900),
      appFonts: true,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AllModulePage)),
    )!;
    expect(find.text(l10n.moduleSeedLibrary), findsOneWidget);
    expect(find.text(l10n.moduleSeedLibraryDescription), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
