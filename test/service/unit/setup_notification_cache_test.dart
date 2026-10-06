import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/service/providers/firebase_token_expiration_provider.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/service/tools/setup.dart';

import '../../shared/app_scaffold.dart';

/// setUpNotification's token-cache branch — the two lines nothing reached
/// (ledger #35), and the reason nothing could.
///
/// The integration shell overrides `firebaseTokenExpirationProvider` with
/// `FakeFirebaseTokenExpirationNotifier`, which returns the fixed userId
/// `'me'` with a date 30 days out. Every test user has a real id, so
/// `firebaseTokenExpiration.userId != user.id` was ALWAYS true and the `||`
/// chain short-circuited before lines 33-34. Nothing about the condition was
/// untestable; it was unreachable through the shell.
///
/// So this file drives the REAL notifier: phase one creates the provider and
/// lets its persisted date land, phase two calls setUpNotification from a real
/// WidgetRef (the way NavigationTemplate does, without booting the router —
/// conventions 1 and 10).
///
/// What it pins:
///  - a valid 30-day cache is HONOURED: no saveDate, no extra topics refresh,
///  - an expired date re-registers (line 34's job),
///  - a null expiration re-registers instead of throwing
///    "Null check operator used on a null value" on `expiration!`,
///  - a row poisoned with the literal string "null" - which the old
///    `toJson` wrote for a null expiration - recovers instead of killing the
///    launch (ledger #54),
///  - `ready` exists because build() cannot await its own prefs read: without
///    it the check saw the empty default and re-registered every launch.
class ReadsExpiration extends ConsumerWidget {
  const ReadsExpiration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(firebaseTokenExpirationProvider);
    return const SizedBox.shrink();
  }
}

class CallsSetUpNotification extends ConsumerWidget {
  const CallsSetUpNotification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    setUpNotification(ref);
    return const SizedBox.shrink();
  }
}

