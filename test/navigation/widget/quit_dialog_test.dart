import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/navigation/providers/display_quit_popup.dart';
import 'package:titan/navigation/ui/quit_dialog.dart';

import '../../shared/app_scaffold.dart';

/// `QuitDialog` is the logout confirm `NavigationTemplate` mounts when
/// `displayQuit` flips (the only live caller of that provider). Confirm runs
/// the REAL logout chain — token deletion through flutter_secure_storage's
/// channel, the firebase-expiration reset, the cache invalidations, a toast
/// and the QR jump to `/login` — so the channel is stubbed hermetically and
/// the dialog itself is pumped routerless. Cancel and a backdrop tap must
/// close it WITHOUT touching the session.
void main() {
  late IntegrationScaffold scaffold;
  late _RecordingRouteMock mock;
  late List<String> deletedSecureKeys;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    mock = _RecordingRouteMock();
    QR.settings.mockRoute = mock;

    deletedSecureKeys = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (call.method == 'delete') {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              deletedSecureKeys.add(args['key'] as String);
            }
            return null;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            null,
          ),
    );
  });

  tearDown(() => QR.settings.mockRoute = null);

  Future<ProviderContainer> pumpQuit(WidgetTester tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    // The template only mounts the dialog while this flag is up.
    container.read(displayQuitProvider.notifier).setDisplay(true);
    await pumpWidgetAt(
      tester,
      const QuitDialog(),
      container: container,
      surface: const ui.Size(600, 900),
      appFonts: true,
    );
    return container;
  }

  testWidgets('Confirm runs the real logout chain and routes to /login', (
    tester,
  ) async {
    final container = await pumpQuit(tester);

    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Do you want to log out?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 8);

    // The session token left through flutter_secure_storage.
    expect(deletedSecureKeys, isNotEmpty);
    expect(container.read(displayQuitProvider), isFalse);
    expect(mock.navigated, contains('/login'));
    // The success toast rides on the title string the dialog itself uses.
    expect(find.text('Success', skipOffstage: false), findsOneWidget);

    // Drain the toast's auto-close timer before the test ends.
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancel closes the dialog without logging out', (tester) async {
    final container = await pumpQuit(tester);

    await tester.tap(find.text('Cancel'));
    await settle(tester, frames: 4);

    expect(container.read(displayQuitProvider), isFalse);
    expect(deletedSecureKeys, isEmpty);
    expect(mock.navigated, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a backdrop tap never logs out', (tester) async {
    await pumpQuit(tester);

    // The dialog's own full-screen backdrop handler wins the hit test here;
    // either it closes the flag or pops the route the dialog sits on — both
    // are "dismissed", and neither may touch the session.
    await tester.tapAt(const Offset(8, 8));
    await settle(tester, frames: 6);

    expect(deletedSecureKeys, isEmpty);
    expect(mock.navigated, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

/// qlevar's test hook target: records every QR.to destination.
class _RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox());
  }
}
