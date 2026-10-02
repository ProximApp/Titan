import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Store-admin seller rights — the module's biggest uncovered cluster.
///
/// `search_result.dart` (83 lines, 0 covered) and `seller_right_dialog.dart`
/// (46, 0 covered) were reachable through exactly one journey: tap "Add
/// seller", type a query, then press the + next to a search result. Nothing in
/// the suite pressed that +, so both files were dead to CI.
///
/// The flow: StoreAdminPage's "Add seller" row flips `isSearching` on, the
/// TextEntry calls `userList.filterUsers(query)` (usersSearchGet),
/// `SearchResult` drops everyone who already sells at the store, and the +
/// opens `SellerRightDialog` with the five `RightCheckBox` rights. "Add"
/// POSTs a `SellerCreation` carrying exactly the ticked rights.
void stubSellerRights(
  IntegrationScaffold scaffold, {
  required List<Seller> sellers,
  required List<CoreUserSimple> searchResults,
  bool createSucceeds = true,
}) {
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse([myPaymentStore]));
  when(
    () => scaffold.repository.mypaymentStoresStoreIdSellersGet(
      storeId: 'store-1',
    ),
  ).thenAnswer((_) async => chopperListResponse(sellers));
  when(
    () => scaffold.repository.usersSearchGet(
      query: any(named: 'query'),
      includedGroups: any(named: 'includedGroups'),
      excludedGroups: any(named: 'excludedGroups'),
      includedAccountTypes: any(named: 'includedAccountTypes'),
      excludedAccountTypes: any(named: 'excludedAccountTypes'),
    ),
  ).thenAnswer((_) async => chopperListResponse(searchResults));
  when(
    () => scaffold.repository.mypaymentStoresStoreIdSellersPost(
      storeId: 'store-1',
      body: any(named: 'body'),
    ),
  ).thenAnswer(
    (_) async => createSucceeds
        ? chopperResponse(Seller.empty())
        : chopper.Response(http.Response('{"detail": "refused"}', 400), null),
  );
}

/// `CoreUserSimple.getName()` is `'$firstname $name'`, so the display name a
/// test asserts on is the pair — not the first name alone.
CoreUserSimple candidate(String id, String firstname, String lastname) =>
    CoreUserSimple.empty().copyWith(
      id: id,
      firstname: firstname,
      name: lastname,
    );

/// The page's `mySellers` lookup reads `seller.user.id`, so every seller in
/// the list needs a real user, not `Seller.empty()`'s blank one.
Seller sellerFor(String id, String firstname, String lastname) => Seller(
  userId: id,
  storeId: 'store-1',
  canBank: true,
  canSeeHistory: false,
  canCancel: false,
  canManageSellers: false,
  canManageEvents: false,
  user: candidate(id, firstname, lastname),
);

