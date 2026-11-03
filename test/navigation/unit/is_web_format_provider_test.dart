import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/navigation/providers/is_web_format_provider.dart';

/// `isWebFormatProvider` reads the FIRST view off the platform dispatcher and
/// answers whether its safe width (screen minus horizontal insets) is wider
/// than 500 logical pixels — the split the tablet / web layouts branch on.
///
/// Nothing in the navigation suites read it, so the whole provider was dark.
/// The test drives `tester.view` instead of a widget: the provider needs no
/// element tree, only a configured view.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool readWithPadding(WidgetTester tester, double width, double left) {
    tester.view.physicalSize = ui.Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(left: left);
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container.read(isWebFormatProvider);
  }

  testWidgets('a wide view is the web format and a narrow one is not', (
    tester,
  ) async {
    expect(readWithPadding(tester, 900, 0), isTrue);
    // Exactly 500 is not "wider than 500".
    expect(readWithPadding(tester, 500, 0), isFalse);
    expect(readWithPadding(tester, 400, 0), isFalse);
  });

  testWidgets('the safe-width comparison takes the insets off the width', (
    tester,
  ) async {
    // 700 logical pixels wide, 250 of them behind the side insets: 450 left,
    // which is the phone layout even though the screen itself is wide.
    expect(readWithPadding(tester, 700, 250), isFalse);
  });
}
