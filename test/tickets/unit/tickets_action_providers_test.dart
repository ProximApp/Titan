import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/csv_download_provider.dart';
import 'package:titan/tickets/providers/ticket_change_over_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockTicketsRepository extends Mock implements Openapi {}

void main() {
  // Both notifiers report a one-shot action through AsyncValue<void>: loading
  // while the call is in flight, data or error once it settles.
  group('Tickets one-shot action providers (AsyncValue<void>)', () {
    late MockTicketsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockTicketsRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('TicketChangeOverNotifier', () {
      test('starts idle, not loading', () {
        expect(container.read(ticketChangeOverProvider).isLoading, isFalse);
      });

      test(
        'requestChangeOver returns true and clears the error on success',
        () async {
          when(
            () => mockRepository.ticketsUserMeTicketsChangeOverRequestPost(
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<String>(http.Response('body', 201), ''),
          );

          final result = await container
              .read(ticketChangeOverProvider.notifier)
              .requestChangeOver('ticket-1', 'friend@example.com');

          expect(result, isTrue);
          final state = container.read(ticketChangeOverProvider);
          expect(state.isLoading, isFalse);
          expect(state.hasError, isFalse);
        },
      );

      test(
        'requestChangeOver reports backend failures through the state',
        () async {
          when(
            () => mockRepository.ticketsUserMeTicketsChangeOverRequestPost(
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<String>(
              http.Response('User is not the owner', 403),
              '',
              error: 'User is not the owner',
            ),
          );

          final result = await container
              .read(ticketChangeOverProvider.notifier)
              .requestChangeOver('ticket-1', 'friend@example.com');

          expect(result, isFalse);
          final state = container.read(ticketChangeOverProvider);
          expect(state.hasError, isTrue);
          // The modal matches on this substring to show a translated message.
          expect(state.error.toString(), contains('User is not the owner'));
        },
      );

      test(
        'requestChangeOver reports thrown exceptions through the state',
        () async {
          when(
            () => mockRepository.ticketsUserMeTicketsChangeOverRequestPost(
              body: any(named: 'body'),
            ),
          ).thenThrow(Exception('network down'));

          final result = await container
              .read(ticketChangeOverProvider.notifier)
              .requestChangeOver('ticket-1', 'friend@example.com');

          expect(result, isFalse);
          expect(container.read(ticketChangeOverProvider).hasError, isTrue);
        },
      );
    });

    group('CsvDownloadNotifier', () {
      test('starts idle, not loading', () {
        expect(container.read(csvDownloadProvider).isLoading, isFalse);
      });

      test('downloadCsv returns the CSV bytes on success', () async {
        // The endpoint is declared as a raw byte payload, so the body comes
        // through http.Response's bytes rather than a decoded model.
        final csvBytes = Uint8List.fromList('id,name\r\n1,Gala\r\n'.codeUnits);
        when(
          () => mockRepository.ticketsAdminEventsEventIdTicketsCsvGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<List<int>>(
            http.Response.bytes(csvBytes, 200),
            csvBytes,
          ),
        );

        final bytes = await container
            .read(csvDownloadProvider.notifier)
            .downloadCsv('event-1');

        expect(bytes, csvBytes);
        expect(container.read(csvDownloadProvider).isLoading, isFalse);
        expect(container.read(csvDownloadProvider).hasError, isFalse);
      });

      test(
        'downloadCsv hands back whatever body the backend answers with',
        () async {
          // downloadCsv only guards against thrown exceptions, not against
          // unsuccessful HTTP statuses: a 403 body comes back as bytes and the
          // state settles on data. Documented as-is; if the notifier ever
          // learns to check isSuccessful, this test should turn into a
          // null-return expectation.
          final body = Uint8List.fromList('forbidden'.codeUnits);
          when(
            () => mockRepository.ticketsAdminEventsEventIdTicketsCsvGet(
              eventId: any(named: 'eventId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<List<int>>(
              http.Response('forbidden', 403),
              body,
              error: 'forbidden',
            ),
          );

          final bytes = await container
              .read(csvDownloadProvider.notifier)
              .downloadCsv('event-1');

          expect(bytes, body);
          expect(container.read(csvDownloadProvider).hasError, isFalse);
        },
      );

      test('downloadCsv returns null when the repository throws', () async {
        when(
          () => mockRepository.ticketsAdminEventsEventIdTicketsCsvGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenThrow(Exception('network down'));

        final bytes = await container
            .read(csvDownloadProvider.notifier)
            .downloadCsv('event-1');

        expect(bytes, isNull);
        expect(container.read(csvDownloadProvider).hasError, isTrue);
      });
    });
  });
}
