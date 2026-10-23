import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart';
import '../tickets_fixtures.dart';

/// The tickets edit page (`/tickets/edit`, 598 executable lines — the app's
/// biggest uncovered UI file) plus its admin gate.
///
/// The page mounts through AdminMiddleware(canManageTicketEventsProvider):
/// the gate chains myStoresProvider → sellerStoreProvider(storeId) →
/// Seller.canManageEvents, all repository-backed, so the container's
/// [IntegrationScaffold.makeContainer] myStores/storeSellers fakes pin the
/// chain deterministically instead of racing the middleware's redirectGuard
/// against mock answers.
///
/// The page reads its target from selectedTicketEventIdProvider — the
/// manage page sets it before forwarding — and loads the event through
/// ticketEventProvider.
EventAdmin ticketEventFixture() => EventAdmin.empty().copyWith(
  id: 'evt-1',
  name: 'Gala 2026',
  storeId: 'store-1',
  openDatetime: DateTime(2026, 1, 10, 18),
  // A close date pre-fills the end-date controller, so its parse branch and
  // the controller init line run on every save in this file.
  closeDatetime: DateTime(2026, 1, 12, 22),
  quota: 200,
  categories: [
    CategoryAdmin.empty().copyWith(id: 'cat-1', name: 'Normal', price: 1000),
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

  Future<void> pumpEdit(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
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

  /// The full save round-trip: editTicketEvent PATCHes, then the staged
  /// category/session/question PATCHes, then the shotgun list reload.
  void stubSaveChain() {
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperResponse(CategoryAdmin.empty()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(SessionAdmin.empty()));
    when(
      // ignore: void_checks
      () =>
          scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
            eventId: any(named: 'eventId'),
            questionId: any(named: 'questionId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperResponse(Question.empty()));
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );
  }

  testWidgets('the edit form renders the event with its rows', (tester) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));

    await pumpEdit(tester, container);

    expect(find.text('Edit ticketing'), findsOneWidget);
    // The event name shows in the header subtitle AND the pre-filled title
    // field.
    expect(find.text('Gala 2026'), findsNWidgets(2));
    expect(find.text('Statistics'), findsOneWidget);
    // The fixture closes on 12/01/2026, already past: the chip reads Closed.
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    // The row fields carry the fixture data (controllers seeded from it).
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Allergies?'), findsOneWidget);
  });

  testWidgets('the save button round-trips the event patch', (tester) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    stubSaveChain();

    await pumpEdit(tester, container);

    await tester.enterText(find.byType(TextFormField).first, 'Gala renamed');
    await tester.scrollUntilVisible(
      find.text('Save changes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    verify(
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(find.text('Success'), findsOneWidget);
    // Drain the success toast (autoCloseDuration 2500ms + 400ms animation);
    // a pending timer would fail the test at teardown.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  // The gate bounce lives in tickets_edit_gating_integration_test.dart: a
  // redirect to /feed wedges the next deep link in the same file (qlevar
  // only honors the first one), so it is only observable on a file's first
  // deep link.
  testWidgets(
    'the page unmounts when no event id is selected (post-frame back)',
    (tester) async {
      final container = sellerContainer();

      await pumpEdit(tester, container);

      // selectedTicketEventIdProvider is null → the page schedules QR.back()
      // and renders nothing in the meantime.
      expect(find.text('Statistics'), findsNothing);
      expect(find.textContaining('Edit ticketing'), findsNothing);
    },
  );

  testWidgets('both date rows open the date-and-time picker on tap', (
    tester,
  ) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    stubSaveChain();

    await pumpEdit(tester, container);

    // Both header rows go through the real showDatePicker/showTimePicker
    // dialogs (getFullDate): tap the row, OK the date picker, OK the time
    // picker.
    for (final row in [
      'Ticket opening date *',
      'Ticketing closing date (optional)',
    ]) {
      await scrollTo(tester, find.text(row));
      await tester.tap(find.text(row));
      await pumpFrames(tester, 8);
      await tester.tap(find.text('OK').first);
      await pumpFrames(tester, 8);
      await tester.tap(find.text('OK').first);
      await pumpFrames(tester, 8);
    }

    // Saving parses both controllers, including the end-date branch.
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await pumpFrames(tester, 12);
    expect(find.text('Ticketing updated successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('save reports a failure for each staged row phase, then succeeds', (
    tester,
  ) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    stubSaveChain();

    await pumpEdit(tester, container);

    // The ancestor scope keeps value-based finds off the stats card and
    // label-based finds on the exact field: a TextFormField is the only
    // ancestor a label or an EditableText value can have.
    Finder fieldOf(Finder labelOrValue) =>
        find
            .ancestor(
              of: labelOrValue,
              matching: find.byType(TextFormField),
            )
            .first;

    // Stage one edit on every editable row plus the header fields.
    await tester.enterText(find.byType(TextFormField).first, 'Gala renamed');
    await tester.enterText(fieldOf(find.text('Quota')), '150'); // places
    await scrollTo(tester, find.text('Normal'));
    await tester.enterText(fieldOf(find.text('Normal')), 'VIP');
    await tester.enterText(fieldOf(find.text('10.0')), '7'); // category price
    await tester.enterText(fieldOf(find.text('Quota (Optional)')), '25');
    await tester.tap(find.byType(Switch).at(1)); // category deactivated
    await pumpFrames(tester, 4);
    await scrollTo(tester, find.text('Saturday'));
    await tester.enterText(fieldOf(find.text('Saturday')), 'Saturday night');
    await tester.enterText(
      fieldOf(find.text('Quota (Optional)').at(1)),
      '60',
    );
    await tester.tap(find.byType(Switch).at(2)); // session deactivated
    await pumpFrames(tester, 4);
    await scrollTo(tester, find.text('Allergies?'));
    await tester.enterText(fieldOf(find.text('Allergies?')), 'Peanuts?');
    await tester.tap(find.byType(DropdownButtonFormField<AnswerType>).first);
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Yes/No'));
    await pumpFrames(tester, 8);

    Future<void> saveExpecting(String toast) async {
      await scrollTo(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await pumpFrames(tester, 12);
      expect(find.text(toast), findsOneWidget);
      await scaffold.drainToast(tester);
    }

    // Phase failures run in order: event, category, session, question.
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<EventAdmin>(500));
    await saveExpecting('Cannot update this item');

    when(
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperError<CategoryAdmin>(500));
    await saveExpecting('Cannot update this item');

    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperResponse(CategoryAdmin.empty()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<SessionAdmin>(500));
    await saveExpecting('Cannot update this item');

    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(SessionAdmin.empty()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
        eventId: any(named: 'eventId'),
        questionId: any(named: 'questionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<Question>(500));
    await saveExpecting('Read-only (answers have already been recorded)');

    // Everything answers: the staged rows PATCH in turn and the page pops.
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
        eventId: any(named: 'eventId'),
        questionId: any(named: 'questionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(Question.empty()));
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await pumpFrames(tester, 16);
    expect(find.text('Ticketing updated successfully'), findsOneWidget);
    expect(find.text('Edit ticketing'), findsNothing); // the form popped
    await scaffold.drainToast(tester);
  });

  testWidgets('session and category deletes surface API failures', (tester) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));

    await pumpEdit(tester, container);

    when(
      () => scaffold.repository.ticketsAdminEventsEventIdCategoriesCategoryIdDelete(
        eventId: any(named: 'eventId'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => chopperError<void>(500));
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdDelete(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => chopperError<void>(500));

    await scrollTo(tester, find.byTooltip('Delete category'));
    await tester.tap(find.byTooltip('Delete category'));
    await pumpFrames(tester, 14);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);
    expect(
      find.text('Cannot delete: existing sales or checkouts'),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);

    await scrollTo(tester, find.byTooltip('Delete session'));
    await tester.tap(find.byTooltip('Delete session'));
    await pumpFrames(tester, 14);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);
    expect(
      find.text('Cannot delete: existing sales or checkouts'),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);

    // The same session delete succeeds once the API answers.
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdDelete(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    await scrollTo(tester, find.byTooltip('Delete session'));
    await tester.tap(find.byTooltip('Delete session'));
    await pumpFrames(tester, 14);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);
    expect(find.text('Saturday'), findsNothing);
    expect(find.text('Ticketing updated successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a failed event load renders the error template', (tester) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperError<EventAdmin>(500));

    await pumpEdit(tester, container);

    // The error branch shows the raw failure instead of the form: load()
    // rethrows the response error ("Bad state: status 500").
    expect(find.textContaining('status 500'), findsOneWidget);
    expect(find.text('Statistics'), findsNothing);
  });

  testWidgets('the add-category modal rejects negative prices and sends a typed quota', (
    tester,
  ) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdCategoriesPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(CategoryComplete.empty()));

    await pumpEdit(tester, container);
    await scrollTo(tester, find.text('Add category'));
    await tester.tap(find.text('Add category'));
    await pumpFrames(tester, 14);

    // Scope to the modal: the page's own fields appear earlier in the tree.
    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Gold');
    await tester.enterText(modalFields.at(1), '-5');
    await tester.tap(find.text('Add category').last);
    await pumpFrames(tester, 16);

    expect(
      find.text('Price must be 0€ or greater than 1€'),
      findsOneWidget,
    );
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdCategoriesPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
    await scaffold.drainToast(tester);

    // A valid price plus a typed quota round-trips through the POST.
    await tester.tap(find.text('Add category'));
    await pumpFrames(tester, 14);
    await tester.enterText(modalFields.first, 'Gold');
    await tester.enterText(modalFields.at(1), '25');
    await tester.enterText(modalFields.at(2), '10');
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
    expect(captured.name, 'Gold');
    expect(captured.quota, 10);
    await scaffold.drainToast(tester);
  });

  testWidgets('the add-session modal reports create failures with its typed quota', (
    tester,
  ) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<SessionComplete>(500));

    await pumpEdit(tester, container);
    await scrollTo(tester, find.text('Add session'));
    await tester.tap(find.text('Add session'));
    await pumpFrames(tester, 14);

    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Sunday');
    // The modal quota field's onChanged fires on the typed value.
    await tester.enterText(modalFields.at(1), '10');
    // The date row goes through the real showDatePicker/showTimePicker.
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

    expect(find.text('Cannot update this item'), findsOneWidget);
    // The typed quota rode along on the create payload despite the failure.
    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as SessionCreate;
    expect(captured.name, 'Sunday');
    expect(captured.quota, 10);
    await scaffold.drainToast(tester);
  });

  testWidgets('the add-question modal records the picked answer type', (
    tester,
  ) async {
    final container = sellerContainer();
    container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer((_) async => chopperResponse(ticketEventFixture()));
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdQuestionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(Question.empty()));

    await pumpEdit(tester, container);
    await scrollTo(tester, find.text('Add a question'));
    await tester.tap(find.text('Add a question'));
    await pumpFrames(tester, 14);

    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Parking?');
    // The page row also carries a dropdown; scope this one to the modal.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomModalTemplate),
        matching: find.byType(DropdownButtonFormField<AnswerType>),
      ),
    );
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Yes/No'));
    await pumpFrames(tester, 8);

    await tester.tap(find.text('Add a question').last);
    await pumpFrames(tester, 16);

    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdQuestionsPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as QuestionCreate;
    expect(captured.question, 'Parking?');
    expect(captured.answerType, AnswerType.boolean);
    await scaffold.drainToast(tester);
  });
}
