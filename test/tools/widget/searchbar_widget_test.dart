import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/searchbar.dart';

import '../../shared/app_scaffold.dart';

/// The magnifier tap's two arms (empty → focus, filled → onSearch) and the
/// conditional clear button — neither is reachable from the styleguide demo,
/// which only types into its bars.
void main() {
  testWidgets('the magnifier focuses when empty and searches when filled', (
    tester,
  ) async {
    final queries = <String>[];
    await pumpWidgetAt(
      tester,
      CustomSearchBar(hintText: 'Find', onSearch: queries.add),
    );

    final field = find.byType(TextField);
    final magnifier = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.magnifyingGlass,
    );

    // Empty field: the tap only asks for focus.
    await tester.tap(magnifier);
    await settle(tester, frames: 4);
    expect(tester.widget<TextField>(field).focusNode!.hasPrimaryFocus, isTrue);
    expect(queries, isEmpty);

    // Filled field: onChanged already reported each keystroke…
    await tester.enterText(field, 'robot');
    await settle(tester, frames: 4);
    expect(queries, ['robot']);

    // …and the magnifier reports the whole text again.
    await tester.tap(magnifier);
    await settle(tester, frames: 4);
    expect(queries, ['robot', 'robot']);
    expect(tester.widget<TextField>(field).controller!.text, 'robot');
  });

  testWidgets('the clear button empties the field and disappears with it', (
    tester,
  ) async {
    final queries = <String>[];
    // The bar never rebuilds on its own — its `isNotEmpty` clear button
    // only appears when the PARENT rebuilds, which is what the parent-state
    // setState here mirrors (in the app that is onSearch's consumer
    // rebuild).
    late StateSetter rebuild;
    await pumpWidgetAt(
      tester,
      StatefulBuilder(
        builder: (context, setter) {
          rebuild = setter;
          return CustomSearchBar(
            hintText: 'Find',
            onSearch: (value) {
              queries.add(value);
              setter(() {});
            },
          );
        },
      ),
    );

    final field = find.byType(TextField);
    final clear = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
    );

    // No text, no clear button: the `isNotEmpty` branch never built it.
    expect(clear, findsNothing);

    await tester.enterText(field, 'robot');
    await settle(tester, frames: 4);
    expect(clear, findsOneWidget);

    await tester.tap(clear);
    await settle(tester, frames: 4);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);

    // One more parent rebuild — the button leaves with the empty text.
    rebuild(() {});
    await settle(tester, frames: 4);
    expect(clear, findsNothing);
    expect(queries, ['robot']);
  });

  testWidgets('without a hint the bar falls back to the localized string', (
    tester,
  ) async {
    await pumpWidgetAt(tester, CustomSearchBar(onSearch: (_) {}));

    // The `hintText ??` right-hand side only runs when no hint was given.
    expect(find.text('Search'), findsOneWidget);
  });
}
