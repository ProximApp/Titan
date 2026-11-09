import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/date_entry.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// edit_ticket_event_page's RESIDUAL uncovered paths — everything the other
/// edit files deliberately skipped:
/// - the page-level save validations (empty title, unparseable quota) and
///   their error toasts,
/// - the stats card internals (sold/quota RichText, in-checkout tile),
/// - the save fan-out that PATCHes staged category/session/question edits
///   through their own endpoints, one section per test because the page
///   re-seeds its staged rows whenever the event provider changes (the
///   plain event PATCH lives in tickets_edit_integration_test.dart; the
///   add/delete modals and locked rows live in
///   tickets_edit_sections_integration_test.dart — nothing repeats those).
///
/// Three lines of that page stay dark under everything tried here:
///
///  * `save()`'s empty-start-date guard (155) and the start-date row's "date
///    not set" subtitle (359) — re-check the numbers if this file's neighbours
///    grow; both are the START-date pair, never the end-date one (the end-date
///    pair is covered, because the closing date may really be absent).
///
///    ATTEMPTED, in this order: (a) the row is a `ListItemTemplate` subtitle,
///    not a field — `find.widgetWithText(EditableText, '10/01/2026 18:00')`
///    finds nothing and typing into every `TextFormField` on the page leaves
///    the subtitle alone, so there is no text to delete; (b) tapping the row
///    opens the real date dialog and CANCELing it writes nothing (`pickDate`
///    returns before the write); (c) CONFIRMING the date and then CANCELing
///    the time dialog writes nothing either (`pickFullDate` answers null), the
///    closest the UI gets to a cleared row; (d) saving after (b) and (c)
///    PATCHes the event's own `openDatetime`. The controller is seeded from
///    `openDatetime`, which `EventAdmin` does not let be null, so "empty" is
///    not a state this row can carry. The contrast test below mounts an event
///    with NO closing date: the "Not set" subtitle renders on that row and
///    only on that row, so the label is live and the opening row's copy of it
///    is excluded by the model, not by the widget being unable to show it.
///  * the session modal's parse failure (743). ATTEMPTED: the same file opens
///    the add-session modal and asserts its only `TextFormField`s are the name
///    and the quota — the date row is a subtitle that shows "Not set" until
///    the picker writes into it, so no unparseable text can be supplied;
///    submitting with an empty date returns before the parse (no POST);
///    CONFIRMING the date and then cancelling the time leaves the row at "Not
///    set" and the submit still returns on the empty-date guard. A complete
///    pick is written by `getFullDate` as `DateFormat.yMd(locale).add_Hm()`
///    and read back by `processDateBackWithHourMaybe` with that same pattern,
///    so the value the parse receives is the one it produced — the round-trip
///    is asserted down to the POSTed `startDatetime` in
///    `tickets_edit_sections_integration_test.dart`.
///
///    The helper boundary is pinned in
///    `unit/edit_session_date_boundary_test.dart`, and running it corrected
///    what this header used to assume. The catch needs a SHAPE mismatch, not
///    a bad value: intl ROLLS over out-of-range fields instead of throwing
///    (`25/01/2026 18:00` under en reads as 1 January 2028, `99/99/9999` as a
///    year-10007 date), so a wrong day never reaches the catch — and a shape
///    the picker does not write never reaches it either, because
///    `getFullDate` writes the pattern the reader parses.
///
/// The first attempt at the start-date row exposed a real defect: the rows are
/// seeded with `DateFormat('dd/MM/yyyy HH:mm')` but the save re-parsed them
/// with `processDateBackWithHourMaybe`, which reads the LOCALE's yMd pattern.
/// The test that cancels the picker and reads the PATCH body back caught it —
/// (that dd/MM seed did not crash on a day past 12, it silently sent another
/// date: see the roll-over note under 743.)
/// `10/01/2026 18:00` went out as 1 October under the en locale. The page now
/// writes the picked date through `dateFormatter` (`pickDate`) and parses the
/// two rows with it, so the row's own format is the one it round-trips.
EventAdmin ticketEventFixture({bool withSales = true}) =>
    EventAdmin.empty().copyWith(
      id: 'evt-1',
      name: 'Gala 2026',
      storeId: 'store-1',
      openDatetime: DateTime(2026, 1, 10, 18),
      quota: 200,
      ticketsSold: withSales ? 3 : 0,
      ticketsInCheckout: withSales ? 2 : 0,
      categories: [
        CategoryAdmin.empty().copyWith(
          id: 'cat-1',
          name: 'Normal',
          price: 1000,
          quota: 100,
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

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubSaveChain() {
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      // ignore: void_checks
      () =>
          scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
            eventId: any(named: 'eventId'),
            questionId: any(named: 'questionId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );
  }

  Future<void> saveAndSettle(WidgetTester tester) async {
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await settle(tester, frames: 16);
  }

  testWidgets('the stats card breaks sales down against the quota', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );

    // StatTile renders value/total as a RichText: sold vs quota.
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Tickets sold'), findsOneWidget);
    expect(find.text('3 / 200', findRichText: true), findsOneWidget);
    expect(find.text('In checkout'), findsOneWidget);
    expect(find.text('2', findRichText: true), findsOneWidget);
  });

  testWidgets('saving without a title is refused before any call', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );

    // Clear the pre-filled title: the trim-empty guard fires first.
    await tester.enterText(find.byType(TextFormField).first, '');
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await settle(tester, frames: 10);

    expect(find.text('Title is required'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('saving an unparseable quota reports the parse error', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );

    // Title field is .first, places field is .at(1) in the tree.
    await tester.enterText(find.byType(TextFormField).at(1), 'not-a-number');
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await settle(tester, frames: 10);

    // The catch-all wraps the FormatException in the generic error toast.
    expect(find.textContaining('An error occurred'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a staged category edit PATCHes only the category endpoint', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );
    stubSaveChain();

    // The row label is numbered per section; the modal fields are numbered
    // after the existing rows, so 'Category 1' is the row's name field.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category 1'),
      'Normal XL',
    );

    await saveAndSettle(tester);

    final categoryBodies = verify(
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: 'evt-1',
            categoryId: 'cat-1',
            body: captureAny(named: 'body'),
          ),
    ).captured;
    expect((categoryBodies.single as CategoryUpdate).name, 'Normal XL');
    // Unchanged items skip their endpoint (original == staged).
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: any(named: 'eventId'),
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    );
    verifyNever(
      () =>
          scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
            eventId: any(named: 'eventId'),
            questionId: any(named: 'questionId'),
            body: any(named: 'body'),
          ),
    );
    // The fan-out ends in the success toast.
    expect(find.text('Success'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a staged session edit PATCHes the session endpoint', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );
    stubSaveChain();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Session 1'),
      'Saturday II',
    );

    await saveAndSettle(tester);

    final sessionBodies = verify(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsSessionIdPatch(
        eventId: 'evt-1',
        sessionId: 'ses-1',
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect((sessionBodies.single as SessionUpdate).name, 'Saturday II');
    expect(
      (sessionBodies.single as SessionUpdate).startDatetime,
      DateTime(2026, 1, 11, 20),
    );
    verifyNever(
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a staged question edit PATCHes the question endpoint', (
    tester,
  ) async {
    // Questions are frozen while sales exist (locked rows ignore edits),
    // so this path needs a sale-free event.
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(withSales: false),
    );
    stubSaveChain();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Question 1'),
      'Allergies (updated)',
    );

    await saveAndSettle(tester);

    final questionBodies = verify(
      () =>
          scaffold.repository.ticketsAdminEventsEventIdQuestionsQuestionIdPatch(
            eventId: 'evt-1',
            questionId: 'q-1',
            body: captureAny(named: 'body'),
          ),
    ).captured;
    expect(
      (questionBodies.single as QuestionUpdate).question,
      'Allergies (updated)',
    );
    verifyNever(
      () => scaffold.repository
          .ticketsAdminEventsEventIdCategoriesCategoryIdPatch(
            eventId: any(named: 'eventId'),
            categoryId: any(named: 'categoryId'),
            body: any(named: 'body'),
          ),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('the start-date row has no field: cancelling keeps the date', (
    tester,
  ) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );
    stubSaveChain();

    // The seeded date is PAINTED as a subtitle, not held in a text field, so
    // there is nothing to clear before saving.
    expect(find.widgetWithText(EditableText, '10/01/2026 18:00'), findsNothing);
    expect(find.text('10/01/2026 18:00'), findsOneWidget);

    // The row's only affordance is the picker; dismissing it writes nothing.
    await scrollTo(tester, find.text('Ticket opening date *'));
    await tester.tap(find.text('Ticket opening date *'));
    await pumpFrames(tester, 10);
    await tester.tap(find.text('Cancel').first);
    await pumpFrames(tester, 10);
    expect(find.text('10/01/2026 18:00'), findsOneWidget);

    await saveAndSettle(tester);
    expect(find.text('Ticketing updated successfully'), findsOneWidget);

    // The save still goes out with the event's own opening date — the empty
    // start-date guard had nothing to fire on, and the row's own format is
    // what the save reads back (an en-locale run used to send 1 October here).
    final body =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdPatch(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as models.EventUpdate;
    expect(body.openDatetime, DateTime(2026, 1, 10, 18));
    await scaffold.drainToast(tester);
  });

  testWidgets('the add-session date is picked, never typed', (tester) async {
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );
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

    final modal = find.byType(BottomModalTemplate);
    // Only the name and the quota are typable; the date is a subtitle row.
    expect(
      find.descendant(of: modal, matching: find.byType(TextFormField)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: modal, matching: find.text('Not set')),
      findsOneWidget,
    );

    // Submitting the name with no date returns before the parse: no POST, and
    // no error toast — the round-trip never has an unparseable string to fail
    // on, which is why the toast below the modal cannot be reached.
    await tester.enterText(
      find.descendant(of: modal, matching: find.byType(TextFormField)).first,
      'Sunday',
    );
    await tester.tap(find.text('Add session').last);
    await pumpFrames(tester, 12);

    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
    expect(find.textContaining('An error occurred'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picked date with a cancelled time keeps the start date', (
    tester,
  ) async {
    // The one sequence the guard could plausibly meet: the date dialog really
    // confirmed, then the time dialog abandoned. `pickFullDate` answers null,
    // so nothing reaches the controller.
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );
    stubSaveChain();

    await scrollTo(tester, find.text('Ticket opening date *'));
    await tester.tap(find.text('Ticket opening date *'));
    await pumpFrames(tester, 12);

    // Confirm the date dialog: it opens on today, so no day has to be picked
    // (and no day of the grid has to be enabled).
    await tester.tap(find.text('OK'));
    await pumpFrames(tester, 14);

    // Abandon the time step.
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester, 14);

    // The row still reads the event's own date: the picked one was discarded
    // with the time, so the save has nothing empty to refuse.
    final row = tester.widget<DateEntry>(find.byType(DateEntry).first);
    expect(row.subtitle, '10/01/2026 18:00');

    await saveAndSettle(tester);
    expect(find.text('Ticketing updated successfully'), findsOneWidget);

    final body =
        verify(
              () => scaffold.repository.ticketsAdminEventsEventIdPatch(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as models.EventUpdate;
    expect(body.openDatetime, DateTime(2026, 1, 10, 18));
    await scaffold.drainToast(tester);
  });

  testWidgets('only the closing date row can read Not set', (tester) async {
    // A fixture without a closing date: the page renders the "Not set" label
    // for the row whose value may be absent. The opening row, seeded from a
    // non-nullable `openDatetime`, shows its date, so the label's absence
    // there is a property of the data, not of the widget.
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );

    DateEntry rowFor(String title) => tester.widget<DateEntry>(
      find.ancestor(of: find.text(title), matching: find.byType(DateEntry)),
    );

    expect(rowFor('Ticket opening date *').subtitle, '10/01/2026 18:00');
    expect(rowFor('Ticketing closing date (optional)').subtitle, 'Not set');
    // The label renders once, on the closing row.
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('the session date is still unset when the time is cancelled', (
    tester,
  ) async {
    // Every way the session date row can end up empty: no pick at all, a date
    // confirmed then its time abandoned. Both leave "Not set", and the submit
    // guard answers before the parse.
    await pumpEdit(
      scaffold,
      tester,
      sellerContainer(scaffold),
      ticketEventFixture(),
    );

    await scrollTo(tester, find.text('Add session'));
    await tester.tap(find.text('Add session'));
    await pumpFrames(tester, 14);

    final modal = find.byType(BottomModalTemplate);
    await tester.enterText(
      find.descendant(of: modal, matching: find.byType(TextFormField)).first,
      'Sunday',
    );

    await tester.tap(
      find.descendant(of: modal, matching: find.byType(DateEntry)),
    );
    await pumpFrames(tester, 12);
    await tester.tap(find.text('OK'));
    await pumpFrames(tester, 14);
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester, 14);

    expect(
      tester
          .widget<DateEntry>(
            find.descendant(of: modal, matching: find.byType(DateEntry)),
          )
          .subtitle,
      'Not set',
    );

    await tester.tap(find.text('Add session').last);
    await pumpFrames(tester, 12);

    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdSessionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
    expect(find.textContaining('An error occurred'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
