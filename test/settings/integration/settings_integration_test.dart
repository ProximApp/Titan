import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/router.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /settings renders the profile sections and notification counter',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(() => scaffold.repository.notificationTopicsGet()).thenAnswer(
        (_) async => chopperListResponse([
          TopicUser.empty().copyWith(
            id: 't-1',
            name: 'Booking reminders',
            moduleRoot: '/booking',
            isUserSubscribed: true,
          ),
          TopicUser.empty().copyWith(
            id: 't-2',
            name: 'AMAP newsletters',
            moduleRoot: '/amap',
            isUserSubscribed: false,
          ),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      // Account section with the profile entries.
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      // The subtitle counts subscribed vs total topics from the real
      // notificationTopicsGet response (ICU plural: 1 is singular).
      expect(find.text('1/2 active notification'), findsOneWidget);
      // Event section: the ical copy row.
      expect(find.text('Ical link'), findsOneWidget);
      expect(find.text('Sync with calendar'), findsOneWidget);
      // The profile picture fetch 404s into the placeholder asset.
      expect(
        find.byWidgetPredicate(
          (w) => w is CircleAvatar && w.backgroundImage is AssetImage,
        ),
        findsOneWidget,
      );
      // The module metadata closures resolve against this page's
      // localization scope (router.dart's getName/getDescription).
      final ctx = tester.element(find.text('Account'));
      expect(SettingsRouter.module.getName(ctx), 'Settings');
      expect(SettingsRouter.module.getDescription(ctx), 'Manage your settings');
    },
  );

  testWidgets('a failing topics fetch degrades the counter to zero and the '
      'profile fetch error to the placeholder hero', (tester) async {
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.notificationTopicsGet())
        .thenThrow(Exception('backend down'));
    // A throwing picture fetch lands the provider in AsyncError, which is
    // the avatar errorBuilder's only entry (the 404 stub resolves as
    // empty DATA instead).
    when(
      () => scaffold.repository.usersUserIdProfilePictureGet(
        userId: any(named: 'userId'),
      ),
    ).thenThrow(Exception('no picture'));

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    // The error arm of the counter's when() → 0/0 (ICU zero form).
    expect(find.text('0/0 active notification'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.userCircle && w.size == 140,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the notifications sheet groups every topic when none stands alone',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(() => scaffold.repository.notificationTopicsGet()).thenAnswer(
        (_) async => chopperListResponse([
          TopicUser.empty().copyWith(
            id: 't-1',
            name: 'Booking reminders',
            moduleRoot: '/booking',
            isUserSubscribed: true,
          ),
          TopicUser.empty().copyWith(
            id: 't-2',
            name: 'Booking news',
            moduleRoot: '/booking',
            isUserSubscribed: false,
          ),
          TopicUser.empty().copyWith(
            id: 't-3',
            name: 'Cinema alerts',
            moduleRoot: '/cinema',
            isUserSubscribed: true,
          ),
          TopicUser.empty().copyWith(
            id: 't-4',
            name: 'Cinema digests',
            moduleRoot: '/cinema',
            isUserSubscribed: false,
          ),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      await scaffold.openModal(tester, find.text('Notifications'));
      // Two paired modules → two group headers, and the 'others' pool is
      // absent (the `?? []` fallback in main_page).
      expect(find.text('/booking'), findsOneWidget);
      expect(find.text('/cinema'), findsOneWidget);
      expect(find.text('Booking reminders'), findsOneWidget);
      expect(find.text('Cinema digests'), findsOneWidget);

      await scaffold.closeModal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pull to refresh reloads the notification topics', (
    tester,
  ) async {
    scaffold.stubProfilePicture();
    var calls = 0;
    when(() => scaffold.repository.notificationTopicsGet())
        .thenAnswer((_) async {
          calls++;
          return chopperListResponse(<TopicUser>[]);
        });

    // Default surface: the profile + four sections + version block overflow
    // it, which is what arms the Cupertino refresh control.
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);
    expect(calls, 1);

    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(calls, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the language picker modal switches the app locale to French', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    when(() => scaffold.repository.notificationTopicsGet())
        .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    // Open the language sheet through the real ListItem.
    await scaffold.openModal(tester, find.text('Language'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Choose a language'), findsOneWidget);
    expect(find.text('🇫🇷 Français'), findsOneWidget);
    expect(find.text('🇬🇧 English'), findsOneWidget);

    // Pick French: the sheet self-closes and the locale persists to
    // SharedPreferences (the MaterialApp.locale re-render is owned by
    // main.dart, outside the pumpApp scope — verified via prefs below).
    await scaffold.tapInModal(tester, find.text('🇫🇷 Français'));
    await settle(tester, frames: 10);

    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('🇬🇧 English'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'fr');
  });

  testWidgets(
    'the ical row copies the calendar link to the clipboard and toasts',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      scaffold.stubClipboard(tester);
      when(() => scaffold.repository.notificationTopicsGet())
          .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      await tester.tap(find.text('Ical link'));
      await settle(tester, frames: 4);

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      expect(data?.text, contains('calendar/ical'));
      // Success toast confirms the copy path ran.
      expect(find.text('Ical link copied!'), findsOneWidget);
      // Drain the toast auto-close timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
