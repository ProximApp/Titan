import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

class MockRepository extends Mock implements Openapi {}

/// The real verifier calls the backend through the repository; the middleware
/// only needs the data branch to decide the app is up to date.
class FakeVersionVerifierNotifier extends VersionVerifierNotifier {
  @override
  AsyncValue<CoreInformation> build() => AsyncValue.data(
    CoreInformation(ready: true, version: '1.0.0', minimalTitanVersionCode: 1),
  );
}

/// The real notifier calls PackageInfo.fromPlatform(), which has no platform
/// channel in tests; the middleware only needs an int to compare against the
/// backend's minimal version.
class FakeTitanVersionNotifier extends TitanVersionNotifier {
  @override
  int build() => 999;
}

/// The real provider derives the session from the OIDC token storage, which
/// does not exist in the test environment; the flow under test needs a user
/// that is already signed in.
class FakeIsLoggedInNotifier extends IsLoggedInProvider {
  @override
  bool build() => true;
}

AppCoreTicketsSchemasTicketsTicketComplete upcomingTicket(String id) =>
    AppCoreTicketsSchemasTicketsTicketComplete.empty().copyWith(
      id: id,
      price: 1500,
      event: EventSimple.empty().copyWith(id: 'event-1', name: 'Gala'),
      category: Category.empty().copyWith(id: 'cat-1', name: 'Normal'),
      session: Session.empty().copyWith(
        id: 'session-1',
        name: 'Vendredi',
        startDatetime: DateTime(2100),
      ),
    );

/// Boots the full real route table through the real Qlevar delegate: real
/// middlewares, real providers, real l10n — only the network edge and the
/// session bootstrap are mocked. This is the same surface the payment deep
/// link travels through.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRepository mockRepository;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedInNotifier.new),
        userProvider.overrideWithValue(CoreUser.empty()),
      ],
    );
  }

  Future<void> pumpTicketsApp(
    WidgetTester tester, {
    String initialPath = '/tickets',
  }) async {
    container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
          routeInformationParser: const QRouteInformationParser(),
          routerDelegate: QRouterDelegate(
            container.read(appRouterProvider).routes,
            initPath: initialPath,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    QR.reset();
    mockRepository = MockRepository();
    // isConnectedProvider hits the same /information endpoint; stub it so any
    // provider watching connectivity sees the backend as reachable.
    when(() => mockRepository.informationGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        CoreInformation(
          ready: true,
          version: '1.0.0',
          minimalTitanVersionCode: 1,
        ),
      ),
    );
  });

  group('Tickets flow', () {
    testWidgets('a signed-in user sees their tickets on the main page', (
      tester,
    ) async {
      final tickets = [upcomingTicket('1'), upcomingTicket('2')];
      when(() => mockRepository.ticketsUserMeTicketsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), tickets),
      );

      await pumpTicketsApp(tester);

      // Page header, section title and both ticket cards from the API.
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('My tickets'), findsOneWidget);
      expect(find.text('Gala'), findsNWidgets(2));
      expect(find.text('15.0€'), findsNWidgets(2));
      verify(
        () => mockRepository.ticketsUserMeTicketsGet(),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('an empty ticket list shows the empty state', (tester) async {
      when(() => mockRepository.ticketsUserMeTicketsGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          <AppCoreTicketsSchemasTicketsTicketComplete>[],
        ),
      );

      await pumpTicketsApp(tester);

      expect(find.text("You don't have any tickets yet"), findsOneWidget);
      expect(find.text('Book your seat for an event!'), findsOneWidget);
    });

    testWidgets('a regular user gets no admin entry point', (tester) async {
      // No stores for this user: canManageTicketEventsProvider resolves to
      // false and the header must not offer the admin button.
      when(() => mockRepository.ticketsUserMeTicketsGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          <AppCoreTicketsSchemasTicketsTicketComplete>[],
        ),
      );
      when(() => mockRepository.mypaymentUsersMeStoresGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), <UserStore>[]),
      );

      await pumpTicketsApp(tester);

      expect(find.text('Admin'), findsNothing);
    });

    testWidgets(
      'the payment-return query param triggers the success toast and is consumed',
      (tester) async {
        when(() => mockRepository.ticketsUserMeTicketsGet()).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            <AppCoreTicketsSchemasTicketsTicketComplete>[],
          ),
        );

        // The user is on the tickets page when the payment platform sends
        // them back; the deep-link handler then forwards the return path
        // with ?code=succeeded while the page is already mounted.
        await pumpTicketsApp(tester);
        expect(find.text('My tickets'), findsOneWidget);

        container
            .read(pathForwardingProvider.notifier)
            .forward('/tickets', queryParameters: {'code': 'succeeded'});
        // The page effect fires on the next frame, toastification inserts
        // the toast on the frame after that and animates it in (~400ms);
        // let the animation run to completion so the toast is laid out.
        await tester.pumpAndSettle();

        expect(find.text('Ticket booked successfully!'), findsOneWidget);
        // The param is consumed so a later rebuild does not re-toast.
        expect(container.read(pathForwardingProvider).queryParameters, isNull);

        // Let the toast auto-close so no timer is left pending.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      },
    );
  });
}
