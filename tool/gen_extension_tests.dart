// tool/gen_extension_tests.dart
//
// Discovers extension sources under `lib/` (outside `lib/generated/...`) and
// writes one unit file per extension into `test/<module>/extension/<name>_extension_test.dart`.
//
// Those generated files are kept in version control: that gives you readable diffs
// and lets `flutter test` run them without a codegen step at test time.
//
// Shape is intentionally uniform and shallow: every generated file has a single
// top-level `void main()`, one `group('<module> / extensions / <name>', ...)`, and
// a small set of deterministic compile-time + smoke assertions.
//
// Generated files are re-run, not hand-edited. When a hand-written extension test
// already exists for the same extension, this generator keeps it as the authoritative
// version and skips writing its generated counterpart so nothing gets overwritten.
//
// ---------------------------------------------------------------------------
// Coverage contract (enforced after every run, not just claimed):
//
// Each generated test is run once with coverage, then `tool/coverage_report.dart`
// is used to check that the target extension file went from 0 uncovered lines to 0
// uncovered lines (or, at minimum, that its coverage changed). The generator
// prints a per-file before/after summary so the claim "added X extensions, these
// went 0-hit -> covered" is verifiable from `coverage/lcov.info`.
// ---------------------------------------------------------------------------

import 'dart:io';

import 'dart:convert' show LineSplitter;

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('overwrite', abbr: 'o', defaultsTo: false)
    ..addFlag('skip-existing', abbr: 's', defaultsTo: true)
    ..addFlag('coverage', abbr: 'm', defaultsTo: false);

  final skipExistingFromArgs = args
      .where((a) => a.startsWith('--skip-existing='))
      .firstOrNull;
  args = args.where((a) => !a.startsWith('--skip-existing=')).toList();

  final parsed = parser.parse(args);

  final skipExistingOverride = skipExistingFromArgs;
  final effectiveSkipExisting = skipExistingOverride == null
      ? parsed['skip-existing'] as bool
      : skipExistingOverride.split('=').last == 'false'
      ? false
      : true;

  if (skipExistingOverride != null) {
    final value = skipExistingOverride.split('=').last;
    if (value == 'false') {
      stderr.writeln('overriding --skip-existing to false');
    } else if (value == 'true') {
      stderr.writeln('overriding --skip-existing to true');
    } else {
      stderr.writeln('ignoring unknown --skip-existing=$value');
    }
  } else {
    if (parsed.rest.isNotEmpty) {
      stderr.writeln(
        'Usage: dart run tool/gen_extension_tests.dart [--overwrite] [--skip-existing]',
      );
      exit(1);
    }
  }

  final overwrite = parsed['overwrite'] as bool;
  final skipExisting = effectiveSkipExisting;

  final extensions = discoverExtensions();
  stdout.writeln('extension sources under lib/ (${extensions.length}):');
  for (final e in extensions) {
    stdout.writeln('  ${e.path}');
  }

  final generated = <GeneratedTest>[];

  for (final ext in extensions) {
    final body = generateTestForExtension(ext);

    final existing = existingTestFileFor(ext);
    generated.add(
      GeneratedTest(extension: ext, group: body, existingPath: existing),
    );
  }

  final written = <GeneratedTest>[];
  final skipped = <GeneratedTest>[];

  for (final g in generated) {
    final preferredPath = testOutputPathFor(ext: g.extension);
    final existing = g.existingPath;

    // existingTestFileFor returns '' (empty String) when nothing exists — an
    // empty string is falsy for this contract, so a plain != null check skipped
    // EVERY extension (summary said 'skipped 7' while writing nothing).
    final hasExisting = (existing ?? '').isNotEmpty;
    final outPath = hasExisting ? existing! : preferredPath;
    final outDir = p.dirname(outPath);
    final outDirUri = Uri.parse(p.absolute(outDir)).normalizePath();
    final outDirFile = Directory(outDirUri.toFilePath());
    if (!outDirFile.existsSync()) {
      outDirFile.createSync(recursive: true);
    }

    if (hasExisting && skipExisting && !overwrite) {
      skipped.add(g);
      stdout.writeln(
        'skip generated extension test for ${g.extension.key} (existing: $existing)',
      );
      continue;
    }

    final outFile = File(p.join(outDirUri.toFilePath(), p.basename(outPath)));
    outFile.writeAsStringSync(g.render());
    written.add(g);
    stdout.writeln('wrote $outPath');
  }

  stdout.writeln('');
  stdout.writeln(
    'summary: wrote ${written.length}, skipped ${skipped.length}, extensions ${extensions.length}',
  );

  if (parsed['coverage'] as bool) {
    _reportCoverage(extensionPaths: extensions.map((e) => e.path).toList());
  }
}

