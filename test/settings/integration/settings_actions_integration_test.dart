import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/router.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';

import '../../shared/app_scaffold.dart';

/// The settings main page rows that no other settings test drives: the
/// change-password launcher, the English half of the language sheet, the
/// account-deletion confirmation (both endpoint answers) and the
/// non-web-only logs navigation.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubProfilePicture();
    when(() => scaffold.repository.notificationTopicsGet())
        .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));
  });

  testWidgets('the change-password row opens the calypsso page', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    final fake = FakeUrlLauncher();
    stubUrlLauncher(fake);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await tester.tap(find.text('Change password'));
    await settle(tester, frames: 4);

    expect(fake.launched, hasLength(1));
    expect(fake.launched.single, endsWith('calypsso/change-password'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the language sheet switches the app locale to English', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Language'));
    expect(find.text('🇬🇧 English'), findsOneWidget);

    await scaffold.tapInModal(tester, find.text('🇬🇧 English'));
    await settle(tester, frames: 10);

    expect(scaffold.isModalOpen(tester), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en');

    // Reopen the sheet now that the locale is English: the French row
    // renders its unchecked Container() trailing (the branch the default
    // French locale never takes) and English gets the check.
    await scaffold.openModal(tester, find.text('Language'));
    expect(find.text('🇫🇷 Français'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('🇫🇷 Français'),
          matching: find.byType(ListItemTemplate),
        ),
        matching: find.byType(HeroIcon),
      ),
      findsNothing,
    );
    await scaffold.closeModal(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the delete-account confirmation sends the deletion request', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.usersMeAskDeletionPost())
        .thenAnswer((_) async => chopperResponseVoid());

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(email: 'me@myemapp.com'),
        seedAsyncUser: true,
      ),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Delete my account'));
    expect(
      find.text(
        'This action will send a request to the administrator to delete your '
        'account.',
      ),
      findsOneWidget,
    );
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 10);

    verify(() => scaffold.repository.usersMeAskDeletionPost()).called(1);
    expect(
      find.text(
        'Your account deletion request has been sent to the administrator.',
      ),
      findsOneWidget,
    );
    // Drain the toast auto-close timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing deletion request toasts the error message', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.usersMeAskDeletionPost()).thenAnswer(
      (_) async => chopper.Response(http.Response('boom', 500), null),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(email: 'me@myemapp.com'),
        seedAsyncUser: true,
      ),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Delete my account'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 10);

    verify(() => scaffold.repository.usersMeAskDeletionPost()).called(1);
    expect(find.text('Error sending account deletion request'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing profile save toasts the failure message', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    when(() => scaffold.repository.notificationTopicsGet())
        .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));
    // updateMe's false arm: the patch answers a non-successful response.
    when(() => scaffold.repository.usersMePatch(body: any(named: 'body')))
        .thenAnswer((_) async => scaffold.repository.fail(500));

    final me = CoreUser.empty().copyWith(
      email: 'me@myemapp.com',
      phone: '0699887766',
      birthday: DateTime(2004, 3, 15),
    );
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: me, seedAsyncUser: true),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Profile'));
    await tester.enterText(find.byType(TextField).at(1), '0601020304');
    await settle(tester, frames: 4);
    await tester.dragUntilVisible(
      find.text('Confirm'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);

    verify(() => scaffold.repository.usersMePatch(body: any(named: 'body')))
        .called(1);
    expect(find.text('Failed to edit account'), findsOneWidget);
    // The sheet stays open on failure.
    expect(scaffold.isModalOpen(tester), isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the logs row navigates to the log page', (tester) async {
    scaffold.setWideSurface(tester);
    final mock = _RecordingRouteMock();

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);
    expect(find.text('Logs'), findsOneWidget);

    // Install the mock only after the initial route resolved: qlevar's
    // hook intercepts EVERY match, so setting it pre-pump would replace
    // the settings page itself with the mock's throwaway route.
    QR.settings.mockRoute = mock;
    addTearDown(() => QR.settings.mockRoute = null);

    await tester.tap(find.text('Logs'));
    await settle(tester, frames: 4);

    expect(mock.navigated, contains(SettingsRouter.root + SettingsRouter.logs));
    expect(tester.takeException(), isNull);
  });
}

/// qlevar's test hook: with `QR.settings.mockRoute` set, every QR.to
/// resolves against this mock instead of a real navigator.
class _RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox());
  }
}
