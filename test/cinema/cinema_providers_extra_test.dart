import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:titan/cinema/providers/is_cinema_admin.dart';
import 'package:titan/cinema/providers/main_page_index_provider.dart';
import 'package:titan/cinema/providers/session_list_provider.dart';
import 'package:titan/cinema/providers/session_provider.dart';
import 'package:titan/cinema/tools/functions.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/user/providers/user_provider.dart';

class FakeSessionListNotifier extends SessionListNotifier {
  FakeSessionListNotifier(this.sessions);
  final List<CineSessionComplete> sessions;

  @override
  AsyncValue<List<CineSessionComplete>> build() => AsyncValue.data(sessions);
}

class _LoadingSessionListNotifier extends SessionListNotifier {
  @override
  AsyncValue<List<CineSessionComplete>> build() =>
      const AsyncValue.loading();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cinema tools functions', () {
    test('formatDuration renders minutes, hours and mixed durations', () {
      expect(formatDuration(45), '45m');
      expect(formatDuration(120), '2h');
      expect(formatDuration(134), '2h 14min');
    });

    test('formatDate pads day, month, hour and minute', () {
      expect(
        formatDate(DateTime(2024, 3, 5, 7, 8)),
        '05/03/2024 - 07h08',
      );
    });

    test('parseDuration converts "HH:mm" to minutes and back', () {
      expect(parseDuration('02:14'), 134);
      expect(parseDurationBack(134), '02:14');
      expect(parseDurationBack(45), '00:45');
    });
  });

  group('getFromUrl', () {
    test('keeps small images untouched', () async {
      final bytes = Uint8List.fromList(List.filled(1024, 1));
      final client = http_testing.MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );

      final result = await http.runWithClient(
        () => getFromUrl('https://example.com/poster.jpg'),
        () => client,
      );

      // http copies the response buffer, so compare contents.
      expect(result, bytes);
    });

    test('keeps oversized non-images as they are when compression fails',
        () async {
      final bytes = Uint8List.fromList(List.filled(1500 * 1024, 0));
      final client = http_testing.MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );

      final result = await http.runWithClient(
        () => getFromUrl('https://example.com/poster.jpg'),
        () => client,
      );

      expect(result, bytes);
    });
  });

  group('MainPageIndexNotifier', () {
    test('starts on the first session in the future', () {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith(
            () => FakeSessionListNotifier([
              CineSessionComplete.empty().copyWith(
                id: 'past',
                start: now.subtract(const Duration(days: 2)),
              ),
              CineSessionComplete.empty().copyWith(
                id: 'future',
                start: now.add(const Duration(days: 2)),
              ),
            ]),
          ),
        ],
      );

      expect(container.read(mainPageIndexProvider), 1);

      container.dispose();
    });

    test('returns 0 when there is no session', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith(
            () => FakeSessionListNotifier(const []),
          ),
        ],
      );

      expect(container.read(mainPageIndexProvider), 0);

      container.dispose();
    });

    test('returns 0 while sessions are loading', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith(_LoadingSessionListNotifier.new),
        ],
      );

      expect(container.read(mainPageIndexProvider), 0);

      container.dispose();
    });

    test('setMainPageIndex, setStartPage and reset', () {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith(
            () => FakeSessionListNotifier([
              CineSessionComplete.empty().copyWith(
                id: 'future',
                start: now.add(const Duration(days: 2)),
              ),
            ]),
          ),
        ],
      );

      final notifier = container.read(mainPageIndexProvider.notifier);
      expect(container.read(mainPageIndexProvider), 0);

      notifier.setMainPageIndex(3);
      expect(container.read(mainPageIndexProvider), 3);

      notifier.setStartPage(2);
      notifier.reset();
      expect(container.read(mainPageIndexProvider), 2);

      container.dispose();
    });
  });

  group('SessionNotifier', () {
    test('starts with an empty session and can set one', () {
      final container = ProviderContainer();

      expect(container.read(sessionProvider), CineSessionComplete.empty());

      final session = CineSessionComplete.empty().copyWith(id: 's-1');
      container.read(sessionProvider.notifier).setSession(session);
      expect(container.read(sessionProvider), session);

      container.dispose();
    });
  });

  group('isCinemaAdminProvider', () {
    test('is true when the user is in the cinema admin group', () {
      final user = CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: 'ce5f36e6-5377-489f-9696-de70e2477300',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(user)],
      );

      expect(container.read(isCinemaAdminProvider), isTrue);

      container.dispose();
    });

    test('is false for a regular user', () {
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(CoreUser.empty())],
      );

      expect(container.read(isCinemaAdminProvider), isFalse);

      container.dispose();
    });
  });
}
