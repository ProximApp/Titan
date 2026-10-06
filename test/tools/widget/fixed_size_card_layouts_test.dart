import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../shared/fixed_size_card_fixtures.dart';
import '../../shared/fixed_width_card_detector.dart';

/// The mount ratchet for every card that pins its own size through
/// `CardLayout`.
///
/// `fixed_width_cards_test.dart` (ledger #47) is the standing sweep for a card
/// that hardcodes a width beside flex children IN THE SAME FILE. This is its
/// blind spot, closed: `CardLayout(width: 140, height: 80)` fixes a width just
/// as hard, but the number is a constructor ARGUMENT, so there is no
/// `SizedBox` for the detector to find. loan's `ItemCardInLoan` is a real
/// pinned 80px box that way, and so is amap's `UserCashUiLayout` at 150x100.
///
/// The rule it enforces is the only one that matters for a regression: a
/// widget class that pins a dimension and is mounted by NO widget test is a
/// card whose layout has never been measured at phone width. This fails on
/// the candidate rather than on the overflow, which means it catches the card
/// the day it is written — long before the string that breaks it exists.
void main() {
  /// The candidates that cannot be mounted here, each with the reason —
  /// the map itself lives in `test/shared/fixed_size_card_fixtures.dart`
  /// (`cardLayoutNotMountedExemptions`) so the mount audit can attempt a
  /// real mount of every entry; this alias keeps the ratchet local.
  const notMounted = cardLayoutNotMountedExemptions;

  /// Every `test/**/widget/*.dart` file, plus the shared card-fixture
  /// registry, with comments and string literals removed.
  ///
  /// `test/shared/card_fixtures.dart` counts because it IS the widget level:
  /// ledger #62 moved the two fixed-size sweeps' builders out of
  /// `fixed_width_cards_test.dart` into that one registry so the width and
  /// height families could not drift into two copies of the same fixture. The
  /// sweeps still mount every card in it, at 360px, with overflows fatal — so
  /// a card named there really is mounted, and the alternative (leaving the
  /// registry out) would report eight real cards as unmounted and teach the
  /// next person to distrust this ratchet.
  ///
  /// Stripping strings is what keeps the sweep's `_notMounted` map from
  /// counting as a mount: its keys and reasons are strings that quote class
  /// names (`'… OrderSection'`), and an import path is a string too. Neither
  /// puts a class name before a `(`, so the strip is belt-and-braces — but
  /// the sweep is edited by hand and the exemption reasons grow, so the
  /// check should not depend on that holding.
  List<String> widgetTestSources() {
    final testDir = Directory('test');
    expect(
      testDir.existsSync(),
      isTrue,
      reason: 'run this from the package root: no test/ directory here',
    );
    const sharedRegistry = 'test/shared/card_fixtures.dart';
    final out = <String>[];
    for (final file in testDir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/widget/') && path != sharedRegistry) continue;
      out.add(_stripped(file.readAsStringSync()));
    }
    return out;
  }

  /// A candidate counts as mounted when a widget test BUILDS it or FINDS it:
  /// a constructor call (`DetailOrderUI(`, `MemberCard(`) or a
  /// `find.byType(DetailOrderUI)`. Anything weaker — an import, a mention in
  /// a comment, a class name in prose — is not a measurement.
  bool isMounted(String className, List<String> sources) {
    final built = RegExp('\\b${RegExp.escape(className)}\\s*\\(');
    final found = RegExp(
      'find\\.byType\\(\\s*${RegExp.escape(className)}\\s*\\)',
    );
    return sources.any((s) => built.hasMatch(s) || found.hasMatch(s));
  }

  test('the ratchet has candidates to check', () {
    // Without this, a detector that silently stopped finding anything would
    // turn every other assertion below into a pass.
    expect(
      findFixedSizeCardLayouts(),
      isNotEmpty,
      reason:
          'the detector found no fixed-size CardLayout under lib/, so the '
          'ratchet below cannot fail for anything',
    );
  });

  test(
    'every fixed-size CardLayout is mounted by a widget test, or exempted',
    () {
      final sources = widgetTestSources();
      final uncovered = findFixedSizeCardLayouts()
          .where(
            (c) =>
                !isMounted(c.className, sources) &&
                !notMounted.containsKey('${c.source} ${c.className}'),
          )
          .toList();

      expect(
        uncovered,
        isEmpty,
        reason:
            'these cards pin a CardLayout dimension but no test/**/widget/ '
            'file mounts them, so their layout has never been measured at 360px. '
            'Mount one, or add an entry to `notMounted` in '
            'test/tools/widget/fixed_size_card_layouts_test.dart saying why. '
            'The uncovered candidates are listed above; the full list with '
            'pinned dimensions is `findFixedSizeCardLayouts()` in '
            'test/shared/fixed_width_card_detector.dart.',
      );
    },
  );

  test('every exemption says why the card cannot be mounted', () {
    expect(
      notMounted.values.where((r) => r.trim().isEmpty),
      isEmpty,
      reason:
          'an exemption with no reason is a silent hole: it looks like '
          'coverage and is not',
    );
  });

  test('no exemption names a card the detector no longer finds', () {
    // A stale key means the card was renamed, moved or de-pinned, and the
    // exemption quietly stopped being about anything.
    final found = findFixedSizeCardLayouts()
        .map((c) => '${c.source} ${c.className}')
        .toSet();
    expect(
      notMounted.keys.where((k) => !found.contains(k)),
      isEmpty,
      reason:
          'these exemptions do not match any candidate the detector '
          'finds; either the card moved or it stopped pinning a dimension, '
          'and the entry should go',
    );
  });

  test('no exemption names a widget a widget test really mounts', () {
    // The scan-side twin of mounted_but_exempted_ratchet_test.dart: that
    // ratchet catches the REGISTRY overlap (cardFixtures entry + exemption),
    // this one catches constructor evidence anywhere under test/**/widget/
    // — a widget file that builds the class is a real mount, and an
    // exemption claiming it cannot be mounted is then stale (the ModuleCard
    // reason was simply false). Exemption reasons are prose; mounts are
    // code, and code wins.
    final sources = widgetTestSources();
    String classNameOf(String key) => key.substring(key.lastIndexOf(' ') + 1);

    final registeredAndExempted = <String>[
      for (final key in notMounted.keys)
        if (isMounted(classNameOf(key), sources))
          'fixed_size_card_layouts notMounted: $key',
      for (final key in notMountedExemptions.keys)
        if (isMounted(classNameOf(key), sources)) 'notMountedExemptions: $key',
    ];

    expect(
      registeredAndExempted,
      isEmpty,
      reason:
          'these widgets are exempted as unmountable while a widget test '
          'file really constructs or finds them — the exemption is stale, '
          'and a stale reason is how ModuleCard hid at 37/37. Delete the '
          'exemption (the mount already exists) or stop mounting it. '
          'Offenders: $registeredAndExempted',
    );
  });

  test('the detector still finds the 25 candidates it was pinned to', () {
    // The Python twin this once cross-checked against (`tool/detect_fixed_
    // size_card_layouts.py`) was deleted in ledger #62, and the count pin
    // stayed behind as the only guard in this direction: the mount ratchet
    // above checks the candidates that come back, so a scan that silently
    // started finding FEWER — a regex that stops matching, a class the
    // declaration pattern no longer catches — would leave it green. A new
    // pinned CardLayout lands here too; bump the number only together with
    // mounting it or exempting it above.
    expect(findFixedSizeCardLayouts().length, 25);
  });
}

