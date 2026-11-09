import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';

import '../../shared/app_scaffold.dart';
import '../admin_fixtures.dart';

/// The main page's association memberships row, which navigates to `/admin/association_memberships`.
///
/// One route per file: qlevar_router only processes the first mid-test
/// navigation of an isolate, so each route gets its own isolate to itself.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets(
    'the association memberships row opens /admin/association_memberships',
    (tester) async {
      await pumpAdminMain(tester, scaffold);

      await tapAdminItem(tester, 4, '/admin/association_memberships');

      expect(QR.currentPath, '/admin/association_memberships');
      expect(tester.takeException(), isNull);
      await settle(tester, frames: 20);
      await scaffold.unmountApp(tester);
    },
  );
}
