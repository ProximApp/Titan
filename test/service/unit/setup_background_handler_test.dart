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
/// whole point of a background isolate entry point), register for FCM (which
/// refreshes the token — the handler used to await `getToken()` and throw the
/// value away) and initialize the notification plugin, all of which are
/// platform calls: FirebasePlatform for initializeApp,
/// FirebaseMessagingPlatform for `register()`, the
/// flutter_local_notifications channel for the plugin.
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
      // The handler awaits init(), but the channel call itself is answered
      // asynchronously by the mock, so give it a frame.
      await tester.pump();

      expect(channelCalls.map((c) => c.method), contains('initialize'));
      // Exactly ONCE. The handler used to build a service for an awaited
      // init() and then a second one for an un-awaited init(), so the plugin
      // was configured twice per background message (and each constructor
      // subscribes its own click listener). `contains` would pass either
      // way — this count is the pin.
      expect(
        channelCalls.where((c) => c.method == 'initialize').length,
        1,
        reason: 'the background handler must initialize the plugin once',
      );
      // Exactly ONCE, and awaited: `register()` refreshes the token by
      // itself, so the handler no longer reads (and discards) getToken().
      expect(messaging.registerCalls, 1);
      expect(messaging.tokenCalls, 0);
    },
  );
}
