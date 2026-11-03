import 'dart:io';

/// A `Row` that hands a `Spacer` a slice of its width while a `Column` or
/// `Text` sibling has no width bound of its own.
///
/// This is ledger #47/#48's defect family, the shape behind three shipped
/// overflows:
///
/// * `AdminAdvertCard`'s label `Column` sat directly in the `Row` beside a
///   `Spacer` and the action icons and ran 37px past the right edge at 360px;
/// * purchases' scan `TicketCard` did the same a module over, and a
///   12500-use ticket pushed the row 149px past the edge;
/// * purchases' header `CustomButton` pair overflowed by 236px for the same
///   reason one level down — a `Text` with no flex sibling to bound it.
///   (`CustomButton`'s own row trades the `Spacer` for a fixed `SizedBox`,
///   which is the same failure mode: a child that cannot shrink next to one
///   that will not.)
///
/// The mechanism is Flutter's layout rule: `Row` gives every non-flex child
/// unbounded width, so a direct `Column`/`Text` sizes to its intrinsic width
/// and never wraps to the row. A `Spacer` beside it then takes whatever
/// slack exists — and there is none once the intrinsic width passes the
/// row's, so the whole row overflows the right edge. `Expanded`/`Flexible`
/// are the fix: they force the child into the width that is left, which is
/// exactly what this scan looks for — a child with neither a flex wrapper
/// nor a width of its own next to the `Spacer`.
///
/// The scan is source-level and bracket-aware: comments and string bodies are
/// blanked to spaces before any bracket is counted, so a `(` or `,` in a
/// label or a doc comment cannot split a child list.
class RowSpacerHazard {
  const RowSpacerHazard(this.source, this.className, this.child, this.line);

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// The enclosing class, or `(top level)` when the `Row` is outside one.
  final String className;

  /// The unconstrained child's widget: `Column`, `Text`, `AutoSizeText` or
  /// `RichText`.
  final String child;

  /// 1-based line of the offending `Row`, for the failure message only — it
  /// deliberately stays out of [toString], because [toString] is the ratchet
  /// key and line numbers churn on unrelated edits.
  final int line;

  @override
  String toString() => '$source $className $child';
}

/// Widgets that size to their content along the row's axis: safe only inside
/// a flex or a bounded box, hazardous as a direct `Row` child.
const _unconstrained = {'Column', 'Text', 'AutoSizeText', 'RichText'};