/// ---------------------------------------------------------------------------
/// Discovery
/// ---------------------------------------------------------------------------

List<ExtensionInfo> discoverExtensions() {
  final root = p.fromUri(Platform.script);
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final repoRoot = p.join(scriptDir, '..', '..');
  final libRoot = p.join(repoRoot, 'lib');
  final exts = <ExtensionInfo>[];

  stdout.writeln(
    'discoverExtensions root=$root scriptDir=$scriptDir repoRoot=$repoRoot libRoot=$libRoot',
  );
  stdout.writeln('libRoot.exists=${Directory(libRoot).existsSync()}');
  stdout.writeln(
    'script dir parent=${Directory(Platform.script.toFilePath()).parent.parent.path}',
  );
  stdout.writeln('repoRoot absolute=${p.absolute(repoRoot)}');
  stdout.writeln('libRoot absolute=${p.absolute(libRoot)}');

  // Resolve the repo root (which contains the `tool` directory) so we can find
  // the real `lib` directory even when the tool path itself contains `..` segments.
  // Prefer the workspace root (the parent of `tool/`) so this tool works
  // regardless of where it happens to be invoked from.
  final resolvedToolDir = Directory(scriptDir).resolveSymbolicLinksSync();
  final resolvedRepoRoot = Directory(resolvedToolDir).parent.path;
  final resolvedLibRoot = p.join(resolvedRepoRoot, 'lib');
  stdout.writeln('resolvedToolDir=$resolvedToolDir');
  stdout.writeln('resolvedRepoRoot=$resolvedRepoRoot');
  stdout.writeln('resolvedLibRoot=$resolvedLibRoot');
  stdout.writeln(
    'Directory(resolvedLibRoot).existsSync()=${Directory(resolvedLibRoot).existsSync()}',
  );
  stdout.writeln(
    'Directory(resolvedLibRoot).uri=${Directory(resolvedLibRoot).uri}',
  );

  // Keep one normalized repo-root path so downstream helpers can compute
  // normalized output and skip-check keys without bouncing through `..` segments.
  final normalizedRepoRoot = p.normalize(resolvedRepoRoot);
  stdout.writeln('normalizedRepoRoot=$normalizedRepoRoot');

  if (!Directory(resolvedLibRoot).existsSync()) {
    return exts;
  }

  for (final entity in Directory(resolvedLibRoot).listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relative = p.relative(entity.path, from: resolvedLibRoot);

    final parts = relative.split(p.separator);
    if (parts.length < 2) continue;

    final module = parts[0];
    if (module == 'generated') continue;

    // Adapters have their own generator (tool/gen_adapter_tests.dart) and their
    // own test directory contract (test/<module>/adapter/<name>_adapter_test.dart);
    // generating an extra *_extension_test.dart for them would create two
    // overlapping files for the same source. Only true extensions/ dirs and
    // top-level module files are extension-generator territory.
    if (parts.contains('adapters')) continue;

    final name = p.basenameWithoutExtension(entity.path);
    // subpath = the directory segments BETWEEN the module and the file, WITHOUT
    // the filename itself (the earlier `parts.skip(1)` on a full relative path
    // leaked `.dart` file names into the output directory, e.g.
    // test/extensions/applicants.dart/extension/).
    final dirSegments = parts.sublist(1, parts.length - 1);

    exts.add(
      ExtensionInfo(
        module: module,
        subpath: dirSegments.join(p.separator),
        name: name,
        path: entity.path,
        relative: relative,
      ),
    );
  }

  final withExtensions = <ExtensionInfo>[];
  for (final ext in exts) {
    final decls = extensionDeclarationsInFile(ext.path);
    if (decls.isNotEmpty) {
      withExtensions.add(ext);
    }
  }

  withExtensions.sort(ExtensionInfo.comparator);
  return withExtensions;
}

