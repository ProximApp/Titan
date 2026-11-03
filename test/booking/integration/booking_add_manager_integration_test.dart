import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/manager_provider.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const bookingAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /booking/admin/manager mounts the manager form pre-filled',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: bookingAdminGroupId,
              name: 'admin',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(() => scaffold.repository.groupsGet()).thenAnswer(
        (_) async => chopperListResponse([
          CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins'),
        ]),
      );
      // The form edits the client-side manager state set by the admin page.
      container
          .read(managerProvider.notifier)
          .setManager(
            Manager.empty().copyWith(
              id: 'mgr-1',
              name: 'Amphi',
              groupId: 'grp-1',
            ),
          );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.manager}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The edit header and the group chip row render.
      expect(find.text('Edit or delete a manager'), findsOneWidget);
      expect(find.text('Admins'), findsOneWidget);
    },
  );
}