/// The source with comment and string bodies replaced by spaces, offsets
/// preserved, so bracket scanning and widget-name matching see code only.
String _mask(String src) {
  final out = StringBuffer();
  var i = 0;
  var inCommentLine = false;
  var inCommentBlock = false;
  var inString = false;
  var quote = '';
  while (i < src.length) {
    final c = src[i];
    final n = i + 1 < src.length ? src[i + 1] : '';
    if (inCommentLine) {
      if (c == '\n') {
        inCommentLine = false;
        out.write('\n');
      } else {
        out.write(' ');
      }
      i++;
    } else if (inCommentBlock) {
      if (c == '*' && n == '/') {
        inCommentBlock = false;
        out.write('  ');
        i += 2;
      } else {
        out.write(c == '\n' ? '\n' : ' ');
        i++;
      }
    } else if (inString) {
      if (c == '\\' && n.isNotEmpty) {
        out.write('  ');
        i += 2;
      } else if (c == quote) {
        inString = false;
        out.write(c);
        i++;
      } else {
        out.write(c == '\n' ? '\n' : ' ');
        i++;
      }
    } else if (c == '/' && n == '/') {
      inCommentLine = true;
      out.write('  ');
      i += 2;
    } else if (c == '/' && n == '*') {
      inCommentBlock = true;
      out.write('  ');
      i += 2;
    } else if (c == "'" || c == '"') {
      inString = true;
      quote = c;
      out.write(c);
      i++;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// Index of the bracket closing the one at [open], or -1. Counts every
/// bracket kind as one nesting level — valid Dart nests properly, and the
/// text is masked, so a stray closer cannot unbalance the count.
int _matching(String s, int open) {
  if (open < 0 || open >= s.length) return -1;
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// The top-level elements of a children list, as masked substrings: split on
/// commas that sit outside every bracket.
List<String> _elements(String list) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < list.length; i++) {
    final c = list[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
    } else if (c == ',' && depth == 0) {
      out.add(list.substring(start, i));
      start = i + 1;
    }
  }
  if (start < list.length) out.add(list.substring(start));
  return out.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

final _ifPrefix = RegExp(r'^if\s*\(');
final _constPrefix = RegExp(r'^const\s+');
final _primary = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)(?:\.[A-Za-z_]\w*)?\s*\(');

/// The widget constructor an expression starts with, after stripping
/// `const` — `Text.rich(...)` counts as `Text`, spreads resolve to nothing.
String? _simple(String s) {
  var e = s.trim();
  if (e.startsWith('...')) return null;
  e = e.replaceFirst(_constPrefix, '');
  return _primary.firstMatch(e)?.group(1);
}

/// The widget constructors one children-list element can build: the element
/// itself, plus both branches when it is a collection `if`/`else`.
Iterable<String> _primaries(String element) sync* {
  var rest = element.trim();
  while (true) {
    if (!_ifPrefix.hasMatch(rest)) {
      final simple = _simple(rest);
      if (simple != null) yield simple;
      return;
    }
    final close = _matching(rest, rest.indexOf('('));
    if (close < 0) return;
    rest = rest.substring(close + 1).trim();

    // Split a trailing `else` branch at depth 0 and yield both branches.
    var depth = 0;
    var elseAt = -1;
    for (var i = 0; i < rest.length; i++) {
      final c = rest[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
      if (depth == 0 &&
          (rest.startsWith('else ', i) || rest.startsWith('else\n', i))) {
        elseAt = i;
        break;
      }
    }
    if (elseAt < 0) continue;
    final simple = _simple(rest.substring(0, elseAt));
    if (simple != null) yield simple;
    rest = rest.substring(elseAt + 'else'.length).trim();
  }
}

/// Every `Row`-with-`Spacer` hazard under [root]/lib, sorted.
List<RowSpacerHazard> findRowSpacerHazards({String root = '.'}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final found = <RowSpacerHazard>[];
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    if (!path.endsWith('.dart')) continue;
    // Generated models/enums are not laid out.
    if (path.contains('/generated/')) continue;
    found.addAll(_inFile(file, path));
  }
  found.sort((a, b) => a.toString().compareTo(b.toString()));
  return found;
}

final _rowCall = RegExp(r'\bRow\s*\(');

/// `children:` followed by a literal list; a variable-list `Row` cannot be
/// reasoned about statically and is skipped.
final _childrenKey = RegExp(r'\bchildren\s*:\s*(?:<[^<>]*>\s*)?\[');

final _classDecl = RegExp(
  r'^class\s+([A-Za-z_][A-Za-z0-9_]*)',
  multiLine: true,
);

List<RowSpacerHazard> _inFile(File file, String path) {
  final src = file.readAsStringSync();
  final text = _mask(src);
  final out = <RowSpacerHazard>[];

  // Class regions for attribution: a `Row` belongs to the last declaration
  // that starts before it, mirroring the other detectors.
  final decls = <({int start, String name})>[];
  for (final m in _classDecl.allMatches(text)) {
    decls.add((start: m.start, name: m.group(1)!));
  }

  for (final row in _rowCall.allMatches(text)) {
    // The match includes the `(`.
    final argsOpen = row.end - 1;
    final argsClose = _matching(text, argsOpen);
    if (argsClose < 0) continue;
    final args = text.substring(argsOpen + 1, argsClose);

    // The Row's OWN children list: the key has to sit at depth 0 of the
    // argument list, or a nested widget's list would be read as this row's.
    var depth = 0;
    var listOpen = -1;
    for (var i = 0; i < args.length; i++) {
      final c = args[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
      if (depth == 0 && _childrenKey.matchAsPrefix(args, i) != null) {
        listOpen = args.indexOf('[', i);
        break;
      }
    }
    if (listOpen < 0) continue;
    final listClose = _matching(args, listOpen);
    if (listClose < 0) continue;
    final children = _elements(args.substring(listOpen + 1, listClose));

    final primaries = <String>{};
    for (final child in children) {
      primaries.addAll(_primaries(child));
    }
    if (!primaries.contains('Spacer')) continue;
    final hazards = primaries.where(_unconstrained.contains).toList();
    if (hazards.isEmpty) continue;

    var name = '(top level)';
    for (final decl in decls) {
      if (decl.start <= row.start) name = decl.name;
    }
    final line = '\n'.allMatches(src.substring(0, row.start)).length + 1;
    for (final hazard in hazards) {
      out.add(RowSpacerHazard(path, name, hazard, line));
    }
  }
  return out;
}
