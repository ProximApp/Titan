import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/flappybird/ui/pages/leaderboard_page/leaderboard_page.dart';
import 'package:titan/mypayment/ui/pages/fund_page/fund_page.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/page_module_guard.dart';

/// The guard in `page_module_guard.dart` fails a test that renders a page
/// from a module other than the one its file lives under, because that is the
/// only shape the qlevar_router leak takes (convention 19): the router's
/// process-global branch hands a deep link a page some earlier test in the
/// same isolate left mounted, so the file under test asserts against nothing
/// and passes anyway.
///
/// A guard nobody has watched fail is a guard nobody knows works, so this file
/// does three things: it checks the index really found the pages the guard
/// claims to police, it checks a genuinely foreign page really is reported,
/// and it checks an allow-listed one really is not.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('the index', () {
    test('finds a page per module and names the declaring file', () {
      final index = pageModuleIndex();

      // The leak the README records came from flappybird's leaderboard
      // rendering inside a /mypayment test, so that pair is the one that has
      // to be in the index for the guard to mean anything.
      final leaderboard = index['LeaderBoardPage'];
      expect(leaderboard, isNotNull, reason: 'the leak page must be indexed');
      expect(leaderboard!.modules, contains('flappybird'));
      expect(leaderboard.declaredIn.single, contains('lib/flappybird/'));
      expect(index['PaymentMainPage']!.modules, contains('mypayment'));
      // Non-page classes are excluded, which is what keeps the shell's own
      // wrappers (AppTemplate, PaymentTemplate) from reading as foreign.
      expect(index.containsKey('AppTemplate'), isFalse);
      expect(index.containsKey('PaymentTemplate'), isFalse);
    });

    test('keeps every module for a name two modules declare', () {
      // Eight modules declare an `AdminPage`. Runtime types carry no library,
      // so the index keeps all eight and the guard treats the name as foreign
      // only when no allowed module declares it — the honest answer to "is a
      // page from somewhere else on screen" for a name that is not unique.
      expect(pageModuleIndex()['AdminPage']!.modules.length, greaterThan(1));
    });
  });

  group('the module under test', () {
    test('is read off the stack, skipping the harness frames', () {
      // A frame list shaped like the real thing: pumpApp in test/shared/,
      // a helper in the file, then the test body.
      expect(
        moduleOfTestFileFrom([
          '#0      IntegrationScaffold.pumpApp '
              '(file:///repo/test/shared/app_scaffold.dart:1:2)',
          '#1      boot (file:///repo/test/mypayment/integration/'
              'mypayment_fund_integration_test.dart:100:3)',
        ]),
        'mypayment',
      );
      // A helper that lives in the harness and is called from a shared
      // fixture cannot name a module, and guessing one would be worse than
      // staying inert.
      expect(
        moduleOfTestFileFrom([
          '#0      bootShared (file:///repo/test/shared/fixtures.dart:9:3)',
        ]),
        isNull,
      );
    });

    test(
      'is this file, and the files that call pumpApp resolve to a module',
      () {
        expect(currentTestModule(), 'tools');
      },
    );
  });

  group('foreignPagesMounted', () {
    testWidgets('reports a page from another module and names the owner', (
      tester,
    ) async {
      // Mounted through the WIDGET shell (no router) precisely so the tree
      // under the guard's feet is exactly this one page and nothing else: the
      // real leak needs a router, and this file must not inherit its rules.
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(tester, const SizedBox.shrink(), container);

      expect(
        foreignPagesMounted(tester, moduleUnderTest: 'mypayment'),
        isEmpty,
        reason: 'an empty tree has nothing to leak',
      );

      // A mypayment page is its own module: allowed, not reported.
      await scaffold.pumpWidgetApp(
        tester,
        const FundPage(),
        container,
        surface: const ui.Size(560, 1000),
      );
      expect(
        foreignPagesMounted(tester, moduleUnderTest: 'mypayment'),
        isEmpty,
      );

      // The flappybird leaderboard is the page convention 19 records showing
      // up inside somebody else's test. Mounted directly here; the router is
      // not needed to reproduce what the guard has to notice.
      await scaffold.pumpWidgetApp(
        tester,
        const Scaffold(body: LeaderBoardPage()),
        container,
        surface: const ui.Size(560, 1000),
      );
      final foreign = foreignPagesMounted(tester, moduleUnderTest: 'mypayment');
      expect(foreign.map((page) => page.name), ['LeaderBoardPage']);
      expect(foreign.single.modules, contains('flappybird'));
    });

    testWidgets('an allowed module silences it, a third module does not', (
      tester,
    ) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const Scaffold(body: LeaderBoardPage()),
        container,
        surface: const ui.Size(560, 1000),
      );

      expect(
        foreignPagesMounted(
          tester,
          moduleUnderTest: 'mypayment',
          allowedModules: {'flappybird'},
        ),
        isEmpty,
        reason: 'a gate-bounce test may legitimately land on another module',
      );
      // Naming the module it expects does not disarm the guard: the leak
      // shows up as a THIRD page, and that still has to fail.
      expect(
        foreignPagesMounted(
          tester,
          moduleUnderTest: 'mypayment',
          allowedModules: {'feed'},
        ),
        isNotEmpty,
      );
    });
  });

  group('assertNoForeignModulePages', () {
    testWidgets('passes on a clean tree', (tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(tester, const SizedBox.shrink(), container);

      expect(
        () => assertNoForeignModulePages(tester, moduleUnderTest: 'mypayment'),
        returnsNormally,
      );
    });

    testWidgets('fails with the class, the owner and the fix', (tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const Scaffold(body: LeaderBoardPage()),
        container,
        surface: const ui.Size(560, 1000),
      );

      // The message is the deliverable: a guard that says "assertion failed"
      // leaves the reader to rediscover the qlevar_router leak from scratch.
      final message = _captureFailure(() {
        assertNoForeignModulePages(
          tester,
          moduleUnderTest: 'mypayment',
          requestedPath: '/mypayment',
        );
      });
      expect(message, contains('LeaderBoardPage'));
      expect(message, contains('test/mypayment/'));
      expect(message, contains('/mypayment'));
      expect(message, contains('flappybird'));
      expect(message, contains('allowedModules'));
    });
  });
}

/// The failure text of a [fail] thrown by [body], without failing the test
/// that is watching the guard.
String _captureFailure(void Function() body) {
  try {
    body();
  } on TestFailure catch (failure) {
    return failure.message ?? '';
  }
  fail('expected the guard to fail, and it did not');
}