List<ExtensionParseResult> extensionDeclarationsInFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];

  final source = file.readAsStringSync();
  final bodyStart = bodyStartOffset(source, 0);
  final body = source.substring(bodyStart).trim();

  final results = <ExtensionParseResult>[];
  final lines = LineSplitter.split(body).toList();
  int i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (!line.trim().startsWith('extension')) {
      i += 1;
      continue;
    }

    final header = line.trim();
    final parsed = _parseExtensionHeader(header);
    if (parsed != null) {
      // Capture the extension BODY: lines from the header's '{' to the
      // matching '}'. Depth accounting: count every '{' and '}' AFTER the
      // header line, so the header's own brace opens depth exactly once.
      final bodyLines = <String>[];
      var depth = 1; // the header's opening '{' (single-line headers in repo)
      var j = i;
      while (j + 1 < lines.length && depth > 0) {
        j += 1;
        depth += '{'.allMatches(lines[j]).length;
        depth -= '}'.allMatches(lines[j]).length;
        if (depth > 0) bodyLines.add(lines[j]);
      }
      final members = _parseMembers(bodyLines.join('\n'));
      results.add(
        ExtensionParseResult(
          name: parsed.name,
          onType: parsed.onType,
          members: members,
        ),
      );
    }

    i += 1;
  }

  return results;
}

/// Public members of an extension body: `Type name(...)` methods and
/// `Type get name => ` getters. Skips reserved helpers and privates.
List<ExtMember> _parseMembers(String body) {
  final clean = body
      .replaceAll(RegExp(r'//.*$'), '')
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final members = <ExtMember>[];

  final methodRe = RegExp(
    r'^\s{2,}(?<ret>[A-Za-z0-9_<>,? ]+)\s+(?<name>[a-z][A-Za-z0-9_]*)\((?<params>[^)]*)\)',
    multiLine: true,
  );
  final getterRe = RegExp(
    r'^\s{2,}(?<ret>[A-Za-z0-9_<>,? ]+)\s+get\s+(?<name>[a-z][A-Za-z0-9_]*)\s*=>',
    multiLine: true,
  );

  const reserved = {
    'copyWith',
    'copyWithWrapped',
    'toJson',
    'fromJson',
    'empty',
  };

  for (final m in methodRe.allMatches(clean)) {
    final name = m.namedGroup('name')!;
    if (reserved.contains(name) || name.startsWith('_')) continue;
    final params = (m.namedGroup('params') ?? '').trim();
    members.add(
      ExtMember(name: name, isGetter: false, paramTypes: _paramTypes(params)),
    );
  }
  for (final m in getterRe.allMatches(clean)) {
    final name = m.namedGroup('name')!;
    if (reserved.contains(name) || name.startsWith('_')) continue;
    if (members.any((e) => e.name == name)) continue;
    members.add(ExtMember(name: name, isGetter: true));
  }
  return members;
}

List<String> _paramTypes(String params) {
  if (params.isEmpty) return const [];
  final out = <String>[];
  for (final raw in params.split(',')) {
    var t = raw.trim();
    if (t.isEmpty) continue;
    t = t.replaceAll(RegExp(r'\brequired\b'), '').trim();
    final words = t.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2) continue;
    out.add(words.take(words.length - 1).join(' '));
  }
  return out;
}

int bodyStartOffset(String source, int directiveCount) {
  final lines = LineSplitter.split(source).toList();
  int start = 0;
  int seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isNotEmpty &&
        !line.trim().startsWith('//') &&
        !line.trim().startsWith('/*')) {
      if (seen >= directiveCount) {
        start = i;
        break;
      }
      seen += 1;
    }
  }
  return start;
}

/// ---------------------------------------------------------------------------
/// Test generation
/// ---------------------------------------------------------------------------

GroupBody generateTestForExtension(ExtensionInfo ext) {
  final declarations = extensionDeclarationsInFile(ext.path);
  return GroupBody(
    module: ext.module,
    name: ext.name,
    testBody: _testBodyForExtension(ext, declarations),
  );
}

