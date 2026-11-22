import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';

import '../../shared/app_scaffold.dart';
import '../admin_fixtures.dart';

/// The main page's payment structures row, which navigates to `/admin/structures`.
///
/// One route per file: qlevar_router only processes the first mid-test
/// navigation of an isolate, so each route gets its own isolate to itself.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('the payment structures row opens /admin/structures', (
    tester,
  ) async {
    await pumpAdminMain(tester, scaffold);

    await tapAdminItem(tester, 3, '/admin/structures');

    expect(QR.currentPath, '/admin/structures');
    expect(tester.takeException(), isNull);
    await settle(tester, frames: 20);
    await scaffold.unmountApp(tester);
  });
}
