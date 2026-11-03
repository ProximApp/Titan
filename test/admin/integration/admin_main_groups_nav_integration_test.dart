import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';

import '../../shared/app_scaffold.dart';
import '../admin_fixtures.dart';

/// The main page's groups management row, which navigates to `/admin/users_groups`.
///
/// One route per file: qlevar_router only processes the first mid-test
/// navigation of an isolate, so each route gets its own isolate to itself.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('the groups management row opens /admin/users_groups', (
    tester,
  ) async {
    await pumpAdminMain(tester, scaffold);

    await tapAdminItem(tester, 1, '/admin/users_groups');

    expect(QR.currentPath, '/admin/users_groups');
    expect(tester.takeException(), isNull);
    await settle(tester, frames: 20);
    await scaffold.unmountApp(tester);
  });
}