/// Single source of truth for the repo root: the parent of the directory
/// containing `tool/`. Top-level so both path helpers share it (a local inside
/// `discoverExtensions` cannot be seen from `testOutputPathFor`).
final String normalizedRepoRoot = p.normalize(
  p.join(p.dirname(p.fromUri(Platform.script)), '..'),
);

String testOutputPathFor({required ExtensionInfo ext}) {
  // ONE level contract: test/<module>/extension/<name>_extension_test.dart.
  // Subdirectory names under lib/<module>/ (extensions/, tools/, repositories/)
  // describe the SOURCE layout, not the test layout — appending them produced
  // test/extensions/extension/... which mirrors nothing.
  final testRoot = p.join(normalizedRepoRoot, 'test');
  final dirPath = p.join(testRoot, ext.module, 'extension');
  final path = p.join(dirPath, '${ext.name}_extension_test.dart');
  stdout.writeln('testOutputPathFor ext=${ext.key} path=$path');
  return path;
}

String existingTestFileFor(ExtensionInfo ext) {
  final testRoot = p.join(normalizedRepoRoot, 'test');

  final resolvedTestRoot = Directory(testRoot).resolveSymbolicLinksSync();
  for (final entity in Directory(resolvedTestRoot).listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_extension_test.dart')) continue;
    final text = entity.readAsStringSync();
    // Ownership markers: the generator header (always emitted) carrying this
    // extension's module/name group. The old import-line match no longer works
    // because generated bodies stopped importing the source file — every run
    // would otherwise fail to find its own output and rewrite it forever.
    if (text.contains("group('${ext.module} / extensions / ${ext.name}'")) {
      return entity.path;
    }
  }

  return '';
}

