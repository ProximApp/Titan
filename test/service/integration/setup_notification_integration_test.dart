import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/navigation/providers/should_setup_provider.dart';

import '../../shared/app_scaffold.dart';

/// setUpNotification — the one piece of app boot the harness normally gates
/// shut. NavigationTemplate only calls it for a non-empty user while
/// shouldSetupProvider is true, and both Firebase providers hit platform
/// channels that do not exist in tests, so `makeContainer` pins that flag to
/// false for every other test in the suite. `runNotificationSetup: true`
/// reopens the gate; the test then owns the fakes itself:
/// FirebaseMessagingPlatform for requestPermission/getToken and
/// FirebasePlatform for Firebase.initializeApp (FirebaseMessaging.instance
/// resolves `Firebase.app()`, which throws without a default app).
///
/// FirebaseMessagingPlatform.onMessage is a *static* broadcast controller,
/// so a foreground push is delivered by adding to it directly — no fake
/// needed for the message path.
///
/// What this file proves (setup.dart's authorized branch):
///  - LocalNotificationService.init() reaches the plugin channel,
///  - the FCM token registration date is persisted under the signed-in id,
///  - getTopics() hits the notification endpoint,
///  - a foreground push rebuilds the Message from the data map and shows it,
///  - the gate closes itself so the setup runs once per launch.
///
/// The denied branch lives in its own file (a file may boot a deep link only
/// once — conventions 1 and 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() async {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // No platform registers the Android implementation in a test env, so
    // the plugin's show()/initialize() dispatch would silently resolve to
    // null without this (same reason as local_notification_service's file).
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    FirebasePlatform.instance = FakeFirebaseCore();
    await Firebase.initializeApp();
  });

  testWidgets(
    'the authorized branch registers the token, fetches topics, and shows a pushed notification',
    (tester) async {
      final channelCalls = stubLocalNotificationsChannel();
      stubFirebaseMessaging(AuthorizationStatus.authorized);
      when(
        () => scaffold.repository.notificationTopicsGet(),
      ).thenAnswer((_) async => chopperListResponse(<TopicUser>[]));

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        runNotificationSetup: true,
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed',
        pumpAndSettle: false,
      );
      // The gate opens from a Future(() {...}) in the shell's build, so the
      // event loop has to turn before requestPermission is even asked.
      await settle(tester, frames: 24);

      // The plugin was initialized by setUpNotification itself.
      expect(channelCalls.map((c) => c.method), contains('initialize'));
      // saveDate() wrote the token expiry under the signed-in user id.
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('firebaseTokenExpiration');
      expect(saved, isNotNull);
      expect(saved, contains('user-1'));
      final decoded = json.decode(saved!) as Map<String, dynamic>;
      final expiration = DateTime.parse(decoded['expiration'] as String);
      expect(expiration.difference(DateTime.now()).inDays, closeTo(30, 1));
      // The topics list really was fetched (the provider's own build() call
      // plus the explicit refresh after the token is saved).
      verify(() => scaffold.repository.notificationTopicsGet()).called(2);
      // ... and the flag flipped, so this only runs once per launch.
      expect(container.read(shouldSetupProvider), isFalse);

      // A foreground push: the handler maps message.data into a Message and
      // hands it to the local notification service.
      FirebaseMessagingPlatform.onMessage.add(
        RemoteMessage(
          messageId: 'm-1',
          data: {'action_module': 'mypayment', 'action_table': 'invoice'},
          notification: const RemoteNotification(
            title: 'Titre',
            body: 'Contenu',
          ),
        ),
      );
      await settle(tester, frames: 8);

      final show = channelCalls.singleWhere((c) => c.method == 'show');
      final args = show.arguments as Map<Object?, Object?>;
      expect(args['title'], 'Titre');
      expect(args['body'], 'Contenu');
      final payload =
          json.decode(args['payload'] as String) as Map<String, dynamic>;
      expect(payload['action_module'], 'mypayment');
      expect(payload['action_table'], 'invoice');
    },
  );
}
