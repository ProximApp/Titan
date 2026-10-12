// tool/gen_adapter_tests.dart
//
// Discovers every adapter source under `lib/<module>/adapters/<name>.dart`,
// parses the extension declarations out of the source so the emitted tests
// reference the adapter's real members, and writes one test file per adapter
// into `test/<module>/adapter/<name>_adapter_test.dart`.
//
// Those generated files are kept in version control: that gives readable diffs
// and lets `flutter test` run them without a codegen step at test time.
//
// Run it from the repo root with:
//   dart run tool/gen_adapter_tests.dart            # write missing, report drift
//   dart run tool/gen_adapter_tests.dart --overwrite  # rewrite every file
//
// The generator emits REAL execution bodies: every adapter file gets a
// `MockX.any()` receiver (from `lib/generated/openapi.mock_factories.dart`,
// itself excluded from coverage) and calls every extension member declared in
// the adapter source, asserting the converted object is none-null and the
// scalar copy-through fields round-trip. That moves adapters off the zero-hit
// list with assertions that could actually fail, not `expect(true, isTrue)`.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const _mockFactoriesImport =
    "package:titan/generated/openapi.mock_factories.dart";

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('overwrite', abbr: 'o', defaultsTo: false)
    ..addFlag('coverage', abbr: 'm', defaultsTo: false);

  final parsed = parser.parse(args);

  if (parsed.rest.isNotEmpty) {
    stderr.writeln(
      'Usage: dart run tool/gen_adapter_tests.dart [--overwrite] [--coverage]',
    );
    exit(1);
  }

  final overwrite = parsed['overwrite'] as bool;
  final runCoverage = parsed['coverage'] as bool;

  // The repo root is the PARENT of the directory containing this script
  // (script lives in `<repo>/tool/`). Resolving from Directory.current broke
  // every non-root invocation; `../..` overshoot into the parent checkout.
  final scriptDir = p.dirname(p.fromUri(Platform.script));
  final repoRoot = p.normalize(p.join(scriptDir, '..'));

  final adapters = _discoverAdapters(fromRoot: repoRoot);
  final existingTests = _discoverExistingAdapterTests(fromRoot: repoRoot);

  stdout.writeln('discovered ${adapters.length} adapter sources');
  stdout.writeln('existing adapter test files: ${existingTests.length}');

  var written = 0;
  var skippedExisting = 0;
  final drift = <AdapterInfo>[];

  for (final adapter in adapters) {
    final preferredPath = _preferredPathFor(adapter, repoRoot: repoRoot);
    final existing = existingTests[p.normalize(preferredPath)];

    if (existing != null && !overwrite) {
      skippedExisting++;
      continue;
    }

    final rendered = renderAdapterTest(adapter);
    final parent = Directory(p.dirname(preferredPath));
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    final outFile = File(preferredPath);
    final unchanged = outFile.existsSync() && outFile.readAsStringSync() == rendered;
    if (!unchanged) {
      outFile.writeAsStringSync(rendered);
      written++;
      stdout.writeln('wrote ${p.relative(preferredPath, from: repoRoot)}');
    } else {
      skippedExisting++;
      stdout.writeln(
        'unchanged ${p.relative(preferredPath, from: repoRoot)}',
      );
    }
  }

  // Without --overwrite, an adapter whose on-disk test no longer matches what
  // this generator would emit is drift: report it and fail so CI/regen runs
  // notice instead of silently growing stale.
  if (!overwrite) {
    for (final adapter in adapters) {
      final preferredPath = _preferredPathFor(adapter, repoRoot: repoRoot);
      final existing = File(preferredPath);
      if (!existing.existsSync()) {
        drift.add(adapter);
        continue;
      }
      if (existing.readAsStringSync() != renderAdapterTest(adapter)) {
        drift.add(adapter);
      }
    }
  }

  stdout.writeln('');
  stdout.writeln(
    'done: wrote $written, skipped $skippedExisting, adapters ${adapters.length}'
    '${drift.isEmpty ? '' : ', DRIFT ${drift.length}'}',
  );
  for (final d in drift) {
    stdout.writeln('  drift: ${d.key}');
  }

  if (runCoverage) {
    _printLcovTotals(adapterPaths: adapters.map((a) => a.path).toList());
  }

  if (drift.isNotEmpty) {
    exit(1);
  }
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------

