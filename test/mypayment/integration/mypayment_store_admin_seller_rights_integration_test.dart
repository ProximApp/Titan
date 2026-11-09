import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

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
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse([userStoreFixture]));
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

  /// The signed-in member's own seller row: the rights checkboxes only render
  /// for someone who may manage the store's sellers, and the card they open
  /// must belong to somebody else.
  final managingSeller = sellerFor('user-1', 'Alex', 'Seller').copyWith(
    canManageSellers: true,
  );
  final colleague = sellerFor('user-2', 'Alice', 'Martin');

  Future<void> openRightsOf(WidgetTester tester, String displayName) async {
    await tester.ensureVisible(find.text(displayName));
    await settle(tester, frames: 8);
    await tester.tap(find.text(displayName), warnIfMissed: false);
    await settle(tester, frames: 16);
  }

  testWidgets('toggling a right on a seller card PATCHes the new rights and '
      'says so', (tester) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller, colleague],
      searchResults: [],
    );
    when(
      () => scaffold.repository.mypaymentStoresStoreIdSellersSellerUserIdPatch(
        storeId: any(named: 'storeId'),
        sellerUserId: any(named: 'sellerUserId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await openStoreAdmin(tester);
    await openRightsOf(tester, 'Alice Martin');

    expect(find.text('Rights of Alice Martin'), findsOneWidget);
    // The shipped rights of a colleague: bank only.
    expect(
      tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
      [true, false, false, false, false],
    );

    // i == 1: every other right keeps its own value, which is the arm the
    // five per-right ternaries take when they are not the one being flipped.
    await tester.tap(find.byType(Checkbox).at(1));
    await settle(tester, frames: 24);

    final body =
        verify(
              () => scaffold.repository
                  .mypaymentStoresStoreIdSellersSellerUserIdPatch(
                    storeId: 'store-1',
                    sellerUserId: 'user-2',
                    body: captureAny(named: 'body'),
                  ),
            ).captured.single
            as SellerUpdate;
    expect(body.canBank, isTrue);
    expect(body.canSeeHistory, isTrue);
    expect(body.canCancel, isFalse);
    expect(find.text('Rights updated'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('flipping the bank right turns the others off the same way', (
    tester,
  ) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller, colleague],
      searchResults: [],
    );
    when(
      () => scaffold.repository.mypaymentStoresStoreIdSellersSellerUserIdPatch(
        storeId: any(named: 'storeId'),
        sellerUserId: any(named: 'sellerUserId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await openStoreAdmin(tester);
    await openRightsOf(tester, 'Alice Martin');

    // i == 0 — the only index whose own arm is the true one, so this covers the
    // "keep the other four" companion of the previous test.
    await tester.tap(find.byType(Checkbox).at(0));
    await settle(tester, frames: 24);

    final body =
        verify(
              () => scaffold.repository
                  .mypaymentStoresStoreIdSellersSellerUserIdPatch(
                    storeId: 'store-1',
                    sellerUserId: 'user-2',
                    body: captureAny(named: 'body'),
                  ),
            ).captured.single
            as SellerUpdate;
    expect(body.canBank, isFalse);
    expect(body.canSeeHistory, isFalse);
    await drainToast(tester);
  });

  testWidgets('a refused rights update says so and keeps the sheet', (
    tester,
  ) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller, colleague],
      searchResults: [],
    );
    when(
      () => scaffold.repository.mypaymentStoresStoreIdSellersSellerUserIdPatch(
        storeId: any(named: 'storeId'),
        sellerUserId: any(named: 'sellerUserId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(http.Response('{"detail": "no"}', 500), null),
    );

    await openStoreAdmin(tester);
    await openRightsOf(tester, 'Alice Martin');

    await tester.tap(find.byType(Checkbox).at(1));
    await settle(tester, frames: 30);

    expect(find.text('Error while updating rights'), findsOneWidget);
    // Nothing was recorded as changed, so the sheet stays open on the old
    // rights for a retry.
    expect(find.text('Rights of Alice Martin'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('a refused seller delete says so', (tester) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller, colleague],
      searchResults: [],
    );
    when(
      () => scaffold.repository.mypaymentStoresStoreIdSellersSellerUserIdDelete(
        storeId: any(named: 'storeId'),
        sellerUserId: any(named: 'sellerUserId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(http.Response('{"detail": "no"}', 500), null),
    );

    await openStoreAdmin(tester);
    await openRightsOf(tester, 'Alice Martin');

    await tester.tap(find.text('Delete seller').last);
    await settle(tester, frames: 16);
    expect(find.text('Are you sure you want to delete this seller?'), findsOneWidget);
    await tester.tap(find.widgetWithText(WaitingButton, 'Confirm'));
    await settle(tester, frames: 30);

    expect(find.text('Error while deleting seller'), findsOneWidget);
    await drainToast(tester);
  });


  testWidgets('the rights dialog survives a tap inside and closes on the '
      'backdrop', (tester) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller],
      searchResults: [candidate('user-2', 'Alice', 'Martin')],
    );
    await openStoreAdmin(tester);
    await openSearch(tester);
    await tester.enterText(find.byType(TextFormField), 'ali');
    await settle(tester, frames: 20);
    await tapAddFor(tester, 'Alice Martin');

    expect(find.text('Seller rights'), findsOneWidget);

    // Tapping the sheet's own body is swallowed by the inner detector.
    await tester.tap(find.text('Seller rights'));
    await settle(tester, frames: 8);
    expect(find.text('Seller rights'), findsOneWidget);

    // The dimmed area behind it dismisses without adding anyone.
    await tester.tapAt(const Offset(4, 4));
    await settle(tester, frames: 16);
    expect(find.text('Seller rights'), findsNothing);
    verifyNever(
      () => scaffold.repository.mypaymentStoresStoreIdSellersPost(
        storeId: any(named: 'storeId'),
        body: any(named: 'body'),
      ),
    );
  });


  testWidgets('the other three rights each flip only their own flag', (
    tester,
  ) async {
    stubSellerRights(
      scaffold,
      sellers: [managingSeller, colleague],
      searchResults: [],
    );
    final bodies = <SellerUpdate>[];
    when(
      () => scaffold.repository.mypaymentStoresStoreIdSellersSellerUserIdPatch(
        storeId: any(named: 'storeId'),
        sellerUserId: any(named: 'sellerUserId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      bodies.add(invocation.namedArguments[#body] as SellerUpdate);
      return chopperResponseVoid();
    });

    await openStoreAdmin(tester);
    // The sheet closes after each save, so every right is flipped in its own
    // visit — which is exactly how a seller admin changes them.
    for (final index in [2, 3, 4]) {
      await openRightsOf(tester, 'Alice Martin');
      await tester.tap(find.byType(Checkbox).at(index));
      await settle(tester, frames: 24);
      await drainToast(tester);
    }

    expect(bodies, hasLength(3));
    // Each visit turns exactly one more right on. The list keeps the earlier
    // changes, so the bodies accumulate — and the two rights nobody touched
    // (bank, history) never move.
    expect(bodies[0].canCancel, isTrue);
    expect(bodies[0].canManageSellers, isFalse);
    expect(bodies[0].canManageEvents, isFalse);
    expect(bodies[1].canCancel, isTrue);
    expect(bodies[1].canManageSellers, isTrue);
    expect(bodies[1].canManageEvents, isFalse);
    expect(bodies[2].canCancel, isTrue);
    expect(bodies[2].canManageSellers, isTrue);
    expect(bodies[2].canManageEvents, isTrue);
    for (final body in bodies) {
      expect(body.canBank, isTrue);
      expect(body.canSeeHistory, isFalse);
    }
  });

}
