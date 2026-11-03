import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/event/notification_service.dart';
import 'package:titan/event/providers/confirmed_event_list_provider.dart';
import 'package:titan/event/providers/day_sorted_event_list_provider.dart';
import 'package:titan/event/providers/event_list_provider.dart';
import 'package:titan/event/providers/sorted_event_list_provider.dart';
import 'package:titan/event/providers/user_event_list_provider.dart';
import 'package:titan/event/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/home/router.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// The two grouping providers and the notification refresh map were the
/// event module's only 0%-covered non-UI files. They are pure derivations
/// over `confirmedEventListProvider`, so they are driven straight from the
/// notifier's state through the mocked repository — no widgets involved.
///
/// The fixture set is chosen to hit every branch of the bucketing logic:
/// a far event (plain new key), a near event (pre-existing key + the
/// insert-before branch when fed out of order), a DAILY recurrence that
/// expands to three occurrences, and an ended event the `end.isAfter(now)`
/// filter must drop.
void main() {
  late MockOpenapi mockRepository;
  late ProviderContainer container;

  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime onDay(int offset, {int hour = 0, int minute = 0}) =>
      DateTime(today.year, today.month, today.day + offset, hour, minute);

  EventCompleteTicketUrl fixture({
    required String id,
    required DateTime start,
    required DateTime end,
    String? recurrenceRule,
  }) => EventCompleteTicketUrl.empty().copyWith(
    id: id,
    name: id,
    start: start,
    end: end,
    recurrenceRule: recurrenceRule,
  );

  final later = fixture(
    id: 'later',
    start: onDay(5, hour: 9),
    end: onDay(5, hour: 11),
  );
  final soon = fixture(
    id: 'soon',
    start: onDay(2, hour: 10),
    end: onDay(2, hour: 12),
  );
  final weekly = fixture(
    id: 'weekly',
    start: onDay(1, hour: 8),
    end: onDay(1, hour: 9),
    recurrenceRule: 'FREQ=DAILY;COUNT=3',
  );
  final past = fixture(id: 'past', start: onDay(-10), end: onDay(-5));

  setUp(() {
    mockRepository = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() => container.dispose());

  /// Stubs the confirmed-events endpoint and performs one real load, so the
  /// derived providers observe `AsyncValue.data(events)` deterministically.
  Future<void> loadConfirmed(List<EventCompleteTicketUrl> events) async {
    when(() => mockRepository.calendarEventsConfirmedGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('[]', 200), events),
    );
    await container
        .read(confirmedEventListProvider.notifier)
        .loadConfirmedEvent();
  }

  group('sortedEventListProvider', () {
    test(
      'groups by delay label, expands recurrence, drops ended events',
      () async {
        await loadConfirmed([later, soon, weekly, past]);

        final map = container.read(sortedEventListProvider);

        // Labels come out date-ordered: tomorrow first, then +2, +3, +5 days.
        // The ended 'past' event never produces an "Aujourd'hui"-era key here.
        expect(map.keys.toList(), [
          'Demain',
          'Dans 2 jours',
          'Dans 3 jours',
          'Dans 5 jours',
        ]);
        // 1 later + 1 soon + 3 weekly occurrences = 5 entries; past excluded.
        expect(map.values.expand((events) => events).length, 5);
        expect(
          map.values.expand((events) => events).map((e) => e.id),
          isNot(contains('past')),
        );

        // 'Dans 2 jours' holds the weekly occurrence at 08:00 and 'soon' at
        // 10:00; weekly was fed LAST, so its occurrence took the
        // insert-before branch to land ahead of 'soon'.
        expect(map['Dans 2 jours']!.map((e) => e.name), ['weekly', 'soon']);

        // mergeDates keeps the original time-of-day on each occurrence.
        expect(map['Dans 3 jours']!.single.start, onDay(3, hour: 8));
        // The far event stands alone under its own label.
        expect(map['Dans 5 jours']!.single.name, 'later');
      },
    );

    test('a loading confirmed list yields an empty grouping', () {
      when(() => mockRepository.calendarEventsConfirmedGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('[]', 200),
          <EventCompleteTicketUrl>[],
        ),
      );
      container.read(confirmedEventListProvider.notifier).state =
          const AsyncValue.loading();

      expect(container.read(sortedEventListProvider), isEmpty);
    });
  });

  group('daySortedEventListProvider', () {
    test('keys are normalized occurrence dates in ascending order', () async {
      await loadConfirmed([later, soon, weekly, past]);

      final map = container.read(daySortedEventListProvider);

      expect(map.keys.toList(), [onDay(1), onDay(2), onDay(3), onDay(5)]);
      expect(map.values.expand((events) => events).length, 5);
      // Two events land on day +2: the existing-key insert-before branch
      // runs when the later-fed weekly occurrence jumps ahead of 'soon'.
      expect(map[onDay(2)]!.map((e) => e.name), ['weekly', 'soon']);
      expect(
        map.values.expand((events) => events).map((e) => e.id),
        isNot(contains('past')),
      );
    });

    test('a loading confirmed list yields an empty grouping', () {
      when(() => mockRepository.calendarEventsConfirmedGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('[]', 200),
          <EventCompleteTicketUrl>[],
        ),
      );
      container.read(confirmedEventListProvider.notifier).state =
          const AsyncValue.loading();

      expect(container.read(daySortedEventListProvider), isEmpty);
    });
  });

  group('eventProviders notification map', () {
    test('maps each notification topic to its route root and providers', () {
      expect(eventProviders.keys, ['userEvents', 'confirmedEvents', 'events']);

      expect(eventProviders['userEvents']!.item1, EventRouter.root);
      expect(eventProviders['userEvents']!.item2, [
        eventEventListProvider,
        confirmedEventListProvider,
      ]);

      expect(eventProviders['confirmedEvents']!.item1, HomeRouter.root);
      expect(eventProviders['confirmedEvents']!.item2, [
        confirmedEventListProvider,
      ]);

      expect(
        eventProviders['events']!.item1,
        EventRouter.root + EventRouter.admin,
      );
      expect(eventProviders['events']!.item2, [eventListProvider]);
    });
  });
}
