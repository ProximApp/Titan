import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';

import '../../shared/app_scaffold.dart';

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

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
  }

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
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the stats card breaks sales down against the quota', (
    tester,
  ) async {
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

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
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

    // Clear the pre-filled title: the trim-empty guard fires first.
    await tester.enterText(find.byType(TextFormField).first, '');
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

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
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());

    // Title field is .first, places field is .at(1) in the tree.
    await tester.enterText(find.byType(TextFormField).at(1), 'not-a-number');
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

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
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
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
    await pumpEdit(tester, sellerContainer(), ticketEventFixture());
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
      tester,
      sellerContainer(),
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
}
