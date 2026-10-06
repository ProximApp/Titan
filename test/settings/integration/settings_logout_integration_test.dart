import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/service/class/firebase_toke_expiration.dart';
import 'package:titan/service/providers/firebase_token_expiration_provider.dart';

import '../../shared/app_scaffold.dart';

/// The REAL logout path from the settings page — the one that clears the
/// saved FCM token-expiration date.
///
/// `FirebaseTokenExpirationNotifier.reset()` had no test at all, and it is
/// not reachable from a provider unit test: both call sites are UI callbacks
/// that run after `await auth.deleteToken()`, behind an `if (!kIsWeb)` guard
/// (false in tests, so it does run). So the only honest way to cover it is to
/// drive the settings page's real "Log out" row and confirm the modal.
///
/// What it asserts, and why each part matters:
///  - the pref key is GONE after logout. This is the point of the method: the
///    date is a per-user cache, and leaving it behind would let the next
///    signed-in user inherit the previous one's 30-day window and never
///    register a token for themselves (`setup.dart` keys the cache on
///    `userId`, so a stale row would just cause a pointless re-register — but
///    only while the row survives, and `reset` is the thing that clears it).
///  - the in-memory state is EMPTY, not merely stale. `reset()` sets state
///    directly rather than re-reading prefs, so a test that only checked the
///    prefs would pass even if the state assignment were deleted.
///  - the session really ends: `deleteToken` runs and the router lands on
///    /login. Without that the "logout" could be a no-op that still clears the
///    cache, which is the reverse of the bug.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// `deleteToken` reaches `flutter_secure_storage`'s platform channel, which
  /// does not exist in a test env, and `CacheManager`, which does real IO.
  /// Both are stubbed so the auth side of logout is real but hermetic — the
  /// subject here is the token-expiration cache, not the storage backend.
  void stubTokenDeletion(WidgetTester tester) {
    final binding = tester.binding.defaultBinaryMessenger;
    final deletedSecureKeys = <String>[];
    binding.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'delete') {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          deletedSecureKeys.add(args['key'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => binding.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      ),
    );
  }

  testWidgets(
    'logging out from settings clears the saved FCM token expiration date',
    (tester) async {
      // The saved row a previous session would have written.
      SharedPreferences.setMockInitialValues({
        'firebaseTokenExpiration':
            '{"token":"user-1",'
            '"expiration":"2099-01-01T00:00:00.000"}',
      });
      stubTokenDeletion(tester);
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(
        () => scaffold.repository.notificationTopicsGet(),
      ).thenAnswer((_) async => chopperListResponse(<TopicUser>[]));

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
      );
      addTearDown(container.dispose);

      await scaffold.pumpApp(tester, container, initialPath: '/settings');
      await settle(tester, frames: 8);

      // The real notifier loaded the seeded row into its state.
      final notifier = container.read(firebaseTokenExpirationProvider.notifier);
      await notifier.ready;
      expect(
        container.read(firebaseTokenExpirationProvider).userId,
        'user-1',
        reason:
            'the seeded row must be in state before the test means anything',
      );

      // The logout row lives near the bottom of a long settings page.
      await scaffold.ensureOnScreen(tester, find.text('Log out'));
      await scaffold.openModal(tester, find.text('Log out'));

      expect(find.text('Do you really want to log out?'), findsOneWidget);
      await scaffold.tapInModal(tester, find.text('Confirm'));
      await settle(tester, frames: 10);

      // reset() really ran: the persisted row is gone...
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('firebaseTokenExpiration'),
        isNull,
        reason:
            'the per-user token cache must not outlive the session that wrote '
            'it; reset() is the only thing that clears it',
      );
      // ...and so is the in-memory copy, which is a separate assignment.
      expect(
        container.read(firebaseTokenExpirationProvider),
        isA<FirebaseTokenExpiration>()
            .having((e) => e.userId, 'userId', '')
            .having((e) => e.expiration, 'expiration', isNull),
      );
      // The session really ended, not just the cache.
      expect(find.text('Logged out successfully'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