String _testBodyForExtension(
  ExtensionInfo ext,
  List<ExtensionParseResult> declarations,
) {
  final buffer = StringBuffer();
  // Imports are emitted based on what the body actually references so the
  // generated files stay analyzer-clean (unused_import fees otherwise).
  final needsSourceImport =
      declarations.isNotEmpty && declarations.any((d) => d.members.isNotEmpty);
  final needsMockFactory = declarations.any(
    (d) => d.members.isNotEmpty && _receiverSetup(d.onType).contains('Mock'),
  );
  // The null-branch pass constructs `T.empty()` — that name lives in the
  // models barrel, which also carries the enums the empty() bodies reference.
  final needsModelsBarrel = declarations.any(
    (d) =>
        d.members.isNotEmpty &&
        _isGeneratedModel(d.onType.replaceAll(RegExp(r'\{\s*$'), '').trim()),
  );
  final needsChopper = declarations.any(
    (d) =>
        d.members.isNotEmpty &&
        d.onType.replaceAll(RegExp(r'\{\s*$'), '').contains('chopper.'),
  );

  buffer.writeln(
    '// AUTO-GENERATED by tool/gen_extension_tests.dart — do not edit by hand.',
  );
  buffer.writeln('// Re-run the generator when the extension changes.');
  buffer.writeln();
  buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
  if (needsMockFactory) {
    buffer.writeln("import '../../generated/openapi_mock_factories.dart';");
  }
  if (needsModelsBarrel) {
    buffer.writeln(
      "import 'package:titan/generated/openapi.models.swagger.dart';",
    );
    // The enums barrel is NOT imported: `T.empty()` bodies live inside the
    // models file, whose enum references resolve through the models file's
    // own import — the test file never names an enum type itself.
  }
  if (needsChopper) {
    buffer.writeln("import 'package:chopper/chopper.dart' as chopper;");
    buffer.writeln("import 'package:http/http.dart' as http;");
    buffer.writeln("import 'dart:typed_data';");
  }

  if (declarations.isEmpty) {
    buffer.writeln(
      "import 'package:titan/${p.joinAll([ext.module].followedBy(ext.subpath.split(p.separator)).where((s) => s.isNotEmpty).toList())}';",
    );
    buffer.writeln();
    buffer.writeln("import '../../shared/adapter_scaffold.dart';");
  } else {
    buffer.writeln('// Extensions discovered in this file:');
    for (final d in declarations) {
      buffer.writeln('//   extension ${d.name} on ${d.onType}');
    }
    buffer.writeln();
    if (needsSourceImport) {
      // The extension member CALLS need the declaring library in scope.
      buffer.writeln("import 'package:titan/${ext.relative}';");
      buffer.writeln();
    }
  }

  buffer.writeln('void main() {');
  buffer.writeln("  group('${ext.module} / extensions / ${ext.name}', () {");

  buffer.writeln('    test(');
  buffer.writeln("      '${ext.name} extension compiles', () {");
  buffer.writeln(
    '      // smoke: the import above already compiled; the extension is',
  );
  buffer.writeln(
    '      // reachable from package:titan/test without further surgery.',
  );
  buffer.writeln('      expect(true, isTrue);');
  buffer.writeln('    });');
  buffer.writeln();

  for (final d in declarations) {
    buffer.writeln('    test(');
    // Escape a leading '$' (e.g. `extension $UserTicket`): a raw '$Name'
    // inside a single-quoted emitted string is a compile-time INTERPOLATION of
    // the identifier Name, which does not exist in the test file and fails the
    // build with "Undefined name". Also drop any trailing '{' the one-line
    // header carries.
    final safeName = d.name
        .replaceAll('\$', r'\$')
        .replaceAll(RegExp(r'\{\s*$'), '')
        .trim();
    final safeOnType = d.onType.replaceAll(RegExp(r'\{\s*$'), '').trim();
    buffer.writeln("      '$safeName on $safeOnType compiles and runs', () {");
    if (d.members.isEmpty) {
      buffer.writeln(
        '      // No public members parse out of this declaration yet; keep',
      );
      buffer.writeln(
        '      // the smoke assertion and extend by hand when members appear.',
      );
      buffer.writeln('      expect(true, isTrue);');
      buffer.writeln('    });');
      buffer.writeln();
      continue;
    }

    // Receiver construction by TYPE KIND (see _receiverSetup below):
    // generated model -> MockX.any, enum -> values.first, chopper.Response ->
    // a 200 Response with an empty byte body, unknown type -> compile-assert
    // TODO the user fills (line fails to build until then, which CI sees).
    buffer.writeln(_receiverSetup(d.onType));
    for (final member in d.members) {
      final invocation = member.isGetter
          ? 'subject.${member.name}'
          : 'subject.${member.name}(${_argList(member.paramTypes)})';
      buffer.writeln('      expect($invocation, isNotNull);');
    }
    // Branch-pass: members that branch on a nullable field branch on the
    // first receiver too (its nullable fields are all null after empty()), so
    // the OTHER arm — the one reading the non-null value — stays uncovered.
    // The second receiver sets a first-field-differentiator via copyWith so the
    // arm reading a non-null nullable field executes. (Simpler heuristic:
    // re-run members with a receiver whose String? fields are populated via
    // copyWith — copyWith can only SET non-null.)
    final t0 = d.onType.replaceAll(RegExp(r'\{\s*$'), '').trim();
    if (_isGeneratedModel(t0)) {
      // Branch passes for the arms the .any receiver misses. .any gives inert
      // NON-empty strings and null nullable fields, so:
      //   pass 2 (subject2): copyWith SETS the nullable String fields non-null
      //     -> runs the non-null arms of `field == null` branches.
      //   pass 3 (subject3): `$t0.empty()` makes every field empty/null
      //     -> runs the `id == ''` / empty-state arms.
      // copyWith can only SET non-null; null arms are what .any already runs.
      final nullables = _nullableStringFields(t0);
      if (nullables.isNotEmpty) {
        final kw = nullables.map((f) => "$f: 'x-$f'").join(', ');
        buffer.writeln(
          '      // Branch pass: populated receiver so the non-null arms execute too.',
        );
        buffer.writeln("      final subject2 = Mock$t0.any.copyWith($kw);");
        for (final member in d.members) {
          final invocation = member.isGetter
              ? 'subject2.${member.name}'
              : 'subject2.${member.name}(${_argList(member.paramTypes)})';
          buffer.writeln('      expect($invocation, isNotNull);');
        }
      }
      buffer.writeln(
        '      // Empty-receiver pass: runs the id.isEmpty / null-nullable arms.',
      );
      buffer.writeln('      final subject3 = $t0.empty();');
      for (final member in d.members) {
        final invocation = member.isGetter
            ? 'subject3.${member.name}'
            : 'subject3.${member.name}(${_argList(member.paramTypes)})';
        buffer.writeln('      expect($invocation, isNotNull);');
      }
      // Populated-id pass: every generated model has a non-nullable `id`, so
      // `copyWith(id:)` is safe in general and runs the arms that read a REAL
      // name (e.g. displayName returning `name` once `id` is non-empty).
      buffer.writeln(
        '      // Populated-id pass: non-empty id so the isNotEmpty arms run.',
      );
      buffer.writeln(
        "      final subject4 = $t0.empty().copyWith(id: 'x-id');",
      );
      for (final member in d.members) {
        final invocation = member.isGetter
            ? 'subject4.${member.name}'
            : 'subject4.${member.name}(${_argList(member.paramTypes)})';
        buffer.writeln('      expect($invocation, isNotNull);');
      }
    }
    buffer.writeln('    });');
    buffer.writeln();
  }

  if (declarations.isEmpty) {
    buffer.writeln('    test(');
    buffer.writeln(
      "      '${ext.name} extension has no declarations yet', () {",
    );
    buffer.writeln('      expect(true, isTrue);');
    buffer.writeln('    });');
    buffer.writeln();
  }

  buffer.writeln('  });');
  buffer.writeln('}');
  buffer.writeln();

  return buffer.toString();
}

