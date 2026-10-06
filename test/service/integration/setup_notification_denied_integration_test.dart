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
import 'package:titan/service/providers/topic_provider.dart';

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
      // The notification setup runs from the shell on whatever page is
      // mounted; /feed is just the cheapest host for it.
      allowedModules: const {'feed'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    // init() runs before the prompt, so the plugin IS initialized.
    expect(channelCalls.map((c) => c.method), contains('initialize'));
    // ... but nothing past the authorization check ran: no token date.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('firebaseTokenExpiration'), isNull);
    // The gate still closes: the user is not re-prompted on every build.
    expect(container.read(shouldSetupProvider), isFalse);

    // Ledger #36's regression assertion. This was `1`, and the reason was
    // that `setUpNotification` read `topicsProvider.notifier` before the
    // prompt answered; reading a notifier instantiates it, and
    // `TopicsProvider.build()` fetches the list itself. A user who has just
    // denied notifications cannot subscribe to a single topic, so the request
    // was pure waste on every launch - and it fired even on the very first
    // frame, while the permission dialog was still open. Zero is the correct
    // count, and the authorized file still sees two (its build call plus the
    // explicit refresh after the token is saved).
    expect(
      topicCalls,
      0,
      reason:
          'a denied launch must not hit notificationTopicsGet at all; if this '
          'fails, something reads topicsProvider before the authorization '
          'answer arrives',
    );
    // And the notifier is genuinely never instantiated, which is what makes
    // the zero above honest rather than a race that happened to resolve.
    expect(
      container.exists(topicsProvider),
      isFalse,
      reason: 'reading the notifier is what triggers the fetch',
    );
  });
}
