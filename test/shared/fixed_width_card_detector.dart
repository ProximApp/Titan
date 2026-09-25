import 'dart:io';

/// The fixed-width-card detector, ported from `tool/detect_fixed_width_cards.py`
/// so the sweep can assert its own coverage without shelling out to Python.
///
/// It answers one question about `lib/`: which widget classes fix their own
/// width AND put flex children inside that box? Those are the only shapes
/// that overflow at phone width for a reason no font choice or padding tweak
/// can fix — the row is exactly as wide as the hardcoded box, so a longer
/// localized label overflows it.
///
/// The old reason this file excluded a card that only fixes a HEIGHT —
/// "clipping is a different question from overflow" — turned out to be the
/// same mistake convention 24 records for `ItemCardInLoan`: for a `RenderFlex`
/// a pinned height compresses, but for a card a pinned height with an
/// un-capped `Text` inside overflows vertically by exactly the same kind of
/// amount. So the height half is no longer excluded, only SPLIT:
/// [findFixedHeightCards] is the same scan with the height predicates, it has
/// its own sweep (`tools/widget/fixed_height_cards_test.dart`), and the two
/// families stay in separate files because mixing them buries the width bugs
/// — the original objection, which was about reporting, not about coverage.
///
/// There is no longer a Python twin to keep in step: `tool/detect_fixed_width_
/// cards.py` is gone and this file is the single implementation, which retires
/// the "cross-checked only by count" debt convention 23 mentions.
class FixedWidthCard {
  const FixedWidthCard(this.source, this.className);

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// The class name, without any leading underscore (privates are skipped:
  /// a library-private widget cannot be mounted from a test at all).
  final String className;

  @override
  String toString() => '$source $className';
}

/// A widget class that fixes its own HEIGHT and puts content inside that box.
///
/// The sibling of [FixedWidthCard], and the second half of what used to be one
/// scan. The predicates differ in exactly one place, and deliberately:
///
/// * **width** needs **flex children** beside the literal width. A row is
///   exactly as wide as the hardcoded box, so a longer localized label
///   overflows it.
/// * **height** needs **content that can outgrow the box** — `Text`,
///   `Column`, `ListView`, … — because flex children do NOT overflow a pinned
///   height, they compress. `Expanded` inside a fixed-height box shrinks to
///   fit and the box simply clips whatever the text needed. So the height scan
///   asks "can this grow past the box", not "is there a flex child".
///
/// Everything else is deliberately identical: same container-suffix filter,
/// same skip of private classes (a library-private widget cannot be mounted
/// from a test at all), same skip of `lib/generated`.
class FixedHeightCard {
  const FixedHeightCard(this.source, this.className, this.height);

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// The class name, without any leading underscore.
  final String className;

  /// The literal height the class pins, for the failure message. There can be
  /// more than one in a class; the first is reported.
  final String height;

  @override
  String toString() => '$source $className';
}

const _widgetBases = [
  'StatelessWidget',
  'StatefulWidget',
  'HookConsumerWidget',
  'ConsumerWidget',
  'HookWidget',
  'ConsumerStatefulWidget',
];

const _containerSuffixes = [
  'Card',
  'Ui',
  'Item',
  'Template',
  'Tile',
  'Box',
  'Bar',
  'Chip',
  'Header',
  'Footer',
  'Row',
  'Section',
  'Banner',
  'Badge',
];

/// `width: 230` — a literal, not `double.infinity` or an expression.
final _hardWidth = RegExp(r'\bwidth\s*:\s*\d');

/// `BoxConstraints(minWidth: 200, …)`, the other way a box gets fixed.
final _constrainedWidth = RegExp(r'\b(minWidth|maxWidth)\s*:\s*\d');

/// Flex children: the thing that overflows when the box cannot grow.
final _flex = RegExp(r'\b(Row|Column|Wrap|ListView|GridView|Table)\s*\(');

final _classDecl = RegExp(
  '^class\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+(?:extends\\s+[\\w<>, ]*?'
  '\\b(?:${_widgetBases.join('|')})\\b)',
  multiLine: true,
);

final _nextTopLevel = RegExp(
  '^(?:class|mixin|enum|extension)\\s',
  multiLine: true,
);

/// Every fixed-width card candidate under [root]/lib.
List<FixedWidthCard> findFixedWidthCards({String root = '.'}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final found = <FixedWidthCard>[];
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        // `listSync` echoes the root argument: drop a leading `./` so the
        // paths compare equal to the ones `tool/detect_fixed_width_cards.py`
        // prints and to the ones in this file's registry.
        .replaceFirst(RegExp(r'^\./'), '');
    if (!path.endsWith('.dart')) continue;
    // Generated models/enums are not laid out.
    if (path.contains('/generated/')) continue;
    found.addAll(_inFile(file, path));
  }
  found.sort((a, b) => a.toString().compareTo(b.toString()));
  return found;
}

/// `height: 80` — a literal, not `double.infinity` or an expression.
final _hardHeight = RegExp(r'\bheight\s*:\s*(\d+(?:\.\d+)?)');

/// `BoxConstraints(minHeight: 40, …)`, the other way a box gets fixed.
final _constrainedHeight = RegExp(r'\b(minHeight|maxHeight)\s*:\s*\d');

/// Content that can outgrow a box. Flex children are NOT here on purpose:
/// `Expanded`/`Spacer` compress inside a fixed height, so they cannot cause
/// the vertical overflow this scan is looking for.
final _grows = RegExp(
  r'\b(Text|AutoSizeText|RichText|Column|ListView|GridView|Wrap|ListTile|'
  r'Table|Flexible|Expanded|Spacer)\b',
);