void main() {
  late IntegrationScaffold scaffold;
  late int topicsCalls;
  late CapturingLoggerOutput logs;

  setUp(() async {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The container wires loggerProvider through _StubLogger when an output is
    // stubbed, so the captured lines are the ones that survived the logger's
    // level threshold.
    logs = CapturingLoggerOutput();
    scaffold.stubLoggerOutput(logs);
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    stubLocalNotificationsChannel();
    FirebasePlatform.instance = FakeFirebaseCore();
    await Firebase.initializeApp();
    stubFirebaseMessaging(AuthorizationStatus.authorized);
    topicsCalls = 0;
    when(() => scaffold.repository.notificationTopicsGet()).thenAnswer((
      _,
    ) async {
      topicsCalls++;
      return chopperListResponse(<TopicUser>[]);
    });
  });

  /// Seeds the persisted date, lets the real notifier load it, then runs
  /// setUpNotification.
  Future<void> runWithCachedDate(
    WidgetTester tester, {
    required String userId,
    required DateTime? expiration,
    bool preLoad = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'firebaseTokenExpiration': json.encode({
        'token': userId,
        'expiration': expiration?.toString(),
      }),
    });
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);

    // preLoad mimics a test that already touched the provider. The production
    // boot does NOT: NavigationTemplate calls setUpNotification on the first
    // build, so the provider is created and read inside the same call — that
    // is the case `notifier.ready` exists for.
    if (preLoad) {
      await scaffold.pumpWidgetApp(tester, const ReadsExpiration(), container);
      await settle(tester, frames: 4);
      expect(
        container.read(firebaseTokenExpirationProvider).userId,
        userId,
        reason: 'the seeded date must have loaded before the setup runs',
      );
    }

    await scaffold.pumpWidgetApp(
      tester,
      const CallsSetUpNotification(),
      container,
    );
    await settle(tester, frames: 12);
  }

  Future<String> savedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebaseTokenExpiration')!;
  }

  testWidgets('a valid 30-day cache is honoured: no re-registration', (
    tester,
  ) async {
    final cached = DateTime.now().add(const Duration(days: 10));
    await runWithCachedDate(tester, userId: 'user-1', expiration: cached);

    // Untouched: saveDate() would have rewritten it to now + 30 days, which is
    // exactly what the inverted condition did on every single launch.
    expect(await savedDate(), contains(cached.toString()));
    // topicsProvider's own build() is the only refresh; the explicit
    // getTopics() after the save did not happen.
    expect(topicsCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an expired date re-registers the token', (tester) async {
    await runWithCachedDate(
      tester,
      userId: 'user-1',
      expiration: DateTime.now().subtract(const Duration(days: 1)),
    );

    final decoded = json.decode(await savedDate()) as Map<String, dynamic>;
    final expiration = DateTime.parse(decoded['expiration'] as String);
    expect(expiration.difference(DateTime.now()).inDays, closeTo(30, 1));
    expect(topicsCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the registration line survives the logger threshold', (
    tester,
  ) async {
    // This is the app's only `logger.info` call, and the logger's floor used
    // to be LogLevel.warning — so the line was accepted and dropped, and the
    // registration left no trace anywhere.
    await runWithCachedDate(
      tester,
      userId: 'user-1',
      expiration: DateTime.now().subtract(const Duration(days: 1)),
    );

    expect(
      logs.logs.where(
        (l) => l.message == 'Firebase messaging token registered',
      ),
      hasLength(1),
    );
    expect(
      logs.logs
          .firstWhere((l) => l.message == 'Firebase messaging token registered')
          .level,
      LogLevel.info,
    );
  });

  testWidgets('a null expiration re-registers instead of crashing', (
    tester,
  ) async {
    // The third `||` operand dereferences the very field it just tested, so
    // this state used to throw "Null check operator used on a null value" out
    // of a launch.
    await runWithCachedDate(tester, userId: 'user-1', expiration: null);

    expect(tester.takeException(), isNull);
    final decoded = json.decode(await savedDate()) as Map<String, dynamic>;
    final expiration = DateTime.parse(decoded['expiration'] as String);
    expect(expiration.difference(DateTime.now()).inDays, closeTo(30, 1));
    expect(topicsCalls, 2);
  });

  testWidgets('a row poisoned with the string "null" recovers on launch', (
    tester,
  ) async {
    // ledger #54. `FirebaseTokenExpiration.toJson` used `expiration.toString()`,
    // and `toString()` on a null is the STRING "null" - so the row was written
    // with a value its own reader could not parse. `getSavedDate` then threw a
    // FormatException inside `notifier.ready`, which `setUpNotification`
    // awaits inside the `requestPermission().then` callback: the authorized
    // branch died before it registered anything.
    //
    // Note the difference from the test above: that one seeds a real JSON null
    // (`expiration?.toString()` in the helper is null-aware, so it encodes to
    // `null`), which the old reader handled fine. The poisoned row needs the
    // literal four characters.
    SharedPreferences.setMockInitialValues({
      'firebaseTokenExpiration': json.encode({
        'token': 'user-1',
        'expiration': 'null',
      }),
    });
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const CallsSetUpNotification(),
      container,
    );
    await settle(tester, frames: 12);

    // The launch survived, which is the whole point: no exception escaped the
    // notifier's async prefs read.
    expect(tester.takeException(), isNull);
    // An unreadable date means "no date", so the token re-registers - the same
    // branch a genuine null takes, not a skipped setup.
    expect(topicsCalls, 2);
    // ... and the poisoned row was replaced with a real one, so this is a
    // one-time recovery rather than a crash on every launch.
    final decoded = json.decode(await savedDate()) as Map<String, dynamic>;
    final expiration = DateTime.parse(decoded['expiration'] as String);
    expect(expiration.difference(DateTime.now()).inDays, closeTo(30, 1));
  });

  testWidgets('a cold boot still honours the cache (the ready await)', (
    tester,
  ) async {
    // No pre-load: the provider is created by setUpNotification's own read, so
    // the state it checks is the empty default unless the notifier's
    // asynchronous prefs read is awaited first. Without that await every
    // launch looked like a first launch and re-registered the token.
    final cached = DateTime.now().add(const Duration(days: 10));
    await runWithCachedDate(
      tester,
      userId: 'user-1',
      expiration: cached,
      preLoad: false,
    );

    expect(await savedDate(), contains(cached.toString()));
    expect(topicsCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('another user\'s cache is never reused', (tester) async {
    await runWithCachedDate(
      tester,
      userId: 'somebody-else',
      expiration: DateTime.now().add(const Duration(days: 10)),
    );

    // A live date under another id still registers this user.
    final decoded = json.decode(await savedDate()) as Map<String, dynamic>;
    expect(decoded['token'], 'user-1');
    expect(topicsCalls, 2);
  });
}
