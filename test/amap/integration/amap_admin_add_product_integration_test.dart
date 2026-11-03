import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../amap_fixtures.dart';
import '../../shared/app_scaffold.dart';

/// The CREATE half of the amap product form, which only ever had its EDIT half
/// driven: the form's whole submit body (`isEdit ? update : add`), the
/// create-category field that only exists when nothing is selected yet, the
/// euros→cents conversion on a typed comma price, and the "list rebuild"
/// branch that create mode runs and edit mode does not.
///
/// Create mode is the state the form is actually used in most of the time, and
/// it is the one branch pair a regression can silently swap: the existing test
/// proves PATCH works, which says nothing about POST.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a new product with a brand-new category posts through the real '
      'endpoint', (tester) async {
    // No products yet, so there are no existing categories to pick from: the
    // form falls back to its create-category field.
    stubAdminLoads(scaffold, products: []);

    ProductSimple? captured;
    when(
      () => scaffold.repository.amapProductsPost(body: any(named: 'body')),
    ).thenAnswer((inv) async {
      captured = inv.namedArguments[#body] as ProductSimple;
      return chopperResponse(
        AppModulesAmapSchemasAmapProductComplete.empty().copyWith(id: 'p-new'),
      );
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin/add_edit_product',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    // Create mode: the submit says Add, and the free-text category field is
    // rendered because "Create category" is the selected dropdown value.
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Create category'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name').first,
      'Cheese',
    );
    // A comma is what a French keyboard produces; the form normalizes it.
    await tester.enterText(
      find.widgetWithText(TextField, 'Price').first,
      '4,50',
    );
    // The category field is the LAST text field (name, price, then category).
    await tester.enterText(find.byType(TextField).last, 'Dairy');
    await settle(tester, frames: 4);

    await tester.tap(find.text('Add'));
    await settle(tester, frames: 16);

    expect(captured, isNotNull);
    expect(captured!.name, 'Cheese');
    // 4,50 € travels as 450 CENTS (the app stores money in cents).
    expect(captured!.price, 450);
    // The typed category wins over the "Create category" placeholder.
    expect(captured!.category, 'Dairy');
    expect(find.text('Product added'), findsOneWidget);
    expect(find.text('Product updated'), findsNothing);

    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('an existing category is sent as-is, without the extra field', (
    tester,
  ) async {
    stubAdminLoads(
      scaffold,
      products: [
        AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          id: 'p-1',
          name: 'Honey jar',
          price: 350,
          category: 'Grocery',
        ),
      ],
    );

    ProductSimple? captured;
    when(
      () => scaffold.repository.amapProductsPost(body: any(named: 'body')),
    ).thenAnswer((inv) async {
      captured = inv.namedArguments[#body] as ProductSimple;
      return chopperResponse(
        AppModulesAmapSchemasAmapProductComplete.empty().copyWith(id: 'p-new'),
      );
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin/add_edit_product',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    // Pick the existing category: this is the dropdown's onChanged, the one
    // arm that rewrites the selected category and clears the free-text field.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester, frames: 8);
    await tester.tap(find.text('Grocery').last);
    await settle(tester, frames: 8);

    // With a real category chosen the create-category field disappears.
    expect(find.widgetWithText(TextField, 'Create category'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name').first,
      'Honey jar 500g',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Price').first,
      '7,00',
    );
    await settle(tester, frames: 4);

    await tester.tap(find.text('Add'));
    await settle(tester, frames: 16);

    expect(captured!.name, 'Honey jar 500g');
    expect(captured!.price, 700);
    expect(captured!.category, 'Grocery');
    expect(find.text('Product added'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('a refused creation toasts the adding error and pops back', (
    tester,
  ) async {
    stubAdminLoads(scaffold, products: []);
    when(() => scaffold.repository.amapProductsPost(body: any(named: 'body')))
        .thenThrow(Exception('product already exists'));

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin/add_edit_product',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name').first,
      'Cheese',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Price').first, '4');
    await tester.enterText(find.byType(TextField).last, 'Dairy');
    await settle(tester, frames: 4);

    await tester.tap(find.text('Add'));
    await settle(tester, frames: 16);

    // The failure arm toasts the adding error and still pops the form.
    expect(find.text('Error while adding'), findsOneWidget);
    expect(find.text('Product added'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
