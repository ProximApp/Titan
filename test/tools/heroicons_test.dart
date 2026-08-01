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
