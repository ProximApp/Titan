import 'dart:io';

/// A lookup in `lib/` that throws when the element it wants is absent.
///
/// Three shapes, each a real crash this repo has shipped:
///
/// * [bareFirstWhere] — `firstWhere`/`singleWhere` with no `orElse:`.
///   `Bad state: No element` out of a `build`, a comparator or a tap handler.
/// * [whereChainFirst] — `list.where(...).first` (also `.last`/`.single`).
///   The filtered list can be empty even when the source is not, so an
///   `isEmpty` check on the source does not guard it.
/// * [unwrappedOptional] — `firstWhereOrNull(...)!`, which turns the safe
///   lookup into the bare one's crash one character later.
///
/// The scan is source-level and bracket-aware. Comments and string bodies are
/// blanked before any bracket is counted, so a `(` in a label or doc comment
/// cannot split a call.
class CollectionGuardHazard {
  const CollectionGuardHazard(this.source, this.rule, this.line);

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// One of [bareFirstWhere], [whereChainFirst], [unwrappedOptional].
  final String rule;

  /// 1-based line, for the failure message only — it stays out of
  /// [toString], which is the ratchet key.
  final int line;

  @override
  String toString() => '$source $rule';
}

const String bareFirstWhere = 'bareFirstWhere';
const String whereChainFirst = 'whereChainFirst';
const String unwrappedOptional = 'unwrappedOptional';

/// The source with comment and string bodies replaced by spaces, offsets
/// preserved.
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

int _matchingForward(String s, int open) {
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

int _matchingBackward(String s, int close) {
  if (close < 0 || close >= s.length) return -1;
  var depth = 0;
  for (var i = close; i >= 0; i--) {
    final c = s[i];
    if (c == ')' || c == ']' || c == '}') {
      depth++;
    } else if (c == '(' || c == '[' || c == '{') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

final _bareCall = RegExp(r'\.\s*(firstWhere|singleWhere)\s*\(');
final _optionalCall = RegExp(r'\.\s*firstWhereOrNull\s*\(');
final _orElse = RegExp(r'\borElse\s*:');
final _chainTail = RegExp(r'\.\s*(first|last|single)\b');
final _whereCallee = RegExp(r'\bwhere$');

/// Every unguarded lookup under [root]/lib, sorted.
List<CollectionGuardHazard> findCollectionGuards({String root = '.'}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final found = <CollectionGuardHazard>[];
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^\./'), '');
    if (!path.endsWith('.dart')) continue;
    if (path.contains('/generated/')) continue;
    found.addAll(_inFile(file, path));
  }
  found.sort((a, b) => a.toString().compareTo(b.toString()));
  return found;
}

List<CollectionGuardHazard> _inFile(File file, String path) {
  final src = file.readAsStringSync();
  final text = _mask(src);
  final out = <CollectionGuardHazard>[];
  int lineOf(int at) => '\n'.allMatches(src.substring(0, at)).length + 1;

  for (final match in _bareCall.allMatches(text)) {
    final open = match.end - 1;
    final close = _matchingForward(text, open);
    if (close < 0) continue;
    final body = text.substring(open + 1, close);
    if (_orElse.hasMatch(body)) continue;
    out.add(CollectionGuardHazard(path, bareFirstWhere, lineOf(match.start)));
  }

  for (final match in _optionalCall.allMatches(text)) {
    final open = match.end - 1;
    final close = _matchingForward(text, open);
    if (close < 0) continue;
    var i = close + 1;
    while (i < text.length && (text[i] == ' ' || text[i] == '\n')) {
      i++;
    }
    if (i < text.length && text[i] == '!') {
      out.add(
        CollectionGuardHazard(path, unwrappedOptional, lineOf(match.start)),
      );
    }
  }

  for (final match in _chainTail.allMatches(text)) {
    var i = match.start - 1;
    while (i >= 0 && (text[i] == ' ' || text[i] == '\n')) {
      i--;
    }
    if (i < 0 || text[i] != ')') continue;
    final open = _matchingBackward(text, i);
    if (open < 0) continue;
    final callee = text.substring(0, open).trimRight();
    if (!_whereCallee.hasMatch(callee)) continue;
    out.add(CollectionGuardHazard(path, whereChainFirst, lineOf(match.start)));
  }

  return out;
}