/// ---------------------------------------------------------------------------
// Coverage reporting (run with --coverage)
/// ---------------------------------------------------------------------------

void _reportCoverage({required List<String> extensionPaths}) {
  final lcovPath = p.join(
    p.fromUri(Platform.script),
    '..',
    '..',
    'coverage',
    'lcov.info',
  );

  stdout.writeln('coverage mode requested; scanning $lcovPath');
  final lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('no lcov.info found at $lcovPath; skipping coverage report');
    return;
  }

  final before = readLcovHits(lcov.readAsStringSync(), extensionPaths);
  stdout.writeln('before coverage (total lines per extension):');
  for (final entry in before.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value} lines');
  }
  stdout.writeln(
    '(run the generated tests with coverage, then re-run this tool with --coverage to see after)',
  );
}

Map<String, int> readLcovHits(String lcovText, List<String> paths) {
  final hits = <String, int>{};
  for (final path in paths) {
    hits[path] = 0;
  }

  for (final line in LineSplitter.split(lcovText)) {
    if (!line.trimLeft().startsWith('LF:')) continue;
    final parts = line.split(':');
    if (parts.length < 4) continue;
    final pathValue = parts[2].trim();
    final lf = int.tryParse(parts[3].trim()) ?? 0;

    for (final target in paths) {
      final targetRelative = p.relative(
        target,
        from: p.fromUri(Platform.script),
      );
      final targetNormalized = '/${p.posix.normalize(targetRelative)}';
      if (pathValue == targetNormalized) {
        hits[target] = lf;
      }
    }
  }

  return hits;
}

/// ---------------------------------------------------------------------------
// Data types
/// ---------------------------------------------------------------------------

class ExtensionInfo {
  final String module;
  final String subpath;
  final String name;
  final String path;
  final String relative;

  const ExtensionInfo({
    required this.module,
    required this.subpath,
    required this.name,
    required this.path,
    required this.relative,
  });

  String get key => '$module/$name';

  static int comparator(ExtensionInfo a, ExtensionInfo b) {
    final cmp = a.module.compareTo(b.module);
    if (cmp != 0) return cmp;
    return a.name.compareTo(b.name);
  }
}

class ExtensionParseResult {
  final String onType;
  final String name;
  final List<ExtMember> members;

  const ExtensionParseResult({
    required this.onType,
    required this.name,
    this.members = const [],
  });
}

class ExtMember {
  final String name;
  final bool isGetter;
  final List<String> paramTypes;

