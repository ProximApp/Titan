import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';

/// The questions section internals (edit_ticket_event_page's
/// _EditQuestionsSection/_QuestionRow) plus the unlocked-row staging the
/// other edit files skip: add/delete question round-trips AND their failure
/// branches, the answer-type dropdown, the required/activated switches, the
/// unlocked category/session TextEntry onChanged closures and the session
/// row's own date picker. The locked-with-sales render (banners, sold lines)
/// lives in tickets_edit_sections_integration_test.dart — only the row-level
/// inertness (null onChanged/onTap branches) is driven here. Nothing
/// overlaps: the save fan-out PATCHes belong to the residual file.
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
      QuestionAdmin.empty().copyWith(
        id: 'q-1',
        question: 'Allergies?',
        answerType: AnswerType.text,
      ),
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

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
  }

  testWidgets('the add-question modal creates a required paid question', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdQuestionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponse(Question.empty()));

    await scrollTo(tester, find.text('Add a question'));
    await tester.tap(find.text('Add a question'));
    await pumpFrames(tester, 14);

    // The modal form is open (question numbered after the existing one).
    expect(find.text('Question 2'), findsOneWidget);
    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Parking?');
    await tester.enterText(modalFields.at(1), '5');
    // Flip the modal's Required switch on.
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomModalTemplate),
            matching: find.byType(Switch),
          )
          .first,
    );
    await pumpFrames(tester, 4);

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
    // Euros in the form, cents on the wire; text type is the default.
    expect(captured.price, 500);
    expect(captured.required, isTrue);
    expect(captured.answerType, AnswerType.text);
    // The success toast renders through the form context.
    expect(find.text('Ticketing updated successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('question rows stage text, price, type and switches', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

    await scrollTo(tester, find.text('Allergies?'));
    // Staged text + price edits fire the row's onChanged closures.
    await tester.enterText(find.text('Allergies?'), 'Vegan menu?');
    await pumpFrames(tester, 4);
    final questionCard = find
        .ancestor(of: find.text('Vegan menu?'), matching: find.byType(Card))
        .first;
    final rowFields = find.descendant(
      of: questionCard,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(rowFields.at(1), '7');
    await pumpFrames(tester, 4);

    // The answer-type dropdown round-trips a selection.
    await tester.tap(find.byType(DropdownButtonFormField<AnswerType>).first);
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Number').last);
    await pumpFrames(tester, 8);
    expect(find.text('Number'), findsOneWidget);

    // The required + activated switches flip their labels on toggle.
    await tester.tap(
      find.descendant(of: questionCard, matching: find.byType(Switch)).first,
    );
    await pumpFrames(tester, 4);
    await tester.tap(
      find.descendant(of: questionCard, matching: find.byType(Switch)).last,
    );
    await pumpFrames(tester, 4);
    expect(find.text('Question deactivated'), findsOneWidget);
  });

  testWidgets('unlocked category and session rows stage their fields', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

    await scrollTo(tester, find.text('Normal'));
    // The category name field carries the current name; editing it fires the
    // unlocked onChanged closure.
    await tester.enterText(find.text('Normal'), 'New Normal');
    await pumpFrames(tester, 4);

    // The session's own DateEntry opens the real date+time pickers and
    // stages the parsed result (the page-level Date rows are scoped out by
    // the unique subtitle).
    await scrollTo(tester, find.text('11/01/2026 20:00'));
    await tester.tap(find.text('11/01/2026 20:00'));
    await pumpFrames(tester, 8);
    await tester.tap(find.text('OK').first);
    await pumpFrames(tester, 8);
    await tester.tap(find.text('OK').first);
    await pumpFrames(tester, 8);

    // The subtitle no longer holds the initial value: the row's
    // onChanged(session.copyWith(startDatetime: ...)) ran.
    expect(find.text('11/01/2026 20:00'), findsNothing);
  });

  testWidgets('deleting a question confirms, DELETEs and toasts', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      () => scaffold.repository
          .ticketsAdminEventsEventIdQuestionsQuestionIdDelete(
            eventId: any(named: 'eventId'),
            questionId: any(named: 'questionId'),
          ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scrollTo(tester, find.byTooltip('Delete question'));
    await tester.tap(find.byTooltip('Delete question'));
    await pumpFrames(tester, 14);

    expect(find.text('Confirm deletion?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    verify(
      () => scaffold.repository
          .ticketsAdminEventsEventIdQuestionsQuestionIdDelete(
            eventId: 'evt-1',
            questionId: 'q-1',
          ),
    ).called(1);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused question delete names the answers guard', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository
          .ticketsAdminEventsEventIdQuestionsQuestionIdDelete(
            eventId: any(named: 'eventId'),
            questionId: any(named: 'questionId'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response<Question>(
        http.Response('{"detail": "nope"}', 409),
        null,
      ),
    );

    await scrollTo(tester, find.byTooltip('Delete question'));
    await tester.tap(find.byTooltip('Delete question'));
    await pumpFrames(tester, 14);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    expect(find.text('Cannot delete: existing answers'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('failed question/category creations surface the update error', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdQuestionsPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<Question>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );
    when(
      // ignore: void_checks
      () => scaffold.repository.ticketsAdminEventsEventIdCategoriesPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<CategoryComplete>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    // The question modal's error branch.
    await scrollTo(tester, find.text('Add a question'));
    await tester.tap(find.text('Add a question'));
    await pumpFrames(tester, 14);
    final modalFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(modalFields.first, 'Parking?');
    await tester.tap(find.text('Add a question').last);
    await pumpFrames(tester, 16);
    expect(find.text('Cannot update this item'), findsOneWidget);
    await scaffold.drainToast(tester);

    // The category modal's error branch, on the same page.
    await scrollTo(tester, find.text('Add category'));
    await tester.tap(find.text('Add category'));
    await pumpFrames(tester, 14);
    final categoryFields = find.descendant(
      of: find.byType(BottomModalTemplate),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(categoryFields.first, 'VIP');
    await tester.tap(find.text('Add category').last);
    await pumpFrames(tester, 16);
    expect(find.text('Cannot update this item'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('locked rows are inert: taps change nothing', (tester) async {
    await pumpEdit(
      tester,
      sellerContainer(),
      ticketEventFixture(withSales: true),
    );

    // The frozen question row: its field is disabled, the delete button is
    // gone and both switches no-op (their onChanged closures are null).
    expect(find.byTooltip('Delete question'), findsNothing);
    final questionCard = find
        .ancestor(of: find.text('Allergies?'), matching: find.byType(Card))
        .first;
    final questionField = tester.widget<TextFormField>(
      find
          .descendant(of: questionCard, matching: find.byType(TextFormField))
          .first,
    );
    expect(questionField.enabled, isFalse);
    final switchesBefore = find
        .descendant(of: questionCard, matching: find.byType(Switch))
        .evaluate()
        .length;
    expect(switchesBefore, 2);
    await tester.tap(
      find.descendant(of: questionCard, matching: find.byType(Switch)).first,
      warnIfMissed: false,
    );
    await pumpFrames(tester, 4);
    expect(find.text('Question deactivated'), findsNothing);

    // The sold session row: no delete, disabled quota, and the date row
    // never opens a picker (onTap is null).
    expect(find.byTooltip('Delete session'), findsNothing);
    final sessionField = tester.widget<TextFormField>(
      find
          .ancestor(
            of: find.text('Saturday'),
            matching: find.byType(TextFormField),
          )
          .first,
    );
    expect(sessionField.enabled, isFalse);
    await tester.tap(find.text('11/01/2026 20:00'), warnIfMissed: false);
    await pumpFrames(tester, 8);
    expect(find.text('OK'), findsNothing);
    expect(find.text('11/01/2026 20:00'), findsOneWidget);
  });
}