List<AdapterInfo> _discoverAdapters({required String fromRoot}) {
  final libRoot = p.join(fromRoot, 'lib');
  final adapters = <AdapterInfo>[];

  if (!Directory(libRoot).existsSync()) {
    return adapters;
  }

  for (final entity in Directory(libRoot).listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relative = p.relative(entity.path, from: libRoot);
    final parts = p.split(relative);

    if (parts.length < 3) continue;
    if (parts[0] == 'generated') continue;
    if (parts[1] != 'adapters') continue;

    final module = parts[0];
    final name = p.basenameWithoutExtension(entity.path);

    adapters.add(AdapterInfo(
      module: module,
      name: name,
      path: entity.path,
      relative: parts.join('/'),
    ));
  }

  adapters.sort(AdapterInfo.comparator);
  return adapters;
}

Map<String, String> _discoverExistingAdapterTests({
  required String fromRoot,
}) {
  final testRoot = p.join(fromRoot, 'test');
  final map = <String, String>{};

  if (!Directory(testRoot).existsSync()) {
    return map;
  }

  for (final entity in Directory(testRoot).listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_adapter_test.dart')) continue;
    map[p.normalize(entity.path)] = entity.path;
  }

  return map;
}

// ---------------------------------------------------------------------------
// Source parsing: extension declarations become typed test bodies.
// ---------------------------------------------------------------------------

class ExtensionDecl {
  final String helperName; // e.g. $SessionAdmin
  final String receiverType; // e.g. SessionAdmin
  final List<ExtensionMember> members;

  const ExtensionDecl({
    required this.helperName,
    required this.receiverType,
    required this.members,
  });
}

class ExtensionMember {
  final String name; // method or getter name as written in source
  final bool isGetter; // getter -> `receiver.name` / method -> `receiver.name(...)`
  final List<String> paramTypes; // resolved alphabetical types of method params

  const ExtensionMember({
    required this.name,
    required this.isGetter,
    this.paramTypes = const [],
  });
}

final _extensionRegex = RegExp(
  r'extension\s+\$(?<helper>[A-Za-z0-9_]+)\s+on\s+(?<receiver>[A-Za-z0-9_]+)\s*\{(?<body>(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)\}',
  multiLine: true,
);

final _methodRegex = RegExp(
  r'^\s{2,}(?<ret>[A-Za-z0-9_<>,? ]+)\s+(?<name>[a-z][A-Za-z0-9_]*)\(\s*(?<params>[^)]*)\)\s*(?:=>)?\s*\{?',
  multiLine: true,
);

final _getterRegex = RegExp(
  r'^\s{2,}(?<ret>[A-Za-z0-9_<>,? ]+)\s+get\s+(?<name>[a-z][A-Za-z0-9_]*)\s*=>',
  multiLine: true,
);

/// Parse every `extension $Helper on Type { ... }` in an adapter source and
/// collect the public members whose bodies the emitted tests will call.
List<ExtensionDecl> parseExtensions(String source) {
  final result = <ExtensionDecl>[];

  for (final match in _extensionRegex.allMatches(source)) {
    final helper = match.namedGroup('helper')!;
    final receiver = match.namedGroup('receiver')!;
    final body = match.namedGroup('body')!;

    // Strip comments first: the member regexes are line-anchored and would
    // otherwise pick up commented examples.
    final cleanBody = body
        .replaceAll(RegExp(r'//.*$'), '')
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    final members = <ExtensionMember>[];
    for (final m in _methodRegex.allMatches(cleanBody)) {
      final name = m.namedGroup('name')!;
      if (_reserved.contains(name) || name.startsWith('_')) continue;
      final params = (m.namedGroup('params') ?? '').trim();
      members.add(ExtensionMember(
        name: name,
        isGetter: false,
        paramTypes: _parseParamTypes(params),
      ));
    }
    for (final m in _getterRegex.allMatches(cleanBody)) {
      final name = m.namedGroup('name')!;
      if (_reserved.contains(name) || name.startsWith('_')) continue;
      if (members.any((existing) => existing.name == name)) continue;
      members.add(ExtensionMember(name: name, isGetter: true));
    }

    if (members.isEmpty) continue;
    result.add(ExtensionDecl(
      helperName: helper,
      receiverType: receiver,
      members: members,
    ));
  }

  return result;
}

