import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/association_tickets_provider.dart';
import 'package:titan/tickets/providers/event_tickets_provider.dart';
import 'package:titan/tickets/providers/store_tickets_list_provider.dart';
import 'package:titan/tickets/providers/ticket_event_list_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/repository/repository.dart';

class MockTicketsRepository extends Mock implements Openapi {}

EventSimple eventSimple(String id, String name) => EventSimple.empty().copyWith(
  id: id,
  name: name,
  storeId: 'store-1',
  openDatetime: DateTime(2100),
);

void main() {
  // Every notifier in this file extends ListNotifierAPI, so they all share the
  // same error contract: fetch failures land in the state as AsyncError while
  // an expired token is rethrown for the session handler.
  group('Ticket event list providers (ListNotifierAPI)', () {
    late MockTicketsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockTicketsRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('AssociationTicketEventListNotifier', () {
      late AssociationTicketEventListNotifier notifier;

      setUp(() {
        notifier = container.read(associationTicketEventListProvider.notifier);
      });

      test('starts with an empty list, not loading', () {
        final state = notifier.state;
        expect(state, isA<AsyncData<List<EventSimple>>>());
        expect(state.value, isEmpty);
      });

      test(
        'loadTicketEvents resets to an empty list without an association',
        () async {
          final result = await notifier.loadTicketEvents(null);

          expect(result.value, isEmpty);
          // No store selected yet: the repository must not be hit at all.
          verifyNever(
            () => mockRepository.ticketsAdminAssociationAssociationIdEventsGet(
              associationId: any(named: 'associationId'),
            ),
          );
        },
      );

      test('loadTicketEvents exposes the association ticketings', () async {
        final events = [eventSimple('1', 'Gala'), eventSimple('2', 'Soirée')];
        when(
          () => mockRepository.ticketsAdminAssociationAssociationIdEventsGet(
            associationId: any(named: 'associationId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), events),
        );

        final result = await notifier.loadTicketEvents('asso-1');

        expect(result.value, events);
      });

      test('loadTicketEvents flags the error when the call fails', () async {
        when(
          () => mockRepository.ticketsAdminAssociationAssociationIdEventsGet(
            associationId: any(named: 'associationId'),
          ),
        ).thenThrow(Exception('network down'));

        final result = await notifier.loadTicketEvents('asso-1');

        expect(result, isA<AsyncError<List<EventSimple>>>());
      });

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.ticketsAdminAssociationAssociationIdEventsGet(
            associationId: any(named: 'associationId'),
          ),
        ).thenThrow(error);

        await expectLater(
          notifier.loadTicketEvents('asso-1'),
          throwsA(same(error)),
        );
      });
    });

    group('StoreTicketEventListNotifier', () {
      late StoreTicketEventListNotifier notifier;

      setUp(() {
        notifier = container.read(storeTicketEventListProvider.notifier);
      });

      test('starts in the loading state', () {
        expect(notifier.state, isA<AsyncLoading>());
      });

      test('loadStoreTicketEventList exposes the fetched events', () async {
        final events = [eventSimple('1', 'Gala'), eventSimple('2', 'Soirée')];
        when(
          () => mockRepository.ticketsAdminStoreStoreIdEventsGet(
            storeId: any(named: 'storeId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), events),
        );

        final result = await notifier.loadStoreTicketEventList('store-1');

        expect(
          result.when(data: (d) => d, error: (e, s) => [], loading: () => []),
          events,
        );
        expect(notifier.state, isA<AsyncData<List<EventSimple>>>());
      });

      test(
        'loadStoreTicketEventList flags the error when the call fails',
        () async {
          when(
            () => mockRepository.ticketsAdminStoreStoreIdEventsGet(
              storeId: any(named: 'storeId'),
            ),
          ).thenThrow(Exception('network down'));

          final result = await notifier.loadStoreTicketEventList('store-1');

          expect(result, isA<AsyncError<List<EventSimple>>>());
          expect(notifier.state, isA<AsyncError<List<EventSimple>>>());
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.ticketsAdminStoreStoreIdEventsGet(
            storeId: any(named: 'storeId'),
          ),
        ).thenThrow(error);

        await expectLater(
          notifier.loadStoreTicketEventList('store-1'),
          throwsA(same(error)),
        );
      });
    });

    group('EventTicketsNotifier', () {
      late EventTicketsNotifier notifier;

      setUp(() {
        notifier = container.read(eventTicketsProvider.notifier);
      });

      test('starts in the loading state', () {
        expect(notifier.state, isA<AsyncLoading>());
      });

      test('loadEventTickets exposes the fetched tickets', () async {
        final tickets = [
          AppCoreTicketsSchemasTicketsTicket.empty().copyWith(id: '1'),
          AppCoreTicketsSchemasTicketsTicket.empty().copyWith(id: '2'),
        ];
        when(
          () => mockRepository.ticketsAdminEventsEventIdTicketsGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), tickets),
        );

        final result = await notifier.loadEventTickets('event-1');

        expect(
          result.when(data: (d) => d, error: (e, s) => [], loading: () => []),
          tickets,
        );
        expect(notifier.state, isA<AsyncData>());
      });

      test('loadEventTickets flags the error when the call fails', () async {
        when(
          () => mockRepository.ticketsAdminEventsEventIdTicketsGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenThrow(Exception('network down'));

        final result = await notifier.loadEventTickets('event-1');

        expect(result, isA<AsyncError>());
        expect(notifier.state, isA<AsyncError>());
      });

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.ticketsAdminEventsEventIdTicketsGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenThrow(error);

        await expectLater(
          notifier.loadEventTickets('event-1'),
          throwsA(same(error)),
        );
      });
    });

    group('ShotgunListNotifier', () {
      late ShotgunListNotifier notifier;

      setUp(() async {
        // build() loads the shotgun list immediately, so the fetch has to be
        // stubbed before the container creates the notifier.
        when(() => mockRepository.ticketsEventsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <EventSimple>[]),
        );
        notifier = container.read(ticketEventListProvider.notifier);
        await Future<void>.delayed(Duration.zero);
      });

      test('build loads the shotgun list', () {
        final state = container.read(ticketEventListProvider);
        expect(state, isA<AsyncData<List<EventSimple>>>());
        expect(state.value, isEmpty);
      });

      test('loadShotgunList exposes the fetched events', () async {
        final events = [eventSimple('1', 'Gala'), eventSimple('2', 'Soirée')];
        when(() => mockRepository.ticketsEventsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), events),
        );

        final result = await notifier.loadShotgunList();

        expect(result.value, events);
      });

      test('createTicketEvent adds the converted event to the list', () async {
        final eventAdmin = EventAdmin.empty().copyWith(
          id: 'event-1',
          name: 'Gala',
          storeId: 'store-1',
          openDatetime: DateTime(2100),
        );
        when(
          () => mockRepository.ticketsAdminEventsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 201), eventAdmin),
        );

        final result = await notifier.createTicketEvent(
          EventCreate.empty().copyWith(name: 'Gala', storeId: 'store-1'),
        );

        // The repository answers an EventAdmin; the notifier converts it to an
        // EventSimple before appending it, because the list holds EventSimple.
        expect(result, isTrue);
        expect(notifier.state.value, [eventSimple('event-1', 'Gala')]);
      });

      test(
        'createTicketEvent fails when the backend rejects the event',
        () async {
          when(
            () =>
                mockRepository.ticketsAdminEventsPost(body: any(named: 'body')),
          ).thenAnswer(
            (_) async => chopper.Response<EventAdmin>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );

          final result = await notifier.createTicketEvent(
            EventCreate.empty().copyWith(name: 'Gala', storeId: 'store-1'),
          );

          expect(result, isFalse);
          // ListNotifierAPI.add leaves the previous data in place on failure:
          // the UI keeps showing the old list and the caller shows a toast.
          expect(notifier.state, isA<AsyncData<List<EventSimple>>>());
          expect(notifier.state.value, isEmpty);
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.ticketsAdminEventsPost(body: any(named: 'body')),
        ).thenThrow(error);

        await expectLater(
          notifier.createTicketEvent(
            EventCreate.empty().copyWith(name: 'Gala', storeId: 'store-1'),
          ),
          throwsA(same(error)),
        );
      });
    });
  });
}