/// Every fixed-height card candidate under [root]/lib.
List<FixedHeightCard> findFixedHeightCards({String root = '.'}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final found = <FixedHeightCard>[];
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    if (!path.endsWith('.dart')) continue;
    if (path.contains('/generated/')) continue;
    for (final match in _classDecl.allMatches(file.readAsStringSync())) {
      final name = match.group(1)!;
      if (name.startsWith('_')) continue;
      if (!_containerSuffixes.any(name.endsWith)) continue;
      final text = file.readAsStringSync();
      final body = _bodyFrom(text, match.end);
      final literal = _hardHeight.firstMatch(body)?.group(1);
      if (literal == null && !_constrainedHeight.hasMatch(body)) continue;
      if (!_grows.hasMatch(body)) continue;
      found.add(FixedHeightCard(path, name, literal ?? '(constrained)'));
    }
  }
  found.sort((a, b) => a.toString().compareTo(b.toString()));
  return found;
}

/// The text of a class body: everything from [after] to the next top-level
/// `class`/`mixin`/`enum`/`extension`, so one class's literal cannot be
/// credited to the next one.
String _bodyFrom(String text, int after) {
  final rest = text.substring(after);
  final next = _nextTopLevel.firstMatch(rest);
  return next == null ? rest : rest.substring(0, next.start);
}

List<FixedWidthCard> _inFile(File file, String path) {
  final text = file.readAsStringSync();
  final out = <FixedWidthCard>[];
  for (final match in _classDecl.allMatches(text)) {
    final name = match.group(1)!;
    if (name.startsWith('_')) continue;
    final rest = text.substring(match.end);
    final next = _nextTopLevel.firstMatch(rest);
    final body = next == null ? rest : rest.substring(0, next.start);
    final fixed = _hardWidth.hasMatch(body) || _constrainedWidth.hasMatch(body);
    if (!fixed) continue;
    if (!_containerSuffixes.any(name.endsWith)) continue;
    if (!_flex.hasMatch(body)) continue;
    out.add(FixedWidthCard(path, name));
  }
  return out;
}

/// A widget class that hands `CardLayout` a pinned dimension.
///
/// This is the companion to [FixedWidthCard] and exists because that
/// detector cannot see a width passed as an ARGUMENT. It looks for a
/// hardcoded width beside flex children in the same file, so
/// `CardLayout(width: 140, height: 80)` is invisible to it: the number is a
/// constructor argument, not a `SizedBox`. loan's `ItemCardInLoan` is a real
/// pinned 80px box that way, and so is amap's `UserCashUiLayout` at 150x100.
///
/// Height counts too, and deliberately so. The original detector excluded
/// height-only cards on the grounds that clipping is a different question
/// from overflow — true for a `RenderFlex`, but not for a card: a pinned
/// height with an un-capped `Text` inside is the same hazard, and is exactly
/// what `ItemCardInLoan` turned out to be.
class FixedSizeCardLayout {
  const FixedSizeCardLayout(
    this.source,
    this.className, {
    this.width,
    this.height,
  });

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// The class name, without any leading underscore.
  final String className;

  /// The literal width passed to `CardLayout`, or null when it is not pinned
  /// (including `double.infinity`, which is the opposite of pinned).
  final String? width;

  /// The literal height passed to `CardLayout`, or null when it is not pinned.
  final String? height;

  /// The dimensions this card actually pins, for the failure message.
  String get dimensions => [
    if (width != null) 'width $width',
    if (height != null) 'height $height',
  ].join(' x ');

  @override
  String toString() => '$source $className';
}

/// `width: 140` / `height: 80` — a literal, so `double.infinity` and
/// arithmetic both fall out and only a real pin is reported.
final _literalDimension = RegExp(r'\b(width|height)\s*:\s*(\d+(?:\.\d+)?)');

final _cardLayoutCall = RegExp(r'\bCardLayout\s*\(');

/// Every widget class under [root]/lib that calls `CardLayout` with at least
/// one literal dimension.
List<FixedSizeCardLayout> findFixedSizeCardLayouts({String root = '.'}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final found = <FixedSizeCardLayout>[];
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    if (!path.endsWith('.dart')) continue;
    if (path.contains('/generated/')) continue;
    found.addAll(_sizesInFile(file, path));
  }
  found.sort((a, b) => a.toString().compareTo(b.toString()));
  return found;
}

List<FixedSizeCardLayout> _sizesInFile(File file, String path) {
  final text = file.readAsStringSync();
  final out = <FixedSizeCardLayout>[];
  for (final match in _classDecl.allMatches(text)) {
    final name = match.group(1)!;
    if (name.startsWith('_')) continue;
    final rest = text.substring(match.end);
    final next = _nextTopLevel.firstMatch(rest);
    final body = next == null ? rest : rest.substring(0, next.start);
    String? width, height;
    for (final call in _cardLayoutCall.allMatches(body)) {
      // Scan this call's own argument list, not the rest of the class: two
      // CardLayout calls in one class must not merge their dimensions.
      final args = _argumentsFrom(body, call.end - 1);
      for (final dim in _literalDimension.allMatches(args)) {
        if (dim.group(1) == 'width') {
          width ??= dim.group(2);
        } else {
          height ??= dim.group(2);
        }
      }
      if (width != null || height != null) break;
    }
    if (width == null && height == null) continue;
    out.add(FixedSizeCardLayout(path, name, width: width, height: height));
  }
  return out;
}

/// The argument text of the call whose `(` sits at [openAt], found by counting
/// nesting so a nested `SizedBox(...)` cannot end the scan early.
String _argumentsFrom(String text, int openAt) {
  var depth = 0;
  for (var i = openAt; i < text.length; i++) {
    final c = text[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return text.substring(openAt + 1, i);
    }
  }
  return text.substring(openAt + 1);
}
