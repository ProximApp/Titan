import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/ui/pages/group_notifification_page/group_notification_page.dart';
import 'package:titan/tools/ui/styleguide/button.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';
import 'package:titan/tools/ui/styleguide/text_entry.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // Stubbed for the admin main page mounted underneath the sub-page.
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <Structure>[]),
    );
    when(() => scaffold.repository.associationsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <Association>[]),
    );
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <MembershipSimple>[]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(
          id: 'g-2',
          name: 'beta',
          description: 'Second group',
        ),
        CoreGroupSimple.empty().copyWith(
          id: 'g-1',
          name: 'Alpha',
          description: 'First group',
        ),
      ]),
    );
  });

  // Deep link to the group notification sub-page. qlevar_router 1.12.4 only
  // processes the init-path middleware chain on the first navigation of the
  // isolate, so every sub-page shell lives in its own file with a single
  // deep-link test (see the purchases test NOTE).
  testWidgets('group notifications renders a sorted group list', (
    tester,
  ) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/admin/group_notification',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/group_notification');
    expect(find.byType(GroupNotificationPage), findsOneWidget);
    expect(find.text('Group notifications'), findsWidgets);
    expect(find.text('First group'), findsOneWidget);
    expect(find.text('Second group'), findsOneWidget);
    final titles = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .toList();
    expect(titles.indexOf('Alpha'), lessThan(titles.indexOf('beta')));
    await scaffold.unmountApp(tester);
  });

  testWidgets('sending a group notification submits its chosen payload', (
    tester,
  ) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/admin/group_notification',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);

    await tester.tap(find.byType(ListItem).first);
    await settle(tester, frames: 10);
    expect(find.text('Send a notification'), findsOneWidget);
    final fields = find.byType(TextEntry);
    expect(fields, findsNWidgets(2));
    await tester.enterText(
      find.descendant(of: fields.at(0), matching: find.byType(TextField)),
      'Schedule change',
    );
    await tester.enterText(
      find.descendant(of: fields.at(1), matching: find.byType(TextField)),
      'The meeting starts at 18:00.',
    );

    when(
      () => scaffold.repository.notificationSendPost(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
    await tester.tap(find.byType(Button));
    await settle(tester, frames: 18);

    final request =
        verify(
              () => scaffold.repository.notificationSendPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as GroupNotificationRequest;
    expect(request.groupId, 'g-1');
    expect(request.title, 'Schedule change');
    expect(request.content, 'The meeting starts at 18:00.');
    expect(find.text('Notification sent'), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });

  testWidgets('failed group notification shows the error toast', (
    tester,
  ) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/admin/group_notification',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
    await tester.tap(find.byType(ListItem).first);
    await settle(tester, frames: 10);

    when(
      () => scaffold.repository.notificationSendPost(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.fail<void>(500));
    await tester.tap(find.byType(Button));
    await settle(tester, frames: 16);

    expect(find.text('Failed to send notification'), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });
}
