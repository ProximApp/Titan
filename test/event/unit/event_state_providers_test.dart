import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/event/providers/event_provider.dart';
import 'package:titan/event/providers/selected_days_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

/// The two state notifiers the event forms drive. They are plain
/// SingleNotifier-style holders, so the whole surface is build/set and was
/// previously reached only through the add-edit form test.
void main() {
  group('eventProvider', () {
    test('starts on the empty event; setEvent and setRoom mutate it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(eventProvider), EventCompleteTicketUrl.empty());

      final notifier = container.read(eventProvider.notifier);
      notifier.setEvent(
        EventCompleteTicketUrl.empty().copyWith(id: 'e-1', name: 'Soirée Kino'),
      );
      expect(container.read(eventProvider).id, 'e-1');
      expect(container.read(eventProvider).name, 'Soirée Kino');

      notifier.setRoom('Amphi Darwin');
      expect(container.read(eventProvider).location, 'Amphi Darwin');
      // setRoom copies: the id survives the room update.
      expect(container.read(eventProvider).id, 'e-1');
    });
  });

  group('selectedDaysProvider', () {
    test('toggles single days and clears back to all-false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedDaysProvider), List.filled(7, false));

      final notifier = container.read(selectedDaysProvider.notifier);
      notifier.toggle(0);
      notifier.toggle(2);
      expect(container.read(selectedDaysProvider), [
        true,
        false,
        true,
        false,
        false,
        false,
        false,
      ]);

      // Toggling back flips only that day.
      notifier.toggle(0);
      expect(container.read(selectedDaysProvider)[0], false);
      expect(container.read(selectedDaysProvider)[2], true);

      notifier.clear();
      expect(container.read(selectedDaysProvider), List.filled(7, false));
    });
  });
}
