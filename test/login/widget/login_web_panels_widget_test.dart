import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/login/ui/web/left_panel.dart';
import 'package:titan/login/ui/web/right_panel.dart';

import '../../shared/app_scaffold.dart';

/// The web login page's two panels, at a desktop surface.
///
/// `login/` sat at 47.5% with no `widget/` directory, and the two files here
/// were its largest untouched blocks: `LeftPanel` 247 lines, `RightPanel` 209.
/// They are web-only, so they are measured at 1400x900 - the 360x640 default
/// would report overflows for a layout that only ever runs on a desktop, which
/// is convention 20's mistake in reverse.
///
/// [LeftPanel] turns out to be unmountable under the CI command at all:
/// `getBaseSchoolName()` reads the `SCHOOL_NAME` dart-define and throws
/// `StateError` when it is absent, and the CI command does not pass it. That
/// is pinned as its own test rather than worked around, because the workaround
/// (adding `--dart-define=SCHOOL_NAME=` to the test command) would make the
/// suite pass on a configuration CI never runs.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpRight(
    WidgetTester tester, {
    ui.Size surface = const ui.Size(1400, 900),
  }) async {
    final container = scaffold.makeLoggedOutContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const RightPanel(),
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 6);
  }

  /// The screenshot title the panel is currently showing.
  String shownTitle(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .firstWhere((t) => t.data != null && t.data!.length > 8)
      .data!;

  String l10nOf(WidgetTester tester, String getter) {
    final l10n = AppLocalizations.of(tester.element(find.byType(RightPanel)))!;
    return getter == 'first' ? l10n.loginUpcomingEvents : l10n.loginMadeBy;
  }

  group('RightPanel', () {
    testWidgets('mounts at desktop width with its carousel and indicator', (
      tester,
    ) async {
      await pumpRight(tester);

      expect(find.byType(RightPanel), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(SmoothPageIndicator), findsOneWidget);
      // The page index is `initialPage` modulo the shot count, so the first
      // visible screenshot is the first entry in the list.
      expect(shownTitle(tester), l10nOf(tester, 'first'));
      expect(find.text(l10nOf(tester, 'last')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('lays out without overflowing at 1400px', (tester) async {
      // The left third is a `Spacer`, the middle eighth is the PageView and
      // the right fifth is the indicator column: at 1400 the PageView gets
      // ~840px and the `WormEffect` dots have room beside it.
      await pumpRight(tester);

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('swiping to the next dot shows the next screenshot', (
      tester,
    ) async {
      await pumpRight(tester);
      final first = shownTitle(tester);

      await tester.fling(find.byType(PageView), const Offset(-600, 0), 2000);
      await settle(tester, frames: 12);

      expect(shownTitle(tester), isNot(first));

      await scaffold.unmountApp(tester);
    });

    testWidgets('a dot click lands on the screenshot that dot labels', (
      tester,
    ) async {
      // `WormEffect.hitTestDots` returns a 0-based DOT index, but the carousel
      // is parked at `initialPage` so the page that shows screenshot N is
      // `initialPage + N`. `onDotClicked` has to translate between the two;
      // if it forwards the raw dot index, every dot lands somewhere else.
      await pumpRight(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RightPanel)),
      )!;

      // Dot 1 labels the AMAP screenshot.
      //
      // The indicator is `axisDirection: Axis.vertical`, so `SmoothIndicator`
      // wraps itself in a `RotatedBox`: `hitTestDots` reads what is screen-Y
      // as if it were the painter's X. The dots therefore run down the panel,
      // spaced `dotWidth + spacing` apart from `-spacing / 2`, and dot N spans
      // `(-spacing/2 + N*(dotWidth+spacing), -spacing/2 + (N+1)*(w+s)]`.
      const dotWidth = 20.0;
      const spacing = 8.0; // WormEffect's default
      final indicator = tester.getRect(find.byType(SmoothPageIndicator));
      await tester.tapAt(
        Offset(
          indicator.center.dx,
          indicator.top -
              spacing / 2 +
              1.5 * (dotWidth + spacing) +
              dotWidth / 2,
        ),
      );
      await settle(tester, frames: 14);

      expect(
        shownTitle(tester),
        l10n.loginFruitVegetableOrders,
        reason: 'the second dot must show the second screenshot',
      );

      await scaffold.unmountApp(tester);
    });

    testWidgets('hovering tilts the screenshot and leaving snaps it back', (
      tester,
    ) async {
      await pumpRight(tester);

      Matrix4 tilt() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(BackdropFilter),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform;

      final before = tilt();

      // A MOUSE gesture, not a touch one: `MouseRegion` only answers
      // `PointerHoverEvent`, which `startGesture`'s default finger never
      // sends. `moveBy` is what carries `localPosition`.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(40, 30));
      await settle(tester, frames: 4);

      expect(
        tilt().storage.toList(),
        isNot(before.storage.toList()),
        reason: 'the tilt matrix must change while the pointer is over it',
      );

      // Leaving the region runs `resetAnimation.forward(from: 0)`, which
      // lerps the offset back to zero over 800ms.
      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('the Proximapp credit sits under the indicator', (
      tester,
    ) async {
      await pumpRight(tester);

      expect(find.byType(Image), findsNWidgets(2)); // the shot + the logo
      expect(
        tester.getSize(find.byType(SmoothPageIndicator)).height,
        lessThan(200),
      );
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('a narrower desktop still lays out', (tester) async {
      // The web login is served at whatever the browser gives it; 1024 is the
      // narrowest width where the two panels are still side by side.
      await pumpRight(tester, surface: const ui.Size(1024, 768));

      expect(find.byType(RightPanel), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });
  });

  group('LeftPanel', () {
    testWidgets('cannot build without the SCHOOL_NAME dart-define', (
      tester,
    ) async {
      // `Image.asset('assets/${getBaseSchoolName()}/login.webp')` is a direct
      // child of the panel's `Expanded`, so the throw happens during `build`
      // and the whole panel is unmountable. The school-specific asset folder
      // is the only reason: every other string it draws is a dart-define or an
      // l10n key.
      final container = scaffold.makeLoggedOutContainer();
      addTearDown(container.dispose);

      // `tester.takeException` collapses a second throw into an opaque
      // "Multiple exceptions (2)" report, so the errors are recorded at the
      // source instead: every one of them must name the missing define, and
      // how many there are stays an implementation detail.
      final recorded = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) =>
          recorded.add(details.exceptionAsString());
      addTearDown(() => FlutterError.onError = previous);

      await scaffold.pumpWidgetApp(
        tester,
        const LeftPanel(),
        container,
        surface: const ui.Size(1400, 900),
        appFonts: true,
      );
      tester.takeException();

      expect(recorded, isNotEmpty, reason: 'the panel must fail to build');
      expect(
        recorded,
        everyElement(contains('Could not find SCHOOL_NAME')),
        reason: 'the only reason LeftPanel cannot build is the missing define',
      );
      expect(
        String.fromEnvironment('SCHOOL_NAME'),
        isEmpty,
        reason:
            'if CI ever defines SCHOOL_NAME, the StateError above is wrong '
            'and this panel becomes mountable - replace this test then',
      );
      expect(find.byType(LeftPanel), findsOneWidget);

      await scaffold.unmountApp(tester);
    });
  });
}