final existingSeller = sellerFor('user-1', 'Alex', 'Seller');

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> openStoreAdmin(
    WidgetTester tester, {
    String userId = 'user-1',
  }) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: userId)),
      initialPath: '/mypayment/storeAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.text('Add seller').first);
    await settle(tester, frames: 10);
  }

  /// The search row's NAME is not tappable: `SearchResult` wraps the row in a
  /// GestureDetector with no onTap and hangs the action on the + WaitingButton
  /// at the row's end. Scoping the tap to the row keeps it off the "Add
  /// seller" header's own plus.
  Future<void> tapAddFor(WidgetTester tester, String displayName) async {
    final row = find
        .ancestor(
          of: find.text(displayName),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(
      find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 20);
  }

  /// displayToast arms a 2.5s PausableTimer for its auto-close, and a
  /// PausableTimer is re-armed from an animation frame — one 3s jump leaves
  /// it pending and the test ends with "A Timer is still pending even after
  /// the widget tree was disposed", which then poisons the NEXT test in the
  /// isolate (its toast never arrives). Step through frames instead.
  Future<void> drainToast(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets(
    'the rights dialog adds a seller with exactly the checked rights',
    (tester) async {
      stubSellerRights(
        scaffold,
        sellers: [existingSeller],
        searchResults: [
          candidate('user-2', 'Alice', 'Martin'),
          candidate('user-3', 'Bob', 'Bernard'),
        ],
      );
      await openStoreAdmin(tester);

      // The page needs MY seller row before it renders the list at all.
      expect(find.textContaining('Sellers of'), findsOneWidget);
      await openSearch(tester);
      expect(
        find.text('Alice Martin'),
        findsNothing,
        reason: 'no query typed yet',
      );

      await tester.enterText(find.byType(TextFormField), 'ali');
      await settle(tester, frames: 20);
      verify(
        () => scaffold.repository.usersSearchGet(
          query: 'ali',
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
          includedAccountTypes: any(named: 'includedAccountTypes'),
          excludedAccountTypes: any(named: 'excludedAccountTypes'),
        ),
      ).called(1);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Bob Bernard'), findsOneWidget);
      // ... but Alex, already a seller here, is filtered out of the results.
      expect(find.text('Alex Seller'), findsNothing);

      await tapAddFor(tester, 'Alice Martin');

      // The rights dialog opened with all five rights.
      expect(find.text('Seller rights'), findsOneWidget);
      expect(find.text('Can collect payments'), findsOneWidget);
      expect(find.text('Can view history'), findsOneWidget);
      expect(find.text('Can cancel transactions'), findsOneWidget);
      expect(find.text('Can manage sellers'), findsOneWidget);
      expect(find.text('Can manage ticket events'), findsOneWidget);
      // The shipped default selection is bank-only.
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .map((b) => b.value),
        [true, false, false, false, false],
      );

      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Can cancel transactions'),
      );
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Can manage sellers'),
      );
      await settle(tester, frames: 10);

      await tester.tap(find.widgetWithText(WaitingButton, 'Add'));
      await settle(tester, frames: 30);

      // The POST carries exactly the rights that were ticked.
      final captured =
          verify(
                () => scaffold.repository.mypaymentStoresStoreIdSellersPost(
                  storeId: 'store-1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as SellerCreation;
      expect(captured.userId, 'user-2');
      expect(captured.canBank, isTrue);
      expect(captured.canSeeHistory, isFalse);
      expect(captured.canCancel, isTrue);
      expect(captured.canManageSellers, isTrue);
      expect(captured.canManageEvents, isFalse);

      // Success closes the dialog, clears the search and says so.
      expect(find.text('Seller rights'), findsNothing);
      expect(find.text('Seller added'), findsOneWidget);
      await drainToast(tester);
    },
  );

  testWidgets('a refused creation shows the error toast and keeps the dialog', (
    tester,
  ) async {
    stubSellerRights(
      scaffold,
      sellers: [existingSeller],
      searchResults: [candidate('user-2', 'Alice', 'Martin')],
      createSucceeds: false,
    );
    await openStoreAdmin(tester);
    await openSearch(tester);
    await tester.enterText(find.byType(TextFormField), 'ali');
    await settle(tester, frames: 20);
    await tapAddFor(tester, 'Alice Martin');

    await tester.tap(find.widgetWithText(WaitingButton, 'Add'));
    await settle(tester, frames: 40);

    expect(find.text('Error while adding seller'), findsOneWidget);
    // The dialog stays open so the rights can be corrected and retried.
    expect(find.text('Seller rights'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('closing the search clears the query and the results', (
    tester,
  ) async {
    stubSellerRights(
      scaffold,
      sellers: [existingSeller],
      searchResults: [candidate('user-2', 'Alice', 'Martin')],
    );
    await openStoreAdmin(tester);
    await openSearch(tester);
    await tester.enterText(find.byType(TextFormField), 'ali');
    await settle(tester, frames: 20);
    expect(find.text('Alice Martin'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
    );
    await settle(tester, frames: 20);

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Alice Martin'), findsNothing);
    expect(find.text('Add seller'), findsOneWidget);
  });

  testWidgets(
    'an emptied query clears the results instead of searching again',
    (tester) async {
      stubSellerRights(
        scaffold,
        sellers: [existingSeller],
        searchResults: [candidate('user-2', 'Alice', 'Martin')],
      );
      await openStoreAdmin(tester);
      await openSearch(tester);
      await tester.enterText(find.byType(TextFormField), 'ali');
      await settle(tester, frames: 20);
      expect(find.text('Alice Martin'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '');
      await settle(tester, frames: 20);

      // `clear()` runs, not a second usersSearchGet with an empty query.
      expect(find.text('Alice Martin'), findsNothing);
      verifyNever(
        () => scaffold.repository.usersSearchGet(
          query: '',
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
          includedAccountTypes: any(named: 'includedAccountTypes'),
          excludedAccountTypes: any(named: 'excludedAccountTypes'),
        ),
      );
    },
  );

  testWidgets('a user who is not a seller sees the guard message', (
    tester,
  ) async {
    stubSellerRights(scaffold, sellers: [], searchResults: []);
    await openStoreAdmin(tester, userId: 'outsider');

    expect(find.text('You are not a seller of this store'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
      findsOneWidget,
      reason: 'the add-seller row stays reachable',
    );
  });
}
