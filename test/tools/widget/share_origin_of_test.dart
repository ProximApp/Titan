import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/file_download.dart';

/// `shareOriginOf` decides where an iPad share sheet points. Both of its arms
/// were uncovered: the null one is the interesting half, because every caller
/// passes a `BuildContext` it has held across an `await` — a context whose box
/// is gone must answer null (the sheet then centres itself) instead of
/// dereferencing a detached render object.
void main() {
  testWidgets('a context with no render box yet has no origin', (tester) async {
    Rect? duringBuild;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 100,
          height: 50,
          child: Builder(
            builder: (context) {
              // Build runs before layout: the element has no box to measure.
              duringBuild = shareOriginOf(context);
              return const ColoredBox(color: Color(0xFF000000));
            },
          ),
        ),
      ),
    );

    expect(
      duringBuild,
      isNull,
      reason: 'a box that is not laid out cannot anchor a popover',
    );
  });

  testWidgets('a laid-out context yields its box in global coordinates', (
    tester,
  ) async {
    Rect? afterLayout;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 50,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => afterLayout = shareOriginOf(context),
                );
                return const ColoredBox(color: Color(0xFF000000));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(afterLayout, isNotNull);
    expect(afterLayout!.width, 100);
    expect(afterLayout!.height, 50);
    // 800x600 test surface, centred: the origin is the box's real position,
    // not the widget's own local zero.
    expect(afterLayout!.left, closeTo((800 - 100) / 2, 0.5));
    expect(afterLayout!.top, closeTo((600 - 50) / 2, 0.5));
  });
}
