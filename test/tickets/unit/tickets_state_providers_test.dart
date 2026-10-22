import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';
import 'package:titan/tickets/providers/tickets_on_back_provider.dart';

void main() {
  // Plain in-memory state holders: no repository, nothing async.
  group('Tickets state holders', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    group('SelectedTicketEventIdNotifier', () {
      test('starts with no selected event', () {
        expect(container.read(selectedTicketEventIdProvider), isNull);
      });

      test('setId stores the selected event id', () {
        container.read(selectedTicketEventIdProvider.notifier).setId('event-1');

        expect(container.read(selectedTicketEventIdProvider), 'event-1');
      });

      test('setId(null) clears the selection', () {
        container.read(selectedTicketEventIdProvider.notifier).setId('event-1');
        container.read(selectedTicketEventIdProvider.notifier).setId(null);

        expect(container.read(selectedTicketEventIdProvider), isNull);
      });
    });

    group('TicketsOnBackNotifier', () {
      test('starts with no callback registered', () {
        expect(container.read(ticketsOnBackProvider), isNull);
      });

      test('setOnBack registers the callback', () {
        var called = false;
        container
            .read(ticketsOnBackProvider.notifier)
            .setOnBack(() => called = true);

        expect(container.read(ticketsOnBackProvider), isNotNull);
        container.read(ticketsOnBackProvider)!();
        expect(called, isTrue);
      });

      test('the template clears the callback before invoking it', () {
        // TicketTemplate wraps the callback so the custom back button only
        // fires once; simulate what its build() does.
        var calls = 0;
        void customBack() => calls++;

        container.read(ticketsOnBackProvider.notifier).setOnBack(customBack);

        final registered = container.read(ticketsOnBackProvider);
        container.read(ticketsOnBackProvider.notifier).setOnBack(null);
        registered?.call();

        expect(container.read(ticketsOnBackProvider), isNull);
        expect(calls, 1);
      });
    });
  });
}
