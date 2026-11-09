import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_page/add_membership_modal.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `AddMembershipModal`, the form the association
/// memberships page opens to create a membership: the name field, the
/// nested group picker (which waits 150ms before opening), and the submit
/// guard — Add must do NOTHING until a group is chosen.
void main() {
  late IntegrationScaffold scaffold;

  final groups = [
    CoreGroupSimple.empty().copyWith(id: 'g1', name: 'BDE'),
    CoreGroupSimple.empty().copyWith(id: 'g2', name: 'BDS'),
  ];

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> openModal(
    WidgetTester tester,
    ProviderContainer container,
    void Function(CoreGroupSimple, String) onSubmit,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      Consumer(
        builder: (context, ref, _) => ElevatedButton(
          onPressed: () => showCustomBottomModal(
            context: context,
            ref: ref,
            modal: AddMembershipModal(
              groups: groups,
              onSubmit: onSubmit,
              ref: ref,
            ),
          ),
          child: const Text('open'),
        ),
      ),
      container,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the name field, the placeholder row and Add', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await openModal(tester, container, (_, _) {});

    expect(find.text('Association memberships management'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(
      find.text('Choose a group to manage this membership'),
      findsOneWidget,
    );
    expect(find.widgetWithText(Button, 'Add'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add without a chosen group never submits', (tester) async {
    var submitted = 0;
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await openModal(tester, container, (_, _) => submitted++);

    await tester.enterText(find.byType(TextFormField), 'Mon asso');
    await tester.tap(find.widgetWithText(Button, 'Add'));
    await tester.pumpAndSettle();

    expect(submitted, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a group in the picker then Add reports both', (
    tester,
  ) async {
    CoreGroupSimple? submittedGroup;
    String? submittedName;
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await openModal(tester, container, (group, name) {
      submittedGroup = group;
      submittedName = name;
    });

    await tester.tap(find.text('Choose a group to manage this membership'));
    // The picker opens after a 150ms delay.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('BDS'), findsOneWidget);

    // Each picker row's + icon is what records the choice.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Choose a group to manage this membership'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Mon asso');
    await tester.tap(find.widgetWithText(Button, 'Add'));
    await tester.pumpAndSettle();

    expect(submittedGroup?.id, 'g1');
    expect(submittedGroup?.name, 'BDE');
    expect(submittedName, 'Mon asso');
    expect(tester.takeException(), isNull);
  });
}
