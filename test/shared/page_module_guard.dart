import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A page class in `lib/`, and the module that declares it.
///
/// Only classes whose NAME ends in `Page` are indexed, which is this
/// codebase's page convention: every routed page is a `*Page`
/// (`PaymentMainPage`, `LeaderBoardPage`, `NoInternetPage`, …) and the
/// components that are legitimately shared across modules end in something
/// else (`PaymentTemplate`, `AppTemplate`, `ModuleCard`). The name suffix is
/// what keeps the navbar and the shell wrappers out of the index — indexing
/// `*Template` would flag every module's shell as foreign to every other.
///
/// Generic names DO collide: eight modules declare an `AdminPage` and five
/// declare a `DetailPage`. Runtime types carry no library, so the index keeps
/// every module that declares a name and treats a mounted name as foreign only
/// when NO module in the allowed set declares it. That is deliberate: the
/// question this guard answers is "is a page from somewhere else on screen",
/// and a name shared by two modules cannot answer the narrower question.
class PageClass {
  const PageClass(this.name, this.modules, this.declaredIn);

  final String name;

  /// Every `lib/<module>/` that declares a class with this name.
  final Set<String> modules;

  /// The files those declarations live in, for the failure message.
  final Set<String> declaredIn;

  @override
  String toString() => '$name (${modules.join('|')})';
}

Map<String, PageClass>? _pageIndex;

/// `class name -> PageClass`, scanned once per isolate.
///
/// Built from the SOURCE rather than from `flutter_test`'s expectations
/// because the alternative — importing every page class to ask whether some
/// name is a page — would pull every module into every test file and undo the
/// module isolation the test tree is built around.
Map<String, PageClass> pageModuleIndex() {
  return _pageIndex ??= _buildPageIndex();
}

Map<String, PageClass> _buildPageIndex() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    throw StateError(
      'pageModuleIndex() needs the package root as its working directory '
      '(looked for ./lib, found nothing). flutter test runs from the package '
      'root, so this means the guard ran under a different cwd.',
    );
  }
  final byName = <String, Set<String>>{};
  final files = <String, Set<String>>{};
  final declaration = RegExp(
    r'^\s*(?:abstract\s+)?class\s+([A-Za-z_0-9]+)\s*(?:<[^>]*>)?\s*'
    r'(?:extends|with|implements|$)',
    multiLine: true,
  );
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final segments = file.path.split(RegExp(r'[/\\]'));
    // lib/<module>/... — a file directly under lib/ (router.dart) belongs to
    // no module, so its classes are indexed under '' and never match a test
    // file's module.
    final module = segments.length > 2 ? segments[1] : '';
    final source = file.readAsStringSync();
    for (final match in declaration.allMatches(source)) {
      final name = match.group(1)!;
      if (!name.endsWith('Page')) continue;
      (byName[name] ??= <String>{}).add(module);
      (files[name] ??= <String>{}).add(file.path);
    }
  }
  return {
    for (final entry in byName.entries)
      entry.key: PageClass(
        entry.key,
        entry.value,
        files[entry.key] ?? const <String>{},
      ),
  };
}

/// The module a test file under `test/<module>/` is about, read off the
/// call stack.
///
/// The harness itself lives in `test/shared/`, and the frames between
/// `pumpApp` and the test body are whatever helpers that file chose to write —
/// so the module has to come from the first frame that is neither the harness
/// nor the package's own `lib/`. That is the same "one page per file" fact the
/// guard exists to enforce, recovered at runtime instead of restated in a
/// parameter on all ~100 shell files.
///
/// Returns null when the stack shows no test file at all (a helper driven from
/// a `test/shared/` fixture, a `test()` with no `testWidgets`), and the guard
/// then stays inert rather than guessing.
String? moduleOfTestFileFrom(Iterable<String> frames) {
  for (final frame in frames) {
    final match = RegExp(r'/test/([A-Za-z_0-9-]+)/').firstMatch(frame);
    if (match == null) continue;
    final module = match.group(1)!;
    if (module == 'shared') continue;
    return module;
  }
  return null;
}

/// [moduleOfTestFileFrom] over the current stack.
String? currentTestModule() =>
    moduleOfTestFileFrom(StackTrace.current.toString().split('\n'));

/// The pages in the mounted tree that belong to no module the caller allows.
///
/// Returns one entry per DISTINCT page class, so a leaked page mounted by the
/// shell's template chain is reported once rather than once per element.
List<PageClass> foreignPagesMounted(
  WidgetTester tester, {
  required String moduleUnderTest,
  Set<String> allowedModules = const {},
}) {
  final allowed = {moduleUnderTest, ...allowedModules};
  final index = pageModuleIndex();
  final found = <String, PageClass>{};
  for (final element in tester.allElements) {
    final name = element.widget.runtimeType.toString();
    final page = index[name];
    if (page == null) continue;
    if (page.modules.any(allowed.contains)) continue;
    found[name] = page;
  }
  return found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

/// Fails the test when a page from another module is on screen.
///
/// Called by [IntegrationScaffold.pumpApp] for every router-driven shell, so
/// the failure lands in the test that rendered the wrong page rather than in
/// whatever test runs next. The bug it closes is convention 19's second leak:
/// qlevar_router keeps the active route branch in process-global state, so a
/// page left mounted by an earlier test in the same isolate can be what a
/// later `/mypayment` deep link actually renders. Every symptom of that is a
/// vacuous test — `find.byType(YourPage)` is 0 while the router log still says
/// `adding Route: .../your/path` — and nothing in flutter_test can see it.
///
/// [allowedModules] is the escape hatch for a test that genuinely crosses
/// modules (a gate bounce proving `/mypayment` lands on `/login`, a redirect
/// test that expects `/feed`). It is explicit per call, and it names MODULES
/// rather than classes, so a third module appearing later still fails.
void assertNoForeignModulePages(
  WidgetTester tester, {
  required String moduleUnderTest,
  Set<String> allowedModules = const {},
  String? requestedPath,
}) {
  final foreign = foreignPagesMounted(
    tester,
    moduleUnderTest: moduleUnderTest,
    allowedModules: allowedModules,
  );
  if (foreign.isEmpty) return;
  final rendered = foreign.map((page) => page.name).join(', ');
  fail(
    'a test under test/$moduleUnderTest/ is rendering pages from another '
    'module: $rendered'
    '${requestedPath == null ? '' : ' (asked for $requestedPath)'}\n'
    'The declared owner(s): ${foreign.map((p) => '${p.name} -> '
        '${p.modules.join("|")} in ${p.declaredIn.join(", ")}').join("; ")}.\n'
    'qlevar_router keeps the active route branch in process-global state, so '
    'a page left mounted by an earlier test in this isolate is what the '
    'router really rendered (convention 19). One router-driven page per '
    'test FILE: move this page into its own file, or, if the test really '
    'expects to land on another module, pass allowedModules: {...} to '
    'pumpApp with the reason in a comment.',
  );
}
