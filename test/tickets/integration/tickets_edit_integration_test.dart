import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';

import '../../shared/app_scaffold.dart';

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
    expect(find.text('Open'), findsOneWidget);
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
}
