import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/event/providers/confirmed_event_list_provider.dart';
import 'package:titan/event/providers/day_sorted_event_list_provider.dart';
import 'package:titan/event/providers/sorted_event_list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// Two events on the SAME day, fed newest-first: the second one has to be
/// APPENDED to the bucket that already exists. The grouping test only ever
/// fed a value that needed the insert-before branch, so the append arms of
/// both grouping providers never ran.
void main() {
  late MockOpenapi mockRepository;
  late ProviderContainer container;

  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  EventCompleteTicketUrl fixture({required String id, required int hour}) =>
      EventCompleteTicketUrl.empty().copyWith(
        id: id,
        name: id,
        start: DateTime(today.year, today.month, today.day + 3, hour),
        end: DateTime(today.year, today.month, today.day + 3, hour + 2),
      );

  setUp(() {
    mockRepository = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> loadConfirmed(List<EventCompleteTicketUrl> events) async {
    when(() => mockRepository.calendarEventsConfirmedGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('[]', 200), events),
    );
    await container
        .read(confirmedEventListProvider.notifier)
        .loadConfirmedEvent();
  }

  test('the day-sorted map appends a second event of the same day', () async {
    final late = fixture(id: 'late', hour: 18);
    final early = fixture(id: 'early', hour: 9);

    // Oldest first: 'early' creates the bucket and 'late' is APPENDED to it.
    await loadConfirmed([early, late]);

    final byDay = container.read(daySortedEventListProvider);
    final dayKey = byDay.keys.first;
    final sameDay = byDay[dayKey]!.where((e) => e.id != null).toList();
    expect(
      sameDay.where((e) => e.id == 'early' || e.id == 'late').length,
      2,
      reason: 'both events must sit in the same day bucket',
    );
  });

  test('the delay-sorted map appends within an existing delay label', () async {
    final late = fixture(id: 'late', hour: 18);
    final early = fixture(id: 'early', hour: 9);

    await loadConfirmed([early, late]);

    final byDelay = container.read(sortedEventListProvider);
    final bucket = byDelay.values.firstWhere(
      (events) => events.any((e) => e.id == 'late'),
    );
    final ids = bucket.map((e) => e.id).whereType<String>().toList();
    expect(ids, containsAll(['early', 'late']));
    // Appended, so the later hour comes second.
    expect(ids.indexOf('late'), greaterThan(ids.indexOf('early')));
  });
}
