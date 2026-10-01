import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /booking/admin is bounced for a non admin', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No news available'), findsOneWidget);
  });
}
