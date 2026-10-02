import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  /// The candidates that cannot be mounted here, each with the reason. A page
  /// is rendered by its module's integration test, not by a widget test, so
  /// the page-shaped entries below are not debt — they are the boundary
  /// between the two levels.
  const notMounted = <String, String>{
    'lib/amap/ui/pages/main_page/orders_section.dart OrderSection':
        'renders the amap orders list, which needs the orders/associations '
        'provider maps seeded; a bare OrderSection throws ProviderException. '
        'Also exempted by the fixed-width sweep for the same reason.',
    'lib/amap/ui/pages/detail_delivery_page/order_detail_ui.dart DetailOrderUI':
        'BLOCKED by bug #3: its build watches userOrderListProvider, whose '
        'notifier `return state` from build(), which throws "Tried to read the '
        'state of an uninitialized provider" through Riverpod\'s provider '
        'error channel — a channel the FlutterError.onError filter in '
        'ignoreAmapKnownQuirks() cannot absorb, so the card never lays out. '
        'The one-line fix is `return const AsyncValue.loading()` in '
        'user_order_list_provider.dart, which is what every other '
        'ListNotifierAPI subclass already does.',
    'lib/amap/ui/pages/admin_page/account_handler.dart AccountHandler':
        'an admin edit DIALOG opened by the accounts page, not a card: it '
        'needs the accounts provider map and a route to dismiss back to.',
    'lib/amap/ui/pages/admin_page/delivery_handler.dart DeliveryHandler':
        'an admin edit DIALOG opened by the deliveries page, same reason as '
        'AccountHandler.',
    'lib/amap/ui/pages/admin_page/product_handler.dart ProductHandler':
        'an admin edit DIALOG opened by the products page, same reason as '
        'AccountHandler.',
    'lib/loan/ui/pages/admin_page/loaners_items.dart LoanersItems':
        'a list SECTION of the admin page, not a card: it composes '
        'CheckItemCard rows out of the admin loan list and needs that map '
        'seeded. Its own leaf is mounted by the sweep.',
    'lib/loan/ui/pages/admin_page/on_going_loan.dart OnGoingLoan':
        'a list SECTION of the admin page, same reason as LoanersItems.',
    'lib/purchases/ui/pages/scan_page/scan_dialog.dart ScanDialog':
        'a MODAL, covered end-to-end by '
        'purchases/integration/purchases_scan_integration_test.dart (tag to '
        'scan to confirm, with the stale-secret probe). A widget test could '
        'mount it, but the page it navigates to is what makes it worth '
        'testing, and that is the integration level\'s job.',
    'lib/booking/ui/pages/main_page/main_page.dart BookingMainPage':
        'a PAGE. Rendered by booking\'s integration tests.',
    'lib/cinema/ui/pages/admin_page/admin_page.dart AdminPage':
        'a PAGE. Rendered by cinema\'s integration tests.',
    'lib/event/ui/pages/main_page/main_page.dart EventMainPage':
        'a PAGE. Rendered by event/feed\'s integration tests.',
    'lib/seed-library/ui/pages/species_page/species_page.dart SpeciesPage':
        'a PAGE. Rendered by seed-library\'s integration tests.',
  };

  /// Every `test/**/widget/*.dart` file, with comments and string literals
  /// removed.
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
    final out = <String>[];
    for (final file in testDir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/widget/')) continue;
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
            'Run `python3 tool/detect_fixed_size_card_layouts.py` for the list '
            'and its pinned dimensions.',
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

  test('the detector and the Python tool agree on the candidate count', () {
    // `tool/detect_fixed_size_card_layouts.py` is the human-facing lister
    // (run it with no arguments to see the pinned dimensions). It is a
    // separate implementation, so the two drifting apart is the failure mode
    // that matters: the README's "keep the two in step" is only true if
    // somebody checks. The counts are the cheap invariant — a divergence in
    // parsing shows up here as a different total, and the Python tool's own
    // output is the one to diff against.
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
