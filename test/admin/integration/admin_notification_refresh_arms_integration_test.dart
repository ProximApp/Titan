import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';

import '../../shared/app_scaffold.dart';
import '../admin_fixtures.dart';

/// The notification page's two uncovered arms: its pull-to-refresh (which
/// reloads the group list) and the send that blows up, whose `.catchError`
/// toasts the raw error instead of reporting a refusal.
final bdeGroup = CoreGroupSimple.empty().copyWith(
  id: 'g-1',
  name: 'BDE',
  description: 'Bureau des eleves',
);

void main() {
  late IntegrationScaffold scaffold;
  var groupsRequests = 0;

  setUp(() {
    scaffold = IntegrationScaffold();
    groupsRequests = 0;
  });

  Future<void> pumpNotifications(WidgetTester tester) async {
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.groupsGet()).thenAnswer((_) async {
      groupsRequests++;
      return chopperListResponse([bdeGroup]);
    });
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/admin/group_notification',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(find.text('BDE'), findsOneWidget);
  }

  testWidgets('pulling the notification list reloads the groups', (
    tester,
  ) async {
    await pumpNotifications(tester);
    final before = groupsRequests;

    final refresher = tester.widget<Refresher>(find.byType(Refresher));
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 12);

    expect(groupsRequests, greaterThan(before));
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });

  testWidgets('a send that throws toasts the raw error', (tester) async {
    await pumpNotifications(tester);
    when(
      () => scaffold.repository.notificationSendPost(body: any(named: 'body')),
    ).thenThrow(Exception('boom'));

    await tester.tap(find.byType(ListItem).first);
    await settle(tester, frames: 16);
    await tester.tap(find.text('Send'));
    await settle(tester, frames: 20);

    expect(
      anyVisibleTextContains(tester, 'boom'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });
}