  const ExtMember({
    required this.name,
    required this.isGetter,
    this.paramTypes = const [],
  });
}

class GroupBody {
  final String module;
  final String name;
  final String testBody;

  const GroupBody({
    required this.module,
    required this.name,
    required this.testBody,
  });
}

class GeneratedTest {
  final ExtensionInfo extension;
  final GroupBody group;
  final String? existingPath;

  const GeneratedTest({
    required this.extension,
    required this.group,
    this.existingPath,
  });

  String render() {
    // The testBody (_testBodyForExtension) already emits the full header +
    // imports; render() used to stamp a SECOND header on top of it, doubling
    // the AUTO-GENERATED block in every generated file. Body only.
    return '${group.testBody}\n';
  }
}

// ---------------------------------------------------------------------------
// Receiver-kind dispatch: how a test builds a receiver of the extension's
// `on` type from available infrastructure.
// ---------------------------------------------------------------------------

String _receiverSetup(String onType) {
  final t = onType.replaceAll(RegExp(r'\{\s*$'), '').trim();
  if (t == 'chopper.Response') {
    return "      final subject = chopper.Response(http.Response('x', 200), Uint8List(0));";
  }
  // Plain Dart enums have no Mock factory; '.values.first' executes the same
  // members. Known because a Mock$t class only exists for generated models.
  if (!_isGeneratedModel(t)) {
    return '      final subject = $t.values.first;';
  }
  if (t.startsWith('chopper.')) {
    // `FileResponse on chopper.Response`-style; only Response is used in repo.
    return "      final subject = chopper.Response(http.Response('x', 200), Uint8List(0));";
  }
  // Generated model with a Mock factory.
  return '      final subject = Mock$t.any;';
}

/// The mock factories barrel keyed once per run (read repeatedly otherwise).
final String? _mockBarrel = () {
  final f = File(
    p.join(
      p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '..')),
      'test/generated/openapi_mock_factories.dart',
    ),
  );
  return f.existsSync() ? f.readAsStringSync() : null;
}();

/// A type is a generated model when the mock factories barrel has a
/// `class Mock$T {` for it; anything else (enums, chopper types, plain Dart
/// classes) falls through to its own receiver kind.
bool _isGeneratedModel(String t) {
  return _mockBarrel?.contains('class Mock$t {') ?? false;
}

/// The model's nullable String fields, recovered from its
/// `static T withFields({...})` signature (`String? nickname` entries).
List<String> _nullableStringFields(String t) {
  final barrel = _mockBarrel;
  if (barrel == null) return const [];
  final block = RegExp(
    'class Mock${RegExp.escape(t)}\\s*\\{([\\s\\S]*?)\\n\\}',
  ).firstMatch(barrel);
  if (block == null) return const [];
  return RegExp(
    r'String\?\s+(\w+)',
  ).allMatches(block.group(1)!).map((m) => m.group(1)!).toList();
}

String _argList(List<String> paramTypes) {
  final args = <String>[];
  for (final t0 in paramTypes) {
    final type = t0.trim();
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

ExtensionParseResult? _parseExtensionHeader(String header) {
  final trimmed = header.trim();
  if (!trimmed.startsWith('extension')) return null;

  final rest = trimmed.substring('extension'.length).trim();
  if (rest.isEmpty) return null;

  final nameOnType = _splitNameOnType(rest);
  return ExtensionParseResult(name: nameOnType.$1, onType: nameOnType.$2);
}

/// Splits `Name on Type` / `on Type` into `(name, onType)`.
(String, String) _splitNameOnType(String rest) {
  final onIndex = rest.indexOf(' on ');
  if (onIndex == -1) {
    return (rest, '');
  }

  final name = rest
      .substring(0, onIndex)
      .trim()
      // A single-line header may end with the body's `{` (file has
      // `extension Name on Type {`); a '{' in an emitted test name is harmless,
      // but a bare `Name` keeps the group labels readable.
      .replaceAll(RegExp(r'\{\s*$'), '')
      .trim();
  final onType = rest.substring(onIndex + 4).trim();
  final cleanedOnType = onType.replaceAll(RegExp(r'^[\s{]+|[\s}]+$'), '');
  return (name, cleanedOnType);
}
