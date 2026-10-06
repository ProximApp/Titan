import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('non-admin deep link to a gated route lands on the feed', (
    tester,
  ) async {
    // Regression test for the redirect loop that used to hang the app: a
    // non-admin deep link to /tombola/detail made AuthenticatedMiddleware
    // forward the path, AdminMiddleware bounce to /, and the auth
    // middleware at / return the forwarded path again — forever. The fix
    // bounces non-admins straight to /feed (a real, always-granted route)
    // instead of the app root: at boot the router history is empty, so a
    // redirect to / was additionally swallowed by the router's same-path
    // guard and the bounce never landed anywhere.
    //
    // The admin middleware is shared by every gated module (raffle, amap,
    // admin, seed-library sub-pages), so this single route exercises the
    // fix for all of them. The admin-side (allowed) case is covered by the
    // admin integration shell's deep-link test.
    //
    // NOTE: qlevar_router 1.12.4 only processes the init-path middleware
    // chain on the first navigation of the isolate; this file therefore
    // holds exactly one deep-link test (see the purchases test NOTE).
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <RaffleComplete>[]),
    );
    when(
      () => scaffold.repository.tombolaUsersUserIdTicketsGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        <AppModulesRaffleSchemasRaffleTicketComplete>[],
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/tombola/detail',
      // The gated-route bounce lands on /feed (with the raffle page behind
      // it in the stack): both are this file's subject.
      allowedModules: const {'feed', 'raffle'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The bounce reaches /feed; QR.currentPath can still report the bounced
    // module's parent because qlevar fires the parent URL update after the
    // redirect. The rendered feed content is the reliable signal.
    expect(find.text('No news available'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
  });
}
