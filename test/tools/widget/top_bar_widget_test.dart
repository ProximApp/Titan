import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/providers/rendered_path_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/top_bar.dart';

/// `TopBar` hides its chevron at the module root and shows it everywhere else.
/// Off the root the caller may pass `onBack` to intercept the tap; only that
/// arm is exercised here — the fallthrough to `QR.back()` needs a mounted
/// qlevar router, which the route-level integration shells own.
class _FixedPath extends RenderedPathNotifier {
  _FixedPath(this.path);

  final String path;

  @override
  String build() => path;
}

void main() {
  Widget wrap(String path, {VoidCallback? onBack}) => ProviderScope(
    overrides: [renderedPathProvider.overrideWith(() => _FixedPath(path))],
    child: MaterialApp(
      home: Scaffold(
        body: TopBar(root: '/feed', onBack: onBack, rightIcon: const Text('R')),
      ),
    ),
  );

  testWidgets('the module root shows no chevron', (tester) async {
    await tester.pumpWidget(wrap('/feed'));

    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.chevronLeft,
      ),
      findsNothing,
    );
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('a nested page shows the chevron and calls onBack', (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(wrap('/feed/post', onBack: () => backs++));

    final chevron = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.chevronLeft,
    );
    expect(chevron, findsOneWidget);
    expect(find.text('R'), findsOneWidget);

    await tester.tap(
      find.ancestor(of: chevron, matching: find.byType(IconButton)),
    );
    await tester.pump();

    expect(backs, 1);
    expect(tester.takeException(), isNull);
  });
}
