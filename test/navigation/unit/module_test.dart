import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/navigation/ui/navigation_template.dart';

/// `Module.copy` / `Module.toString` (never called by any page test — the
/// navbar builds `Module`s inline instead) and the two lazily-initialized
/// globals on `NavigationTemplate`, which no test had ever touched: they
/// only run on first access, so a test that imports but never reads them
/// reports them uncovered.
void main() {
  group('Module', () {
    Module makeModule() => Module(
      getName: (_) => 'Cinema',
      getDescription: (_) => 'Movies',
      root: '/cinema',
    );

    test('copy overrides what it is given and keeps the rest', () {
      final copy = makeModule().copy(root: '/new_root');

      expect(copy.root, '/new_root');
      expect(copy.getName(_FakeBuildContext()), 'Cinema');
      expect(copy.getDescription(_FakeBuildContext()), 'Movies');
    });

    test('copy without arguments keeps the original root', () {
      expect(makeModule().copy().root, '/cinema');
    });

    test('toString is the module root', () {
      expect(makeModule().toString(), '/cinema');
    });
  });

  group('NavigationTemplate globals', () {
    test('the root navigator key exists and the transition is 200ms', () {
      expect(rootNavigatorKey, isA<GlobalKey<NavigatorState>>());
      expect(NavigationTemplate.duration, const Duration(milliseconds: 200));
    });
  });
}

/// The callbacks only read `context` through the l10n delegate, and these
/// fakes never call them — a bare fake keeps the test hermetic.
class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Module callbacks never use the context here');
}
