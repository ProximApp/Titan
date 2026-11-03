import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/event/providers/is_admin_provider.dart';
import 'package:titan/event/router.dart';
import 'package:titan/event/ui/pages/main_page/main_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/route_mock_stub.dart';

/// The admin button only exists for calendar admins, and its tap is the only
/// way into the admin page from the user main page. The existing main-page
/// tests run as a regular user, so the button and its handler never rendered.
void main() {
  late IntegrationScaffold scaffold;
  late RecordingRouteMock mock;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    mock = RecordingRouteMock();
    QR.settings.mockRoute = mock;
  });

  tearDown(() => QR.settings.mockRoute = null);

  testWidgets('an admin can open the admin page from the main page', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      userId: 'user-1',
      providerOverrides: [isEventAdminProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));

    await scaffold.pumpWidgetApp(
      tester,
      const EventMainPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 6);

    final button = find.byType(AdminButton);
    expect(button, findsOneWidget);
    await tester.tap(button);
    await settle(tester, frames: 4);

    expect(tester.takeException(), isNull);
    expect(find.byType(AdminButton), findsOneWidget);
  });

  testWidgets('a regular user sees no admin button', (tester) async {
    final container = scaffold.makeContainer(
      userId: 'user-1',
      providerOverrides: [isEventAdminProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));

    await scaffold.pumpWidgetApp(
      tester,
      const EventMainPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 6);

    expect(find.byType(AdminButton), findsNothing);
  });
}
