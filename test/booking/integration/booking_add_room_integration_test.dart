import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/room_provider.dart';
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
    'deep link to /booking/admin/room mounts the room form pre-filled',
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
      when(() => scaffold.repository.bookingManagersGet()).thenAnswer(
        (_) async => chopperListResponse([
          Manager.empty().copyWith(
            id: 'mgr-1',
            name: 'Amphi',
            groupId: 'grp-1',
          ),
        ]),
      );
      when(() => scaffold.repository.groupsGet()).thenAnswer(
        (_) async => chopperListResponse([
          CoreGroupSimple.empty().copyWith(id: 'grp-1', name: 'Admins'),
        ]),
      );
      // The form edits the client-side room state set by the admin page.
      container
          .read(roomProvider.notifier)
          .setRoom(
            RoomComplete.empty().copyWith(
              id: 'room-1',
              name: 'Amphi A',
              managerId: 'mgr-1',
            ),
          );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${BookingRouter.root}${BookingRouter.admin}${BookingRouter.room}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Pre-filled name (TextEntry renders TextEntry widgets, the text lives
      // in the controller) plus the manager chip row.
      expect(find.text('Amphi'), findsOneWidget);
    },
  );
}
