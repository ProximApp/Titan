import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/ticket_event_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockTicketRepository extends Mock implements Openapi {}

void main() {
  group('TicketEventNotifier', () {
    late MockTicketRepository mockRepository;
    late ProviderContainer container;

    final eventA = EventAdmin.empty().copyWith(
      id: 'a',
      name: 'Event A',
      quota: 10,
    );
    final eventB = EventAdmin.empty().copyWith(
      id: 'b',
      name: 'Event B',
      quota: 20,
    );

    void stubGet(String eventId, EventAdmin event) {
      when(
        () => mockRepository.ticketsAdminEventsEventIdGet(eventId: eventId),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), event),
      );
    }

    setUp(() {
      mockRepository = MockTicketRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('loadTicketEvent returns the fetched event', () async {
      stubGet('a', eventA);
      final sub = container.listen(ticketEventProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(ticketEventProvider.notifier).loadTicketEvent('a');

      final state = container.read(ticketEventProvider);
      expect(state.value!.id, 'a');
      expect(state.value!.name, 'Event A');
      expect(state.value!.quota, 10);
    });

    test('loadTicketEvent surfaces fetch errors', () async {
      when(
        () => mockRepository.ticketsAdminEventsEventIdGet(eventId: 'a'),
      ).thenThrow(Exception('network down'));
      final sub = container.listen(ticketEventProvider, (_, _) {});
      addTearDown(sub.close);

      final result = await container
          .read(ticketEventProvider.notifier)
          .loadTicketEvent('a');

      expect(result, isA<AsyncError>());
    });

    test('editing a second event never exposes the first one', () async {
      stubGet('a', eventA);
      stubGet('b', eventB);

      // The edit page for A is open.
      final pageA = container.listen(ticketEventProvider, (_, _) {});
      await container.read(ticketEventProvider.notifier).loadTicketEvent('a');
      expect(container.read(ticketEventProvider).value!.id, 'a');

      // The page is closed: the autoDispose provider is destroyed with it.
      pageA.close();
      await Future<void>.delayed(Duration.zero);

      // The edit page for B opens: the provider rebuilds in loading and must
      // never expose A's data, only resolve to B.
      final sawStates = <AsyncValue<EventAdmin>>[];
      final pageB = container.listen(ticketEventProvider, (_, next) {
        sawStates.add(next);
      });
      addTearDown(pageB.close);

      expect(container.read(ticketEventProvider).isLoading, isTrue);

      await container.read(ticketEventProvider.notifier).loadTicketEvent('b');

      for (final state in sawStates) {
        expect(state.value?.id, isNot('a'));
      }
      expect(container.read(ticketEventProvider).value!.id, 'b');
      expect(container.read(ticketEventProvider).value!.name, 'Event B');
    });
  });
}
