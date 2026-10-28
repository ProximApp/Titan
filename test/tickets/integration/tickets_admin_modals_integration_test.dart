import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The header's `Admin` button (tickets_main_page.dart:66-100): a bottom
/// modal whose two entries — Create and Manage — route into the admin
/// section. The button renders for every seller who can manage events, but
/// no test ever opened the sheet, so the whole modal body sat at zero.
///
/// Single test on purpose: qlevar 1.12.4 only renders the boot page of the
/// FIRST test in an isolate — later tests keep the first one on screen — so
/// the card-modal half of these sheets lives in
/// `tickets_event_card_actions_integration_test.dart`, which boots
/// `/tickets/manage` in every one of its tests (convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The buttons of whichever bottom modal is open.
  Finder modalButtons() => find.descendant(
    of: find.byType(BottomModalTemplate),
    matching: find.byType(Button),
  );

  testWidgets("the Admin sheet's Create entry routes to the create form", (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    when(() => scaffold.repository.mypaymentUsersMeStoresGet()).thenAnswer(
      (_) async => chopperListResponse(<models.UserStore>[
        models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE'),
      ]),
    );
    when(() => scaffold.repository.ticketsUserMeTicketsGet()).thenAnswer(
      (_) async => chopperListResponse(
        <models.AppCoreTicketsSchemasTicketsTicketComplete>[],
      ),
    );
    // ShotgunListNotifier.build loads this list on the create page mount.
    when(() => scaffold.repository.ticketsEventsGet())
        .thenAnswer((_) async => chopperListResponse(<EventSimple>[]));
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Admin'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    await settle(tester, frames: 10);

    expect(find.byType(BottomModalTemplate), findsOneWidget);
    expect(modalButtons(), findsNWidgets(2));
    expect(find.text('Create a ticketing'), findsOneWidget);
    expect(find.text('Manage association ticketings'), findsOneWidget);

    await tester.tap(find.text('Create a ticketing'));
    await settle(tester, frames: 20);

    // First test in the isolate, so the swap really renders the target.
    expect(QR.currentPath, '/tickets/create');
    expect(find.text('Save tickets'), findsOneWidget);
  });
}
