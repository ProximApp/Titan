import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/navigation/ui/navigation_template.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/add_edit_button_layout.dart';
import 'package:titan/tools/ui/layouts/app_template.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

/// The three template-level branches that only the edge of the app reaches: the
/// app template's two "show the page alone" arms, the styleguide list item
/// without a tap target and the layout's gradient variant.
class _FakeVerifier extends VersionVerifierNotifier {
  _FakeVerifier(this.value);

  final AsyncValue<CoreInformation> value;

  @override
  AsyncValue<CoreInformation> build() => value;
}

class _BuildNumber extends TitanVersionNotifier {
  @override
  int build() => 0;
}

class _LoggedIn extends IsLoggedInProvider {
  _LoggedIn(this.value);

  final bool value;

  @override
  bool build() => value;
}

void main() {
  Widget wrap(Widget child, {bool loggedIn = true, int minimal = 0}) =>
      ProviderScope(
        overrides: [
          versionVerifierProvider.overrideWith(
            () => _FakeVerifier(
              AsyncValue.data(
                CoreInformation(
                  ready: true,
                  version: '1',
                  minimalTitanVersionCode: minimal,
                ),
              ),
            ),
          ),
          titanVersionProvider.overrideWith(_BuildNumber.new),
          isLoggedInProvider.overrideWith(() => _LoggedIn(loggedIn)),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  group('AppTemplate', () {
    testWidgets('a stale build shows the page on its own', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTemplate(child: Text('page')), minimal: 5),
      );

      expect(find.text('page'), findsOneWidget);
      expect(find.byType(NavigationTemplate), findsNothing);
    });

    testWidgets('a signed-out shell shows the page on its own', (tester) async {
      await tester.pumpWidget(
        wrap(const AppTemplate(child: Text('page')), loggedIn: false),
      );

      expect(find.text('page'), findsOneWidget);
      expect(find.byType(NavigationTemplate), findsNothing);
    });
  });

  group('ListItem', () {
    testWidgets('without a tap target there is no chevron', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ListItem(title: 'Plain')),
      );

      expect(find.text('Plain'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.chevronRight,
        ),
        findsNothing,
      );
    });

    testWidgets('with a tap target the chevron shows and taps through', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ListItem(title: 'Tappable', onTap: () => taps++),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.chevronRight,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Tappable'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('AddEditButtonLayout', () {
    testWidgets('a color pair paints the radial gradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddEditButtonLayout(
            color: Colors.black,
            colors: [Colors.red, Colors.orange],
            child: Text('Save'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AddEditButtonLayout),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.gradient, isA<RadialGradient>());
      expect((decoration.gradient! as RadialGradient).colors.length, 2);
      expect(decoration.color, isNull);
    });

    testWidgets('a single colour is used as a flat fill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddEditButtonLayout(color: Colors.teal, child: Text('Save')),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AddEditButtonLayout),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, Colors.teal);
      expect(decoration.gradient, isNull);
    });
  });
}
