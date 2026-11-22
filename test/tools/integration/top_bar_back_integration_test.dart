import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/rendered_path_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The one ticket the purchases list answers with — enough for the main page
/// to render instead of showing its empty state.
AppModulesCdrSchemasCdrTicket usableTicket() =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: 't-1',
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

/// `TopBar` has two ways to undo a page: the `onBack` a module can pass, and —
/// for the modules that pass none — qlevar's own `QR.back()`. The second arm
/// needs a mounted router, so it is driven here through a real module route:
/// purchases renders `TopBar(root: '/purchases')` with no `onBack`, and its
/// ticket page sits one level below the root.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a module-level chevron without onBack pops through the router', (
    tester,
  ) async {
    when(() => scaffold.repository.cdrUsersMeTicketsGet())
        .thenAnswer((_) async => chopperListResponse([usableTicket()]));
    when(
      () => scaffold.repository.cdrUsersMeTicketsTicketIdSecretGet(
        ticketId: any(named: 'ticketId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(TicketSecret.empty().copyWith(qrCodeSecret: 's')),
    );

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/ticket',
      allowedModules: const {'feed', 'purchases'},
      // The ticket page keeps a spinner up while it waits for a secret, so the
      // mount is pumped by frames rather than settled.
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    // One level below the module root: the chevron is shown, and this TopBar
    // was built without an onBack, so the tap has to reach `QR.back()`.
    final chevron = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.chevronLeft,
    );
    expect(chevron, findsOneWidget);

    await tester.tap(
      find.ancestor(of: chevron, matching: find.byType(IconButton)),
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/purchases');
    expect(container.read(renderedPathProvider), '/purchases');
    // Back on the root: the chevron is hidden again.
    expect(chevron, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
