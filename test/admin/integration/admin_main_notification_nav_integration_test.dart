import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';

import '../../shared/app_scaffold.dart';
import '../admin_fixtures.dart';

/// The main page's group notifications row, which navigates to `/admin/group_notification`.
///
/// One route per file: qlevar_router only processes the first mid-test
/// navigation of an isolate, so each route gets its own isolate to itself.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('the group notifications row opens /admin/group_notification', (
    tester,
  ) async {
    await pumpAdminMain(tester, scaffold);

    await tapAdminItem(tester, 2, '/admin/group_notification');

    expect(QR.currentPath, '/admin/group_notification');
    expect(tester.takeException(), isNull);
    await settle(tester, frames: 20);
    await scaffold.unmountApp(tester);
  });
}
