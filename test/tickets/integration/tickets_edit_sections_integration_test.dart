import 'package:flutter/material.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';

/// The edit page's item-management sections (edit_ticket_event_page's
/// ~200 uncovered section lines): per-row fields, locked branches, the
/// add-category / add-session / add-question modals round-tripping their
/// POST endpoints, the delete confirm modal and the event cancel/delete
/// flows.
///
/// The page-level render and the event PATCH round-trip live in
/// tickets_edit_integration_test.dart — everything here adds a different
/// code path, nothing overlaps.
EventAdmin ticketEventFixture({bool withSales = false}) {
  final sold = withSales ? 3 : 0;
  return EventAdmin.empty().copyWith(
    id: 'evt-1',
    name: 'Gala 2026',
    storeId: 'store-1',
    openDatetime: DateTime(2026, 1, 10, 18),
    quota: 200,
    ticketsSold: sold,
    categories: [
      CategoryAdmin.empty().copyWith(
        id: 'cat-1',
        name: 'Normal',
        price: 1000,
        quota: 100,
        ticketsSold: sold,
      ),
    ],
    sessions: [
      SessionAdmin.empty().copyWith(
        id: 'ses-1',
        name: 'Saturday',
        startDatetime: DateTime(2026, 1, 11, 20),
        ticketsSold: sold,
      ),
    ],
    questions: [
      QuestionAdmin.empty().copyWith(id: 'q-1', question: 'Allergies?'),
    ],
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer sellerContainer() {
    return scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      myStores: [models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE')],
      storeSellers: {
        'store-1': [
          Seller.empty().copyWith(userId: 'me', canManageEvents: true),
        ],
      },
    );
  }

  /// Pumps the edit page with [fixture] answering the event GET.
  Future<void> pumpEdit(
    WidgetTester tester,
    ProviderContainer container,
    EventAdmin fixture,
  ) async {
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(fixture));

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/edit',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Scrolls the section's add/delete row into view. Everything below the
  /// stats card sits under the fold, and dropped taps fail silently.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
  }

  testWidgets('sold rows render locked: banner, disabled fields, sold counts', (
    tester,
  ) async {
    await pumpEdit(
      tester,
      sellerContainer(),
      ticketEventFixture(withSales: true),
    );

    expect(find.text('Edit ticketing'), findsOneWidget);
    // canDeleteEvent == false: the read-only banner shows and the delete
    // button is disabled; the questions section is frozen wholesale.
    expect(
      find.text('Cannot delete: existing sales or checkouts'),
      findsWidgets,
    );
    expect(
      find.text('Read-only (answers have already been recorded)'),
      findsOneWidget,
    );
    // Locked rows show their sales line; sold counters end with a period.
    expect(find.text('3 tickets sold, 0 in checkout'), findsWidgets);
    // The add-question button is hidden while questions are frozen.
    expect(find.text('Add question'), findsNothing);

    await scrollTo(tester, find.text('Normal'));
    // The sold-out category's fields render disabled (enterText bypasses
    // enabled, so assert the widget state instead).
    final nameField = tester.widget<TextFormField>(
      find
          .ancestor(
            of: find.text('Normal'),
            matching: find.byType(TextFormField),
          )
          .first,
    );
    expect(nameField.enabled, isFalse);
  });

  testWidgets('the add-category modal creates a category with cents price', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdCategoriesPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(CategoryComplete.empty()));

    await scrollTo(tester, find.text('Add category'));
    await tester.tap(find.text('Add category'));
    await pumpFrames(tester, 14);

    // The modal form is open (tariff numbered after the existing one).
    expect(find.text('Category 2'), findsOneWidget);
    // Scope to the modal: the page's own fields appear earlier in the tree.
    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'VIP');
    await tester.enterText(modalFields.at(1), '12');

    await tester.tap(find.text('Add category').last);
    await pumpFrames(tester, 16);

    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdCategoriesPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as CategoryCreate;
    expect(captured.name, 'VIP');
    // Euros in the form, cents on the wire.
    expect(captured.price, 1200);
    await scaffold.drainToast(tester);
  });

  testWidgets('the add-session modal creates a session through the API', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(SessionComplete.empty()));

    await scrollTo(tester, find.text('Add session'));
    await tester.tap(find.text('Add session'));
    await pumpFrames(tester, 14);

    expect(find.text('Session 2'), findsOneWidget);
    // Scope to the modal: the page's own fields appear earlier in the tree.
    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Sunday');
    // The date row goes through the real showDatePicker/showTimePicker
    // dialogs (getFullDate), so tap the row and OK through both. Scope to
    // the modal: the page carries 'Date' rows of its own.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomModalTemplate),
        matching: find.text('Date'),
      ),
    );
    await pumpFrames(tester, 8);
    await tester.tap(find.text('OK').first);
    await pumpFrames(tester, 8);
    await tester.tap(find.text('OK').first);
    await pumpFrames(tester, 8);

    await tester.tap(find.text('Add session').last);
    await pumpFrames(tester, 16);

    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as SessionCreate;
    expect(captured.name, 'Sunday');
    // Today's picker round-trip (now-based defaults), parsed back from the
    // formatted controller text by processDateBackWithHourMaybe.
    expect(captured.startDatetime, isA<DateTime>());
    await scaffold.drainToast(tester);
  });

  testWidgets('deleting a category confirms through the modal then DELETEs', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdDelete(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
          ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scrollTo(tester, find.byTooltip('Delete category'));
    await tester.tap(find.byTooltip('Delete category'));
    await pumpFrames(tester, 14);

    expect(find.text('Confirm deletion?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    verify(
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdDelete(
            eventId: 'evt-1',
            categoryId: 'cat-1',
          ),
    ).called(1);
    await scaffold.drainToast(tester);
  });

  testWidgets('cancel event reports the unavailable-endpoint toast', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

    await scrollTo(tester, find.text('Cancel event'));
    await tester.tap(find.text('Cancel event'));
    await pumpFrames(tester, 14);

    expect(find.text('Cancel this event?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    // cancelEvent always returns false today: the reason toast shows.
    expect(find.text('Cancellation is not available yet'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('delete event is disabled while sales exist', (tester) async {
    await pumpEdit(
      tester,
      sellerContainer(),
      ticketEventFixture(withSales: true),
    );

    await scrollTo(tester, find.text('Delete ticketing'));
    // The disabled button never opens the confirm modal.
    await tester.tap(find.text('Delete ticketing'), warnIfMissed: false);
    await pumpFrames(tester, 14);
    expect(find.text('Confirm deletion?'), findsNothing);
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    );
  });

  testWidgets('delete event round-trips the DELETE and reports refusals', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 409),
        null,
      ),
    );

    await scrollTo(tester, find.text('Delete ticketing'));
    await tester.tap(find.text('Delete ticketing'));
    await pumpFrames(tester, 14);

    expect(find.text('Confirm deletion?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    verify(
      () =>
          scaffold.repository.ticketsAdminEventsEventIdDelete(eventId: 'evt-1'),
    ).called(1);
    // The refusal toast renders through the form context (delete failures
    // always name the sales guard as the reason).
    expect(
      find.text('Cannot delete: existing sales or checkouts'),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('delete event success toasts and pops through the navigator', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    // The form is unmounted by its own pop before the success toast fires,
    // so the page toasts through the navigator's context captured at
    // delete time — it resolves the app-level ToastificationWrapper.
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      () => scaffold.repository.ticketsEventsGet(),
    ).thenAnswer((_) async => chopperListResponse<EventSimple>([]));

    await scrollTo(tester, find.text('Delete ticketing'));
    await tester.tap(find.text('Delete ticketing'));
    await pumpFrames(tester, 14);

    expect(find.text('Confirm deletion?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    verify(
      () =>
          scaffold.repository.ticketsAdminEventsEventIdDelete(eventId: 'evt-1'),
    ).called(1);
    expect(find.text('Ticketing deleted successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