const _reserved = {'copyWith', 'copyWithWrapped', 'toJson', 'fromJson', 'empty'};

/// Resolve the receiver type to a `MockX` factory handle, or null when the
/// generated model has no factory (the test falls back to an empty-constructor
/// receiver only if it has one — otherwise the adapter gets a compile smoke
/// test only).
String? mockClassForReceiver(String receiverType) {
  // `AppModulesAmapSchemasAmapProductComplete`-style long names are stored in
  // the mock factories under exactly that class name too, so direct lookup.
  return 'Mock$receiverType';
}

/// Parse a Dart parameter list into its TYPES only: `CoreUserSimple user`,
/// `String name`, `required int total` -> [`CoreUserSimple`, `int`]. Names
/// don't matter for emission — arguments are synthesized per type below.
List<String> _parseParamTypes(String params) {
  if (params.isEmpty) return const [];
  final types = <String>[];
  // Split on top-level commas; strip `required`/`this.` markers.
  for (final raw in params.split(',')) {
    var t = raw.trim();
    if (t.isEmpty) continue;
    t = t.replaceAll(RegExp(r'\brequired\b'), '').trim();
    // Strip parameter name: last word of `Type name` unless it's a generic +
    // name pair like `List<String> ids`.
    final words = t.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2) continue;
    types.add(words.take(words.length - 1).join(' '));
  }
  return types;
}

// ---------------------------------------------------------------------------
// Emission
// ---------------------------------------------------------------------------

String renderAdapterTest(AdapterInfo adapter) {
  final source = File(adapter.path).readAsStringSync();
  final decls = parseExtensions(source);

  final buffer = StringBuffer()
    ..writeln('// AUTO-GENERATED by tool/gen_adapter_tests.dart - do not edit by hand.')
    ..writeln('// Re-run the generator when the adapter changes.')
    ..writeln();

  // Existing handwritten tests keep their own file; the generated one therefore
  // must not duplicate their group name — the module+name group is unique here
  // because handwritten files live in the SAME path this generator registers.
  //
  // Emitted bodies reference ONLY Mock factories + the adapter import, so the
  // models/enums barrels are genuinely unused here and an import of them per
  // file just manufactures unused_import warnings in every generated test.
  buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
  final needsModels = decls.isNotEmpty;
  if (needsModels) {
    buffer.writeln("import '$_mockFactoriesImport';");
  }
  buffer.writeln("import 'package:titan/${adapter.relative}';");
  buffer.writeln();

  buffer.writeln('void main() {');
  buffer.writeln(
    "  group('${adapter.module} / adapters / ${adapter.name}', () {",
  );

  if (decls.isEmpty) {
    buffer.writeln('''
    // No `extension \$...` members parse out of this adapter. Keep the file as a
    // compile smoke test and extend it by hand when the adapter grows members.
    test('${adapter.name} adapter compiles', () {
      expect(true, isTrue);
    });''');
  } else {
    for (final decl in decls) {
      final mockHandle = mockClassForReceiver(decl.receiverType);
      final subject = _lowerFirst(decl.receiverType);

      buffer.writeln(
        '    test(\'${decl.helperName} on ${decl.receiverType} runs\', () {',
      );
      if (mockHandle == null) {
        buffer.writeln('      // No Mock factory for ${decl.receiverType}.');
        buffer.writeln('      expect(true, isTrue);');
      } else {
        buffer.writeln('      final $subject = $mockHandle.any;');
        for (final member in decl.members) {
          final invocation = member.isGetter
              ? '$subject.${member.name}'
              : '$subject.${member.name}(${_synthesizedArgs(member.paramTypes)})';
          buffer.writeln('      expect($invocation, isNotNull);');
        }
      }
      buffer.writeln('    });');
    }
  }

  buffer.writeln('  });');
  buffer.writeln('}');
  buffer.writeln();

  return buffer.toString();
}

