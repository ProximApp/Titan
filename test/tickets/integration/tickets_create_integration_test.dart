import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The create page (`/tickets/create`, 180 executable lines) with its
/// TarifCard / SessionCard / extra-question sub-editors.
///
/// The route sits behind the same admin gate as the edit route
/// (AdminMiddleware(canManageTicketEventsProvider)): the seller row must
/// carry canManageEvents, so the scaffold's myStores/storeSellers fakes
/// pin the gate while the page pre-selects the first store.
///
/// The save button sits inside a GestureDetector that unfocuses on tap —
/// after enterText a field holds focus and would swallow the first tap, so
/// the tests unfocus before pressing Save.
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

  Future<void> pumpCreate(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    // ShotgunListNotifier.build() loads the store's event list on mount; if
    // it lands in an error state, ListNotifierAPI.add refuses the create
    // POST ("Cannot add while loading"-class guard) — stub it so the save
    // round-trip reaches the repository.
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/create',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Releases the field focus so the next tap reaches the button instead of
  /// the unfocus GestureDetector around the form.
  Future<void> unfocus(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await unfocus(tester);
    await tester.scrollUntilVisible(
      find.text('Save tickets'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save tickets'));
    await tester.tap(find.text('Save tickets'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the create form renders the store picker and ticket fields', (
    tester,
  ) async {
    final container = sellerContainer();

    await pumpCreate(tester, container);

    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Ticketing title *'), findsOneWidget);
    expect(find.text('Ticket opening date *'), findsOneWidget);
    expect(find.text('Ticketing closing date (optional)'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Add a question'), findsOneWidget);
    expect(find.text('Save tickets'), findsOneWidget);
  });

  testWidgets('a filled form creates the ticketing with converted prices', (
    tester,
  ) async {
    final container = sellerContainer();
    when(
      () =>
          scaffold.repository.ticketsAdminEventsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));

    await pumpCreate(tester, container);

    // Field order on the page: title, quota, start date, end date, then the
    // tariff row (label, price), then the session row (label, date, quota).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Gala 2026');
    await tester.enterText(fields.at(1), '120');
    await tester.enterText(fields.at(2), '10/01/2026 18:00');
    await tester.enterText(fields.at(4), 'Normal');
    await tester.enterText(fields.at(5), '5');
    await tester.enterText(fields.at(6), 'Saturday');
    await tester.enterText(fields.at(8), '100');

    await tapSave(tester);

    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as EventCreate;
    expect(captured.name, 'Gala 2026');
    expect(captured.storeId, 'store-1');
    expect(captured.quota, 120);
    expect(captured.closeDatetime, isNull);
    expect(captured.categories.single.name, 'Normal');
    // The UI works in euros, the backend stores cents.
    expect(captured.categories.single.price, 500);
    expect(captured.sessions.single.name, 'Saturday');
    expect(captured.sessions.single.quota, 100);
    expect(find.text('Ticketing created successfully!'), findsOneWidget);
    // Drain the success toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the extra question section collects typed questions', (
    tester,
  ) async {
    final container = sellerContainer();
    when(
      () =>
          scaffold.repository.ticketsAdminEventsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));

    await pumpCreate(tester, container);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Gala 2026');
    await tester.enterText(fields.at(2), '10/01/2026 18:00');
    await tester.enterText(fields.at(4), 'Normal');
    await tester.enterText(fields.at(6), 'Saturday');

    // Add one extra question and make it required.
    await tester.scrollUntilVisible(
      find.text('Add a question'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Add a question'));
    await tester.tap(find.text('Add a question'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    // The new question card's text field is the page's last one.
    await tester.enterText(find.byType(TextFormField).last, 'Allergies?');
    await tester.tap(find.byType(Checkbox).first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    await tapSave(tester);

    final captured =
        verify(
              () => scaffold.repository.ticketsAdminEventsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as EventCreate;
    final question = captured.questions.single;
    expect(question.question, 'Allergies?');
    expect(question.required, isTrue);
    expect(find.text('Ticketing created successfully!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the save button walks through its validation toasts', (
    tester,
  ) async {
    final container = sellerContainer();

    await pumpCreate(tester, container);

    // Empty form: title comes first.
    await tapSave(tester);
    expect(find.text('Title is required'), findsOneWidget);
    // Drain the error toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Title alone is not enough: categories are validated next.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Gala 2026');
    await tester.enterText(fields.at(2), '10/01/2026 18:00');
    await tapSave(tester);
    expect(find.text('At least one category is required'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    verifyNever(
      () =>
          scaffold.repository.ticketsAdminEventsPost(body: any(named: 'body')),
    );
  });
}
