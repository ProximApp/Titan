import 'package:flutter/material.dart' show TextFormField;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/item_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The save handler of `add_edit_item_page`, which the prefill shell never
/// reaches: the four branches of the tap (form invalid → toast, add → POST,
/// edit → PATCH, request failed → error toast) and the add-mode title/button
/// labels. Same deep link for every test — the shape
/// `loan_admin_integration_test` already proves works.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final item = itemFixture(
    id: 'item-1',
    name: 'Tente 2 places',
    loanerId: 'loaner-1',
    totalQuantity: 4,
    loanedQuantity: 1,
    suggestedCaution: 3000,
    suggestedLendingDuration: 3,
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Boots the form with [seed] as the selected item (`Item.empty()` is the
  /// add mode) and the item list resolved to [items] — `ListNotifierAPI`
  /// refuses every mutation while the list is still `loading`.
  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    required Item seed,
    required List<Item> items,
  }) async {
    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse(items));
    // The admin main page mounts underneath the form and its panels
    // auto-load the loan lists for the selected loaner.
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: any(named: 'loanerId'),
        returned: any(named: 'returned'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    container.read(loanerIdProvider.notifier).setId('loaner-1');
    container.read(itemProvider.notifier).setItem(seed);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditItem}',
      pumpAndSettle: false,
    );
    // Three deferred libraries load in sequence (main, admin, form).
    await settle(tester, frames: 40);
    return container;
  }

  Future<void> fillForm(WidgetTester tester) async {
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields, hasLength(4));
    await tester.enterText(find.byType(TextFormField).at(0), 'Marteau');
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    await tester.enterText(find.byType(TextFormField).at(3), '7');
    // Convention 12: unfocus before tapping or the unfocus handler eats the
    // tap.
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
  }

  testWidgets('add mode saves a new object through the POST endpoint', (
    tester,
  ) async {
    await pumpForm(tester, seed: Item.empty(), items: <Item>[]);

    expect(find.text('Add an object'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    var posts = 0;
    ItemBase? posted;
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsPost(
        loanerId: any(named: 'loanerId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      posts++;
      posted = inv.namedArguments[#body] as ItemBase;
      return chopperResponse(item);
    });

    await fillForm(tester);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 30);

    expect(posts, 1);
    expect(posted!.name, 'Marteau');
    expect(posted!.totalQuantity, 2);
    expect(posted!.suggestedCaution, 500);
    expect(posted!.suggestedLendingDuration, 7);
    // QR.back() left the form for the admin page underneath.
    expect(find.text('Add an object'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('edit mode saves the changed fields through the PATCH endpoint', (
    tester,
  ) async {
    await pumpForm(tester, seed: item, items: [item]);

    expect(find.text('Edit the object'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    var patches = 0;
    ItemUpdate? sent;
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsItemIdPatch(
        loanerId: any(named: 'loanerId'),
        itemId: any(named: 'itemId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      patches++;
      sent = inv.namedArguments[#body] as ItemUpdate;
      return chopperResponse(item);
    });

    await fillForm(tester);
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 30);

    expect(patches, 1);
    expect(sent!.name, 'Marteau');
    expect(sent!.totalQuantity, 2);
    await scaffold.drainToast(tester);
  });

  testWidgets('a form the validator rejects sends nothing', (tester) async {
    await pumpForm(tester, seed: item, items: [item]);

    var patches = 0;
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsItemIdPatch(
        loanerId: any(named: 'loanerId'),
        itemId: any(named: 'itemId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      patches++;
      return chopperResponse(item);
    });

    // `isInt: true` refuses the cleared quantity, so Form.validate() fails
    // before any request is built.
    await tester.enterText(find.byType(TextFormField).at(1), '');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 30);

    expect(patches, 0);
    // Still on the form: no QR.back() on the invalid path.
    expect(find.text('Edit the object'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a rejected save stays on the form and keeps the values', (
    tester,
  ) async {
    await pumpForm(tester, seed: item, items: [item]);

    var patches = 0;
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsItemIdPatch(
        loanerId: any(named: 'loanerId'),
        itemId: any(named: 'itemId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      patches++;
      return scaffold.repository.fail<Item>(500);
    });

    await fillForm(tester);
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 30);

    // value == false: the error toast fires and QR.back() does not.
    expect(patches, 1);
    expect(find.text('Edit the object'), findsOneWidget);
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((f) => f.controller?.text),
      ['Marteau', '2', '500', '7'],
    );
    await scaffold.drainToast(tester);
  });
}