/// Removes `//` line comments, `/* */` block comments, and the contents of
/// `'...'`, `"..."` and `'''...'''` string literals.
///
/// Comments are removed before strings so a lone apostrophe in prose cannot
/// swallow the rest of the file. Escapes are honoured inside quoted strings;
/// raw and triple-quoted raw strings are treated as plain quoted, which is
/// good enough because the text being scanned is hand-written test source.
String _stripped(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final two = i + 1 < source.length ? source.substring(i, i + 2) : '';
    if (two == '//') {
      final end = source.indexOf('\n', i);
      i = end == -1 ? source.length : end;
      continue;
    }
    if (two == '/*') {
      final end = source.indexOf('*/', i + 2);
      i = end == -1 ? source.length : end + 2;
      continue;
    }
    final c = source[i];
    if (c == "'" || c == '"') {
      final triple = source.startsWith(c * 3, i);
      final terminator = triple ? c * 3 : c;
      i += terminator.length;
      while (i < source.length) {
        if (source[i] == r'\' && i + 1 < source.length) {
          i += 2;
          continue;
        }
        if (source.startsWith(terminator, i)) {
          i += terminator.length;
          break;
        }
        i++;
      }
      // A space keeps two adjacent tokens from fusing into a false match.
      out.write(' ');
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}
