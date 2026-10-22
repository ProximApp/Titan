// One-shot codegen: every generator this repo owns, in dependency order, so
// regenerating the whole project is ONE command:
//
//   dart run tool/codegen.dart
//
// Steps — each is printed as `$ <command>` before it runs, and each is fatal
// on a non-zero exit, because the later steps READ the earlier steps'
// output (running them in isolation is exactly how generated files go stale):
//
//   1. build_runner build         the swagger client, models and enums +
//                                 `.g.dart`, from the spec in swaggers/
//                                 (build.yaml also lists the OpenAPI url as
//                                 an input; the build is cached and
//                                 rewrites nothing when the spec is
//                                 unchanged)
//   2. tool/gen_empty_models.dart injects `static empty()` into every model;
//                                 build_runner cannot do it itself — it
//                                 mutates build_runner's own output
//   3. tool/gen_mock_openapi.dart rewrites test/shared/mock_openapi.dart
//                                 from the freshly generated client (reads
//                                 the checked-in test/generated model factories)
//   4. dart format                steps 2 and 3 emit unformatted source (old
//                                 indent style, over-long lines, a trailing
//                                 blank line) while the committed files are
//                                 formatted — without this pass every regen
//                                 lands as whitespace-only drift
//   5. flutter gen-l10n           lib/l10n/app_localizations*.dart from the
//                                 arbs (untranslated messages land in the
//                                 gitignored missing.txt)
//   6. tool/gen_heroicons.dart    the HeroIcon catalog, rebuilt from the
//                                 heroicons assets named in
//                                 tool/heroicons.yaml — SKIPPED with a note
//                                 when that source checkout is absent, since
//                                 it only changes with the icon version or
//                                 the declared solid styles
//   7. tool/gen_adapter_tests.dart  missing test/<m>/adapter/*_test.dart;
//                                 exits 1 on drift, so stale generated tests
//                                 surface at regen time, not test time
//   8. tool/gen_extension_tests.dart same for test/<m>/extension/*
//   9. dart format                the generated test folders written by
//                                 steps 7–8 (same whitespace contract)
//
// Extra args are forwarded to build_runner (step 1), e.g.:
//
//   dart run tool/codegen.dart --build-filter=lib/generated/**
//
// Deliberately NOT here: tool/subset_font.py and tool/web_icons.sh both need
// arguments or assets from outside the repo (a source TTF, a flavor name), so
// they stay one-off commands; and neither test generator is run with
// --overwrite from this runner — rewriting committed generated files is a
// reviewable decision, not a side effect of regenerating.

import 'dart:io';

Future<void> main(List<String> args) async {
  // 1. The API client itself; every step below post-processes its output.
  await _run('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
    ...args,
  ]);
  // 2. The `empty()` constructors, generated in the production models file.
  await _run('dart', ['run', 'tool/gen_empty_models.dart']);
  // 3. The shared mock of the client every test stubs through.
  await _run('dart', ['run', 'tool/gen_mock_openapi.dart']);
  // 4. Format the generated models and shared client mock.
  await _run('dart', [
    'format',
    'lib/generated/openapi.models.swagger.dart',
    'lib/generated/openapi.models.swagger.g.dart',
    'test/shared/mock_openapi.dart',
  ]);
  // 5. Localizations: the arbs are the source, lib/l10n the build output.
  await _run('flutter', ['gen-l10n']);
  // 6. Icon catalog — conditional on the SVG source the config points at.
  final heroSource = _heroiconsSource();
  if (heroSource != null && heroSource.existsSync()) {
    await _run('dart', ['run', 'tool/gen_heroicons.dart']);
  } else {
    stdout.writeln(
      'SKIP tool/gen_heroicons.dart: no icon source at '
      '${heroSource?.path ?? 'source: in tool/heroicons.yaml'} '
      '(the catalog only changes with the heroicons version or styles)',
    );
  }
  // 7 + 8. Generated TEST files: missing ones are written, drift fails the run.
  await _run('dart', ['run', 'tool/gen_adapter_tests.dart']);
  await _run('dart', ['run', 'tool/gen_extension_tests.dart']);
  // 9. Those write into test/<module>/{adapter,extension}/ — those folders
  // are generator-owned (test/README.md, "Generated adapter & extension
  // tests"), so format the folders they populated.
  final generatedTestDirs = [
    for (final module in Directory('test').listSync().whereType<Directory>())
      for (final sub in ['adapter', 'extension'])
        if (Directory('${module.path}/$sub').existsSync())
          '${module.path}/$sub',
  ];
  await _run('dart', ['format', ...generatedTestDirs]);
}

/// The SVG checkout `tool/gen_heroicons.dart` itself reads from `source:` in
/// tool/heroicons.yaml (typically a pub-cache path, so it may be absent on a
/// machine that never fetched that exact version).
Directory? _heroiconsSource() {
  final config = File('tool/heroicons.yaml');
  if (!config.existsSync()) return null;
  final match = RegExp(
    r'^source:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(config.readAsStringSync());
  if (match == null) return null;
  var path = match.group(1)!;
  if (path.startsWith('~')) {
    path = '${Platform.environment['HOME'] ?? ''}${path.substring(1)}';
  }
  return Directory(path);
}

Future<void> _run(String exe, List<String> args) async {
  stdout.writeln('\$ $exe ${args.join(' ')}');
  final process = await Process.start(
    exe,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) exit(code);
}
