import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/file_download.dart';

import '../../shared/app_scaffold.dart';

/// `shareOriginOf` is the only part of file_download.dart that is testable
/// on the host: `downloadFile`'s own branches all hand bytes to platform
/// plugins (share_plus on iOS, file_saver elsewhere) that have no test
/// binding, while the rect reader needs only a widget tree.
void main() {
  testWidgets('reads the laid-out rect, and nothing before layout', (
    tester,
  ) async {
    // During a first build the element's subtree does not exist yet, so
    // findRenderObject comes back null — the guard's null arm, which is
    // what lets a caller fall back to centering the share sheet.
    Rect? duringBuild;
    late BuildContext live;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          duringBuild ??= shareOriginOf(context);
          live = context;
          return const SizedBox(width: 40, height: 20);
        },
      ),
    );
    expect(duringBuild, isNull);

    // After layout the same context reports the widget's rect.
    final rect = shareOriginOf(live);
    expect(rect, isNotNull);
    expect(rect!.size, const Size(40, 20));
  });
}
