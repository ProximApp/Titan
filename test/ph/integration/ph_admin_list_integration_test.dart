import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/ph/ui/pages/admin_page/admin_ph_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/card_button.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The admin journal list: year chips toggle the filter, the card body tap
/// and the two card buttons drive the list callbacks, and the trash button
/// confirms through the dialog into `phPaperIdDelete`.
///
/// Order matters (conventions 2/10): the pencil's `QR.to` to the deferred
/// add form is this file's first navigation, so its test runs FIRST; the
/// other two tests only tap in place.

/// The pencil / trash / download buttons are `GestureDetector > CardButton >
/// HeroIcon`; matching on the icon keeps the finder on the exact button.
Finder cardButton(HeroIcons icon) => find.byWidgetPredicate(
  (w) =>
      w is GestureDetector &&
      w.child is CardButton &&
      (w.child as CardButton).child is HeroIcon &&
      ((w.child as CardButton).child as HeroIcon).icon == icon,
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpAdminList(WidgetTester tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: adminPhGroupId,
            name: 'admin_ph',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.phGet()).thenAnswer(
      (_) async => chopperListResponse(<PaperComplete>[
        paperFixture('p1', 'Journal 2026', 2026),
        paperFixture('p2', 'Journal 2025', 2025),
      ]),
    );
    // Without a stub the DELETE throws a MissingStubError inside delete()'s
    // errorWrapper, which answers false and leaves the card on screen.
    when(
      () => scaffold.repository.phPaperIdDelete(paperId: any(named: 'paperId')),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('', 200), null),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhRouter.root}${PhRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);
    return container;
  }

  testWidgets('the pencil opens the add form prefilled with the journal', (
    tester,
  ) async {
    await pumpAdminList(tester);
    expect(find.text('Journal 2026'), findsOneWidget);

    await tester.tap(cardButton(HeroIcons.pencil).first);
    await settle(tester);

    // The form is in edit mode with the tapped journal loaded.
    expect(find.text('Edit PDF file'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Journal 2026'), findsOneWidget);
  });

  testWidgets('year chips filter the list and the card body tap is inert', (
    tester,
  ) async {
    await pumpAdminList(tester);

    // Tapping the card itself runs the empty body callback (line coverage of
    // the card's own GestureDetector) without navigating anywhere.
    final cardRect = tester.getRect(find.byType(AdminPhCard).first);
    await tester.tapAt(cardRect.topLeft + const Offset(15, 15));
    await settle(tester);

    // Add 2025 to the selection, then remove the default 2026.
    await tester.tap(find.text('2025'));
    await settle(tester);
    expect(find.text('Journal 2026'), findsOneWidget);
    expect(find.text('Journal 2025'), findsOneWidget);

    await tester.tap(find.text('2026'));
    await settle(tester);
    expect(find.text('Journal 2026'), findsNothing);
    expect(find.text('Journal 2025'), findsOneWidget);
  });

  testWidgets('the trash button confirms through the dialog and DELETEs', (
    tester,
  ) async {
    await pumpAdminList(tester);

    await tester.tap(cardButton(HeroIcons.trash).first);
    await settle(tester);
    expect(
      find.text('Are you sure you want to delete this journal?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm'));
    await settle(tester);

    verify(() => scaffold.repository.phPaperIdDelete(paperId: 'p1')).called(1);
    // p1 is gone; p2 (2025) still exists but stays hidden behind the
    // default year selection — re-select 2025 to see it.
    expect(find.text('Journal 2026'), findsNothing);
    expect(find.byType(AdminPhCard), findsNothing);
    await tester.tap(find.text('2025'));
    await settle(tester);
    expect(find.text('Journal 2025'), findsOneWidget);
  });
}