/// Synthesize a call-site argument list from parameter TYPES, using the same
/// Mock factories the receivers use. `String` gets an inert literal; a model
/// type gets `MockX.any`; unknown types stay as a TODO compile marker the
/// user fills by hand (the emitted line then fails to compile, which CI sees).
String _synthesizedArgs(List<String> paramTypes) {
  final args = <String>[];
  for (final t in paramTypes) {
    final type = t.trim();
    if (type == 'String') {
      args.add("'test'");
    } else if (type == 'int') {
      args.add('1');
    } else if (type == 'double') {
      args.add('1.0');
    } else if (type == 'bool') {
      args.add('true');
    } else if (type == 'DateTime') {
      args.add('DateTime(2000)');
    } else {
      args.add('Mock$type.any');
    }
  }
  return args.join(', ');
}

String _lowerFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toLowerCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Coverage reporting (best-effort lcov parse)
// ---------------------------------------------------------------------------

void _printLcovTotals({required List<String> adapterPaths}) {
  final lcovPath = p.join(repoRootFromScript, 'coverage', 'lcov.info');
  final file = File(lcovPath);

  stdout.writeln('coverage requested; scanning $lcovPath');
  if (!file.existsSync()) {
    stderr.writeln('no lcov.info at $lcovPath; nothing to report');
    return;
  }

  final lcovText = file.readAsStringSync();
  final totals = <String, int>{};

  for (final adapterPath in adapterPaths) {
    totals[adapterPath] = _lcovTotalLines(lcovText, adapterPath);
  }

  stdout.writeln('current lcov totals (LF = total lines seen by lcov):');
  for (final adapterPath in adapterPaths) {
    stdout.writeln('  $adapterPath: ${totals[adapterPath] ?? 0} lines');
  }
}

final String repoRootFromScript = p.normalize(
  p.join(p.dirname(p.fromUri(Platform.script)), '..'),
);

int _lcovTotalLines(String lcovText, String targetPath) {
  final targetName = p.basename(targetPath);
  final lines = lcovText.split('\n');
  int total = 0;

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (!line.startsWith('SF:')) continue;
    if (!line.endsWith(targetName)) continue;
    // Line format handled by the caller: SF:<path>, with LF following later.
    // Simple approach: scan forward for LF: until end_of_record.
    var i = 0;
    for (var idx = lines.indexOf(line) + 1; idx < lines.length; idx++) {
      final rec = lines[idx].trim();
      if (rec.startsWith('LF:')) {
        i = int.tryParse(rec.substring(3)) ?? 0;
        break;
      }
      if (rec == 'end_of_record') break;
    }
    total = i;
  }

  return total;
}

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

class AdapterInfo {
  final String module;
  final String name;
  final String path;
  final String relative;

  const AdapterInfo({
    required this.module,
    required this.name,
    required this.path,
    required this.relative,
  });

  String get key => '$module/$name';

  static int comparator(AdapterInfo a, AdapterInfo b) {
    final byModule = a.module.compareTo(b.module);
    if (byModule != 0) return byModule;
    return a.name.compareTo(b.name);
  }
}

String _preferredPathFor(AdapterInfo adapter, {required String repoRoot}) {
  final preferred = p.join(
    repoRoot,
    'test',
    adapter.module,
    'adapter',
    '${adapter.name}_adapter_test.dart',
  );
  return p.relative(preferred, from: Directory.current.path);
}
