import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /ph renders the empty-database message and nav buttons',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      when(
        () => scaffold.repository.phGet(),
      ).thenAnswer((_) async => chopperListResponse(<PaperComplete>[]));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: PhRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.text('No PH yet in database'), findsOneWidget);
      expect(find.text('See previous journals'), findsOneWidget);
      // A plain user gets no admin button.
      expect(find.byType(AdminButton), findsNothing);
    },
  );
}
