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

/// The denied half of setUpNotification, in its own file: a file may boot a
/// deep link exactly once (conventions 1 and 10), and this journey needs its
/// own boot with `requestPermission` answering `denied`.
///
/// A refusal must be inert: the plugin is still initialized (that happens
/// before the prompt), but no token date is written, no topic is REFRESHED,
/// and the shell's flag still flips so the setup is not retried on the next
/// build.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() async {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    FirebasePlatform.instance = FakeFirebaseCore();
    await Firebase.initializeApp();
  });

  testWidgets('a denied permission writes no token date and fetches no topic', (
    tester,
  ) async {
    final channelCalls = stubLocalNotificationsChannel();
    stubFirebaseMessaging(AuthorizationStatus.denied);
    var topicCalls = 0;
    when(() => scaffold.repository.notificationTopicsGet()).thenAnswer((
      _,
    ) async {
      // A counter rather than verifyNever: the feed boot itself calls other
      // repository methods, and mocktail's verifyNever reports every one of
      // them as unexpected.
      topicCalls++;
      return chopperListResponse(<TopicUser>[]);
    });

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
    await settle(tester, frames: 24);

    // init() runs before the prompt, so the plugin IS initialized.
    expect(channelCalls.map((c) => c.method), contains('initialize'));
    // ... but nothing past the authorization check ran: no token date, and
    // no topic REFRESH. One call still lands because setUpNotification
    // watches topicsProvider.notifier unconditionally, and that notifier's
    // build() calls getTopics() itself (the authorized file sees two).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('firebaseTokenExpiration'), isNull);
    expect(topicCalls, 1);
    // The gate still closes: the user is not re-prompted on every build.
    expect(container.read(shouldSetupProvider), isFalse);
  });
}
