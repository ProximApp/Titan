import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The create-page arms the happy-path file cannot reach by typing.
///
/// Every existing test on `/tickets/create` fills the date rows with
/// `enterText`, which is exactly what the rows are NOT for — they are
/// read-only `DateEntry`s whose gesture calls `getFullDate`. So the real
/// dialog pair was never opened from this page, the optional END date was
/// never sent, a date the parser rejects was never submitted, and the
/// question card's answer-type dropdown was never touched. Those are the arms
/// pinned here, each against the captured `EventCreate` rather than a toast.
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
    // ShotgunListNotifier.build() loads the store's event list on mount and
    // the create POST is refused while it is in a loading/error state.
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
    await settle(tester, frames: 12);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await settle(tester, frames: 2);
  }

  Future<void> tapSave(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await scrollTo(tester, find.text('Save tickets'));
    await tester.tap(find.text('Save tickets'));
    await settle(tester, frames: 12);
  }

  /// Taps a date row and OKs through the two real dialogs it opens
  /// (showDatePicker, then showTimePicker).
  Future<void> pickDate(WidgetTester tester, String label) async {
    await scrollTo(tester, find.text(label));
    await tester.tap(find.text(label));
    await settle(tester, frames: 8);
    await tester.tap(find.text('OK').first);
    await settle(tester, frames: 8);
    await tester.tap(find.text('OK').first);
    await settle(tester, frames: 8);
  }

  testWidgets(
    'both date rows open the real pickers and a filled end date is sent',
    (tester) async {
      final container = sellerContainer();
      addTearDown(container.dispose);
      when(
        () => scaffold.repository.ticketsAdminEventsPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));

      await pumpCreate(tester, container);
      final fields = find.byType(TextFormField);

      // The opening row: date dialog then time dialog, both OK'd, and the
      // formatted result lands in the controller.
      await pickDate(tester, 'Ticket opening date *');
      final openedText = tester.widgetList<TextFormField>(fields).isEmpty
          ? null
          : tester
                .widget<EditableText>(find.byType(EditableText).at(2))
                .controller
                .text;
      expect(
        openedText,
        matches(RegExp(r'^\d{1,2}/\d{1,2}/\d{4} \d{2}:\d{2}$')),
        reason: 'the opening row must be written by getFullDate',
      );

      // The closing row takes the same path (its own tap handler).
      await pickDate(tester, 'Ticketing closing date (optional)');

      // Deterministic values for the payload: overwrite both rows, keep the
      // END one non-empty so the optional-close branch is the one exercised.
      await tester.enterText(fields.at(2), '10/01/2026 18:00');
      await tester.enterText(fields.at(3), '10/02/2026 20:00');
      await tester.enterText(fields.at(0), 'Gala 2026');
      await tester.enterText(fields.at(4), 'Normal');
      await tester.enterText(fields.at(5), '5');
      await tester.enterText(fields.at(6), 'Saturday');
      await settle(tester, frames: 4);

      await tapSave(tester);

      final captured =
          verify(
                () => scaffold.repository.ticketsAdminEventsPost(
                  body: captureAny(named: 'body'),
                ),
              ).captured.last
              as EventCreate;
      expect(captured.openDatetime.year, 2026);
      expect(captured.openDatetime.month, 10);
      expect(captured.openDatetime.day, 1);
      expect(captured.closeDatetime, isNotNull);
      expect(captured.closeDatetime!.day, 2);
      expect(captured.quota, isNull);
      expect(find.text('Ticketing created successfully!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );

  testWidgets('an unparseable date is reported and nothing is sent', (
    tester,
  ) async {
    final container = sellerContainer();
    addTearDown(container.dispose);

    await pumpCreate(tester, container);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Gala 2026');
    await tester.enterText(fields.at(2), 'garbage');
    await tester.enterText(fields.at(4), 'Normal');
    await tester.enterText(fields.at(5), '5');
    await tester.enterText(fields.at(6), 'Saturday');
    await settle(tester, frames: 4);

    // Validation passes (the row is non-empty), then DateTime.parse throws:
    // the page's catch turns it into an error toast instead of escaping the
    // button's async body as an unhandled exception.
    await tapSave(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Error'), findsOneWidget);
    verifyNever(
      () =>
          scaffold.repository.ticketsAdminEventsPost(body: any(named: 'body')),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets(
    'the question answer type dropdown changes what is sent, and a blank tap unfocuses',
    (tester) async {
      final container = sellerContainer();
      addTearDown(container.dispose);
      when(
        () => scaffold.repository.ticketsAdminEventsPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponse(EventAdmin.empty()));

      await pumpCreate(tester, container);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Gala 2026');
      await tester.enterText(fields.at(2), '10/01/2026 18:00');
      await tester.enterText(fields.at(4), 'Normal');
      await tester.enterText(fields.at(5), '5');
      await tester.enterText(fields.at(6), 'Saturday');

      await scrollTo(tester, find.text('Add a question'));
      await tester.tap(find.text('Add a question'));
      await settle(tester, frames: 8);
      await scrollTo(tester, find.text('Answer type'));
      await tester.enterText(
        find.byType(TextFormField).last,
        'Combien de personnes ?',
      );

      // The card's dropdown: open it and pick the number type.
      await tester.tap(find.text('Answer type'));
      await settle(tester, frames: 8);
      await tester.tap(find.text('Number').last);
      await settle(tester, frames: 8);

      // A tap on a plain label (no gesture of its own) reaches the form-level
      // GestureDetector, which drops focus from the field being typed in. The
      // label sits above the question card, so it is scrolled into view first
      // (a tap on an off-screen widget is dropped, not delivered).
      await tester.ensureVisible(find.text('Categories'));
      await settle(tester, frames: 4);
      final focusedBefore = tester.binding.focusManager.primaryFocus;
      await tester.tap(find.text('Categories'));
      await settle(tester, frames: 4);
      expect(focusedBefore?.hasFocus, isFalse);

      await tapSave(tester);

      final captured =
          verify(
                () => scaffold.repository.ticketsAdminEventsPost(
                  body: captureAny(named: 'body'),
                ),
              ).captured.last
              as EventCreate;
      final question = captured.questions.single;
      expect(question.question, 'Combien de personnes ?');
      expect(question.answerType, AnswerType.number);
      expect(question.required, isFalse);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
