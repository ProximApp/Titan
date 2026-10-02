import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/service/tools/setup.dart';

import '../../shared/app_scaffold.dart';

/// `firebaseMessagingBackgroundHandler` is registered from main() — the one
/// caller no test can reach — but it is a plain top-level function, so it is
/// called directly here. It has to bootstrap Firebase itself (that is the
/// whole point of a background isolate entry point), refresh the FCM token
/// and initialize the notification plugin, all of which are platform calls:
/// FirebasePlatform for initializeApp, FirebaseMessagingPlatform for
/// getToken, the flutter_local_notifications channel for the plugin.
void main() {
  testWidgets(
    'the background handler boots Firebase, refreshes the token and initializes the plugin',
    (tester) async {
      final channelCalls = stubLocalNotificationsChannel();
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      FirebasePlatform.instance = FakeFirebaseCore();
      final messaging = stubFirebaseMessaging(AuthorizationStatus.authorized);

      await firebaseMessagingBackgroundHandler(
        const RemoteMessage(messageId: 'bg-1'),
      );
      // Let the plugin's fire-and-forget initialize land.
      await tester.pump();

      expect(channelCalls.map((c) => c.method), contains('initialize'));
      expect(messaging.tokenCalls, greaterThanOrEqualTo(1));
      // The handler is fire-and-forget on the token: it awaits getToken() but
      // never uses the value, so nothing else has to answer.
    },
  );
}
