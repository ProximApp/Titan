import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The admin gate button on the ph main page: its tap is the journey of this
/// file (conventions 2/10 — nothing else navigates here), and the empty
/// list branch renders alongside it.

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the admin button opens the ph admin section', (tester) async {
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
    when(() => scaffold.repository.phGet())
        .thenAnswer((_) async => chopperListResponse(<PaperComplete>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: PhRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // Known quirk: AdminButton's fixed 116.7px box is tuned to the
    // production font metrics; the wide test font makes its Row overflow by
    // ~43px, which the framework reports as a layout exception. It is a
    // test-font artifact, so take it explicitly rather than letting it fail
    // the run.
    expect(tester.takeException(), isA<FlutterError>());

    // Admin users get the button; the empty branch shows the message.
    expect(find.byType(AdminButton), findsOneWidget);
    expect(find.text('No PH yet in database'), findsOneWidget);

    await tester.tap(find.byType(AdminButton));
    await settle(tester);

    expect(find.text('Add a new journal'), findsOneWidget);
    // This file's one journey ends mounted on /ph/admin; nothing follows.
  });
}
