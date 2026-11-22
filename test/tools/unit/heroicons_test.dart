import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/heroicons.dart';

void main() {
  group('HeroIcon', () {
    testWidgets('draws every generated icon', (tester) async {
      // `tool/gen_heroicons.dart` inlines the SVG source rather than shipping
      // asset files, so a malformed or truncated drawing would only ever show
      // up at runtime. Rendering the whole set here is what catches it.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: HeroIcons.values
                    .map((icon) => HeroIcon(icon, size: 24))
                    .toList(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroIcon), findsNWidgets(HeroIcons.values.length));
    });

    testWidgets('draws the solid style where it was generated', (tester) async {
      final solid = HeroIcons.values.where((i) => i.solid != null);
      expect(
        solid,
        isNotEmpty,
        reason: 'tool/heroicons.yaml lists no solid icons',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: solid
                  .map((i) => HeroIcon(i, style: HeroIconStyle.solid))
                  .toList(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('an icon asked for a variant it never got trips the assertion', (
      tester,
    ) async {
      // `tool/heroicons.yaml` only lists a couple of solid drawings, so most
      // icons are outline-only. Asking one of those for the solid style is the
      // only way to build the developer-facing message above the fallback.
      final outlineOnly = HeroIcons.values.firstWhere((i) => i.solid == null);

      await tester.pumpWidget(
        MaterialApp(home: HeroIcon(outlineOnly, style: HeroIconStyle.solid)),
      );

      final error = tester.takeException();
      expect(error, isA<AssertionError>());
      expect(
        (error as AssertionError).message,
        allOf(
          contains('HeroIcons.${outlineOnly.name} has no solid variant'),
          contains('tool/heroicons.yaml'),
          contains('dart run tool/gen_heroicons.dart'),
        ),
      );
    });

    test('describes itself for the inspector', () {
      // `debugFillProperties` is what DevTools and `toString` read; the suite
      // otherwise never asks a widget to describe itself.
      const icon = HeroIcon(
        HeroIcons.chevronLeft,
        style: HeroIconStyle.solid,
        size: 20,
        color: Color(0xFF123456),
      );

      expect(
        icon.toString(),
        allOf(
          contains('HeroIcon("chevronLeft"'),
          contains('style: solid'),
          contains('size: 20.0'),
          // `0xFF123456` prints as its sRGB channels.
          contains('red: 0.0706'),
        ),
      );
    });

    test('every icon carries a well-formed outline drawing', () {
      for (final icon in HeroIcons.values) {
        expect(
          icon.outline,
          allOf(startsWith('<svg '), endsWith('</svg>'), contains('viewBox=')),
          reason: 'HeroIcons.${icon.name}',
        );
      }
    });
  });
}
