import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/super_admin/ui/components/admin_button.dart';
import 'package:titan/super_admin/ui/components/item_card_ui.dart';
import 'package:titan/super_admin/ui/pages/schools/add_school_page/add_school_page.dart';
import 'package:titan/super_admin/ui/pages/schools/edit_school_page/edit_school_page.dart';
import 'package:titan/super_admin/ui/pages/schools/school_page/school_page.dart';
import 'package:titan/super_admin/ui/pages/schools/school_page/school_ui.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

/// The schools screen and both of its sub-pages in one walk: qlevar's
/// init-path rule only bites on a second, DIFFERENT deep link, and the first
/// mid-test `QR.to` of an isolate is the only one that is guaranteed to run
/// (convention 2) — so all navigation lives in this file's first test.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder schoolIcon(String label, HeroIcons icon) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(SchoolUi)),
    matching: find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == icon,
      description: 'HeroIcon($icon)',
    ),
  );

  testWidgets('the schools screen adds, edits and deletes a school', (
    tester,
  ) async {
    when(() => scaffold.repository.schoolsGet()).thenAnswer(
      (_) async => scaffold.repository.ok([
        CoreSchool.empty().copyWith(
          id: 's1',
          name: 'EFREI',
          // The edit form prefills and validates this field; an empty
          // regex makes validate() reject the save before the PATCH.
          emailRegex: r'^.*@efrei\.fr$',
        ),
      ]),
    );
    // `add()` appends the RESPONSE body, so the stub echoes the school the
    // form posts or the list would gain an unnamed row.
    when(() => scaffold.repository.schoolsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 201),
            CoreSchool.empty().copyWith(id: 's2', name: 'EFREI Paris'),
          ),
        );
    when(
      () => scaffold.repository.schoolsSchoolIdPatch(
        schoolId: any(named: 'schoolId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('body', 200), null),
    );
    when(
      () => scaffold.repository.schoolsSchoolIdDelete(
        schoolId: any(named: 'schoolId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('body', 200), null),
    );

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'sa-1', isSuperAdmin: true),
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/super_admin/schools',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin/schools');
    expect(find.byType(SchoolsPage), findsOneWidget);
    expect(find.text('EFREI'), findsOneWidget);

    // --- add: the plus card routes to the add page, the form posts, and the
    // success path returns to the list with the new school appended.
    final plusIcon = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
      description: 'HeroIcon(plus)',
    );
    await tester.tap(
      find.ancestor(of: plusIcon, matching: find.byType(ItemCardUi)).first,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin/schools/add_school');
    expect(find.byType(AddSchoolPage), findsOneWidget);
    expect(find.text('Add school'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'EFREI Paris');
    await tester.enterText(find.byType(TextFormField).last, r'^.*@efrei\.fr$');
    await tester.tap(find.byType(SuperAdminButton));
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/super_admin/schools');
    expect(find.text('EFREI Paris'), findsOneWidget);

    // --- edit: the eye on the original row routes to the edit page; saving
    // patches the school and the list shows the new name.
    await tester.tap(schoolIcon('EFREI', HeroIcons.eye));
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin/schools/edit_school');
    expect(find.byType(EditSchoolPage), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'EFREI Lyon');
    await tester.tap(find.byType(SuperAdminButton));
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/super_admin/schools');
    expect(find.text('EFREI Lyon'), findsOneWidget);

    // --- delete: the X on the added row asks for confirmation, and the
    // confirmed delete removes it from the list.
    await tester.tap(schoolIcon('EFREI Paris', HeroIcons.xMark));
    await settle(tester, frames: 12);
    expect(find.byType(CustomDialogBox), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 16);
    // The success toast holds a 2.5s PausableTimer; expire it before the
    // binding checks for pending timers at the end of the test.
    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.text('EFREI Paris'), findsNothing);
    expect(find.text('EFREI Lyon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
