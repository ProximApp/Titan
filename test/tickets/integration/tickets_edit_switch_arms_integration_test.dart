import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/ticket_event_provider.dart';
import 'package:titan/tickets/ui/components/switch_row.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The edit page's state-switch arms and the successful cancellation.
///
/// Three things the other edit files leave untouched:
///  * the EVENT switch — every fixture is activated, so neither the
///    "deactivated" title nor the toggle callback ever ran;
///  * the CATEGORY switch — the same, on the other card, and its staged edit
///    is what makes the save fan out to the category endpoint;
///  * a SUCCESSFUL cancellation. `TicketEventNotifier.cancelEvent` returns
///    false unconditionally today (the endpoint is missing), so the
///    success arm is unreachable through the real notifier; it is driven here
///    through a notifier override that answers true, which is the only way to
///    execute the reload-and-report sequence the page already has.
///
/// The rest of the page's uncovered lines are genuinely unreachable rather
/// than untested: `openDatetime` is non-nullable on `EventAdmin`, so the
/// "start date required" toast and the "Not set" subtitle cannot occur, and
/// the add-session modal's date row is a tap-only `ListItemTemplate`, so a
/// date the parser rejects cannot be typed into it.
void main() {
  late IntegrationScaffold scaffold;

  /// The bodies the save fan-out actually sent.
  Object? capturedEventBody;
  Object? capturedCategoryBody;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  EventAdmin fixture({bool disabled = false, bool categoryDisabled = false}) =>
      EventAdmin.empty().copyWith(
        id: 'evt-1',
        name: 'Gala 2026',
        storeId: 'store-1',
        openDatetime: DateTime(2026, 1, 10, 18),
        quota: 200,
        disabled: disabled,
        categories: [
          CategoryAdmin.empty().copyWith(
            id: 'cat-1',
            name: 'Normal',
            price: 1000,
            quota: 100,
            disabled: categoryDisabled,
          ),
        ],
        sessions: [
          SessionAdmin.empty().copyWith(
            id: 'ses-1',
            name: 'Saturday',
            startDatetime: DateTime(2026, 1, 11, 20),
          ),
        ],
        questions: [
          QuestionAdmin.empty().copyWith(id: 'q-1', question: 'Allergies?'),
        ],
      );

  void stubSaveChain() {
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      capturedEventBody = inv.namedArguments[#body];
      return chopperResponseVoid();
    });
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((inv) async {
      capturedCategoryBody = inv.namedArguments[#body];
      return chopperResponseVoid();
    });
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );
  }

  /// The [Switch] inside the row whose title is [title]:
  /// `SwitchRow.onChanged` is wired to the switch itself and to the row tap.
  Finder switchOf(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(SwitchRow)),
    matching: find.byType(Switch),
  );

  testWidgets(
    'a deactivated event is labelled so and its switch re-activates it on save',
    (tester) async {
      stubSaveChain();
      final container = sellerContainer(scaffold);
      addTearDown(container.dispose);

      await pumpEdit(scaffold, tester, container, fixture(disabled: true));
      expect(find.text('Event deactivated'), findsOneWidget);

      await tester.ensureVisible(switchOf('Event deactivated'));
      await tester.tap(switchOf('Event deactivated'));
      await pumpFrames(tester, 8);
      // The label follows the flipped state, so the callback really ran.
      expect(find.text('Event activated'), findsOneWidget);
      expect(find.text('Event deactivated'), findsNothing);

      await scrollTo(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await pumpFrames(tester, 16);

      verify(
        () => scaffold.repository.ticketsAdminEventsEventIdPatch(
          eventId: 'evt-1',
          body: any(named: 'body'),
        ),
      ).called(1);
      // The merged event the page keeps carries the flipped flag.
      expect((capturedEventBody as dynamic).toJson()['disabled'], isFalse);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets(
    'a category switch deactivates it and stages the edit for the save fan-out',
    (tester) async {
      stubSaveChain();
      final container = sellerContainer(scaffold);
      addTearDown(container.dispose);

      await pumpEdit(scaffold, tester, container, fixture());
      expect(find.text('Category activated'), findsOneWidget);

      await scrollTo(tester, find.text('Category activated'));
      await tester.ensureVisible(switchOf('Category activated'));
      await tester.tap(switchOf('Category activated'));
      await pumpFrames(tester, 8);
      expect(find.text('Category deactivated'), findsOneWidget);

      await scrollTo(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await pumpFrames(tester, 18);

      // A staged category differs from the server copy, so the fan-out PATCHes
      // that category by id rather than the event alone.
      verify(
        () => scaffold.repository
            .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
              eventId: 'evt-1',
              categoryId: 'cat-1',
              body: any(named: 'body'),
            ),
      ).called(1);
      expect((capturedCategoryBody as dynamic).toJson()['disabled'], isTrue);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('an accepted cancellation reloads the list and reports it', (
    tester,
  ) async {
    // The real notifier answers false (no endpoint), so the success arm is
    // reached through an override that answers true.
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      myStores: [models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE')],
      storeSellers: {
        'store-1': [
          Seller.empty().copyWith(userId: 'me', canManageEvents: true),
        ],
      },
      providerOverrides: [ticketEventProvider.overrideWith(_Accepted.new)],
    );
    addTearDown(container.dispose);
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );

    await pumpEdit(scaffold, tester, container, fixture());

    // The page's own mount already reloaded the list once; only the
    // reload the cancellation triggers is counted here.
    clearInteractions(scaffold.repository);
    await scrollTo(tester, find.text('Cancel event'));
    await tester.tap(find.text('Cancel event'));
    await pumpFrames(tester, 14);
    expect(find.text('Cancel this event?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 18);

    // The reload goes out before the page reports the cancellation.
    // The reload goes out before the page reports the cancellation. The list
    // provider refreshes it on mount as well, so the count is not pinned.
    expect(
      verify(() => scaffold.repository.ticketsEventsGet()).callCount,
      greaterThanOrEqualTo(1),
    );
    expect(find.text('Event cancelled'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}

/// [TicketEventNotifier] with the missing endpoint stubbed to succeed, so the
/// page's success arm (reload, then toast) can run.
class _Accepted extends TicketEventNotifier {
  @override
  Future<bool> cancelEvent(String eventId) async => true;
}
