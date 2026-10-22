import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/ticket_id_provider.dart';
import 'package:titan/purchases/providers/ticket_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

AppModulesCdrSchemasCdrTicket ticket(String id) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(id: id);

void main() {
  late MockOpenapi repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('TicketIdNotifier', () {
    test('setTicketId holds the id', () {
      container.read(ticketIdProvider.notifier).setTicketId('gen-1');

      expect(container.read(ticketIdProvider).value, 'gen-1');
    });

    test('the repository getter resolves the overridden client', () {
      expect(
        container.read(ticketIdProvider.notifier).ticketIdRepository,
        same(repository),
      );
    });
  });

  group('TicketNotifier', () {
    test('setTicket holds the ticket', () {
      container.read(ticketProvider.notifier).setTicket(ticket('t-1'));

      expect(container.read(ticketProvider).value?.id, 't-1');
    });

    test('loadTicketSecret returns the secret on success', () async {
      when(() => repository.cdrUsersMeTicketsTicketIdSecretGet(ticketId: 't-1'))
          .thenAnswer(
            (_) async => chopper.Response(
              http.Response('body', 200),
              TicketSecret.empty().copyWith(qrCodeSecret: 'secret-abc'),
            ),
          );
      final notifier = container.read(ticketProvider.notifier);
      notifier.setTicket(ticket('t-1'));

      final result = await notifier.loadTicketSecret();

      expect(result.value?.qrCodeSecret, 'secret-abc');
    });

    test('loadTicketSecret errors when the backend refuses', () async {
      when(() => repository.cdrUsersMeTicketsTicketIdSecretGet(ticketId: 't-1'))
          .thenAnswer(
            (_) async => chopper.Response<TicketSecret>(
              http.Response('nope', 404),
              null,
              error: StateError('404'),
            ),
          );
      final notifier = container.read(ticketProvider.notifier);
      notifier.setTicket(ticket('t-1'));

      final result = await notifier.loadTicketSecret();

      expect(result.hasError, isTrue);
    });

    test('loadTicketSecret errors while the ticket is still loading', () async {
      final result = await container
          .read(ticketProvider.notifier)
          .loadTicketSecret();

      expect(result.hasError, isTrue);
    });
  });
}
