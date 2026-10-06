import 'dart:io';

/// The in-place list-mutation detector, ported from
/// `tool/detect_inplace_list_mutations.py` so the ratchet can assert its own
/// coverage without shelling out to Python.
///
/// It answers one question about `lib/`: which call sites MUTATE a collection
/// the surrounding code does not own? Ledger #12 found 21 such sites by
/// looking only at `.sort(`; the same sweep generalised to every mutating
/// list/set method found 12 more, two of which were so broken they never
/// notified a listener at all.
///
/// A finding is a bucket, a file, a line and the receiver expression. Anything
/// the detector cannot resolve to a copy, a class's own field, a notifier's
/// API or a platform object comes back as [Bucket.review], which is the only
/// bucket the ratchet treats as a finding.
class InplaceMutation {
  const InplaceMutation(this.bucket, this.source, this.line, this.receiver);

  final Bucket bucket;

  /// `lib/…` path, repo-relative and forward-slashed.
  final String source;

  /// 1-based line of the call, not of the statement it sits in.
  final int line;

  /// The receiver expression as written, e.g. `state` or `plants..removeWhere`.
  final String receiver;

  /// `lib/path:line`, the stable key the ratchet allowlist uses.
  String get id => '$source:$line';

  @override
  String toString() => '$bucket $id  receiver=$receiver';
}

enum Bucket {
  /// The receiver is a copy made on the spot. Always safe.
  fresh,

  /// A class field, mutated by its own class.
  owned,

  /// `usersNotifier.add(...)` — `ListNotifierAPI`'s API, not a list mutation.
  api,

  /// A `TextEditingController`, `SharedPreferences`, stream sink, etc.
  control,

  /// `DateTime.now().add(Duration(...))` — not a collection at all.
  nonlist,

  /// `dates[i].add(...)` — an index expression is an element, not the list.
  element,

  /// Not resolvable. The only bucket that is a finding.
  review,
}

/// Every list/set method that mutates in place. `sort` is here so this
/// supersedes `tool/detect_inplace_sorts.py` rather than sitting beside it.
const mutators = <String>[
  'add',
  'addAll',
  'addFirst',
  'addLast',
  'clear',
  'fillRange',
  'insert',
  'insertAll',
  'remove',
  'removeAt',
  'removeFirst',
  'removeLast',
  'removeRange',
  'removeSingle',
  'removeWhere',
  'replaceRange',
  'retainWhere',
  'setAll',
  'setLength',
  'setRange',
  'shuffle',
  'sort',
];

// Longest first, so `removeAt` is never read as `remove`.
final _alt = (mutators.toList()..sort((a, b) => b.length.compareTo(a.length)))
    .join('|');

/// A receiver is a postfix expression: a base (identifier or literal) plus any
/// number of `.field`, `.method(...)`, `?`, `!` and `[index]` steps.
///
/// Matched FORWARDS on purpose. The sort detector walked backwards over a loose
/// character class, which runs straight through `=`, `>` and `+` and reports a
/// whole function body as the receiver — that alone produced 201 findings, all
/// noise.
const _base =
    r'(?:[A-Za-z_$][\w$]*|\[[^\[\]]*\]|\{[^}]*\}|<[^>]*>\s*\[[^\]]*\])';
const _seg =
    r'(?:\s*[?!]?\s*\.\s*[A-Za-z_$][\w$]*'
    r'|\s*\.\s*[A-Za-z_$][\w$]*\s*\((?:[^()]|\([^()]*\))*\)'
    r'|\s*\[[^\[\]]*\])*';
const _receiver = '$_base$_seg';

final _plain = RegExp('($_receiver)\\.($_alt)\\s*\\(');
// `..method(` — the extra dot is the cascade, so group 1 is the cascade TARGET,
// classified the same way a receiver is.
final _cascade = RegExp('($_receiver)\\.\\.($_alt)\\s*\\(');

/// Receiver last-segments that are platform objects, not Dart collections.
const _control = <String>{
  'controller',
  'prefs',
  'storage',
  'sink',
  'completer',
  'context',
  'cacher',
  'caches',
  'keys',
  'focusnode',
};

/// `ListNotifierAPI`/`SingleNotifierAPI` expose methods whose names collide
/// with the mutators. On a notifier receiver they are provider API.
final _providerTail = RegExp(
  r'(notifier|provider|repository|repo)$',
  caseSensitive: false,
);

/// Types known NOT to be a collection. `DateTime.add(Duration)` is the
/// important one: `DateTime.now().add(...)` is everywhere in this codebase.
final _nonlist = RegExp(
  r'^DateTime\s*[.(]|\.now\(\)$|\.parse\(|^Duration|^String|^num$|^bool$',
);

/// `state.sublist(0)`, `x.toList()`, `List.of(x)` — a copy made on the spot.
/// `sublist` matters: it is this codebase's idiomatic "copy before I mutate".
final _copyTail = RegExp(
  r'(List|Set|Map)\s*[.<]|\.(?:toList|toSet|sublist|from)\s*(?:<[^>]*>)?\s*\([^()]*\)'
  r'|\.cast<',
);

/// `map.putIfAbsent(k, () => []).add(x)` — the receiver is a list the factory
/// built on the spot. `[^;]*?` rather than `[^)]*` because the text to cross is
/// `() => []`, which contains a closing paren of its own.
final _putIfAbsent = RegExp(r'putIfAbsent\([^;]*?=>\s*[\[<]');

/// A declaration that builds a new collection right here.
const _typed = r'(?:final|const|var|late|static)?\s*[\w<>,\s?]*\??\s+';
const _freshRhs =
    r'(?:const\s+|final\s+|late\s+)?'
    r'(?:\[|\{|<[^>]*>\s*[\[{]|List\s*[.<]|Set\s*[.<]|Map\s*[.<]'
    r'|\w[\w.()\[\]]*\s*\.\s*(?:toList|toSet|sublist|split|cast)\s*(?:<[^>]*>)?\s*\([^()]*\)'
    r'|\w+\s*\.\s*(?:where|map|entries|keys|values)\b[^;]*\.(?:toList|toSet)\(\))';

/// NOTE: Dart RAW strings do NOT interpolate. `r'...$_freshRhs'` compiles to a
/// pattern containing the literal text `$freshRhs`, which still parses as a
/// valid regex and simply never matches — a silent failure that cost an hour
/// and looked like a classification bug, not a string-literal bug. So the
/// patterns that splice a fragment in are built by CONCATENATION, never by
/// interpolation inside `r'...'`.
final _decl = RegExp(
  r'\b' + _typed + r'(?<name>[A-Za-z_$][\w$]*)\s*=\s*' + _freshRhs,
  multiLine: true,
);

/// `List<X> foo = [];` split across two lines is the same declaration as a
/// one-liner, so a bare reassignment to a literal makes the name fresh too.
final _reassign = RegExp(
  r'^\s+(?<name>[A-Za-z_$][\w$]*)\s*=\s*' + _freshRhs,
  multiLine: true,
);

/// A class member: collection-typed, at exactly two spaces of indent. This repo
/// formats at two spaces per level, so a two-space indent inside a top-level
/// class is a field and a four-space one is a local.
final _field = RegExp(
  r'^ {2}(?:static\s+|late\s+|final\s+|const\s+)*'
  r'(?:List|Set|Iterable|Map)<[^>]*>\??\s+(?<name>[A-Za-z_$][\w$]*)\s*(?:=|;)',
);

/// Blanks out comments and string bodies, preserving offsets and newlines.
///
/// Without this a mutator name inside a doc comment, an l10n string or a URL is
/// indistinguishable from a call — ledger #49's ratchet already learned that.
String stripNoise(String src) {
  final out = List<String>.of(src.split(''));
  var i = 0;
  final n = src.length;
  void blank(int from, int to) {
    for (var k = from; k < to && k < n; k++) {
      if (out[k] != '\n') out[k] = ' ';
    }
  }

  while (i < n) {
    final c = src[i];
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      var j = src.indexOf('\n', i);
      if (j < 0) j = n;
      blank(i, j);
      i = j;
    } else if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      final end = src.indexOf('*/', i + 2);
      final j = end < 0 ? n : end + 2;
      blank(i, j);
      i = j;
    } else if (c == "'" || c == '"') {
      final triple = src.startsWith("'''", i) || src.startsWith('"""', i);
      final quote = triple ? src.substring(i, i + 3) : c;
      var j = i + quote.length;
      while (j < n) {
        if (src[j] == r'\') {
          j += 2;
          continue;
        }
        if (j + quote.length <= n && src.startsWith(quote, j)) {
          j += quote.length;
          break;
        }
        j++;
      }
      blank(i, j < n ? j : n);
      i = j;
    } else {
      i++;
    }
  }
  return out.join();
}

/// Collapses a receiver to one line.
///
/// A receiver is matched as a whole expression and can easily span several
/// formatted lines (`Map.from(\n  topics,\n)..remove`). That is fine for
/// classifying, but it breaks the one-row-per-line contract the Python port's
/// `--dump` promises, so every receiver is flattened where it is REPORTED, not
/// where it is matched.
String _oneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

String _tail(String recv) =>
    recv.split(RegExp(r'[.\[\]()<>]')).lastWhere((s) => true, orElse: () => '');

({Set<String> fresh, Set<String> fields}) declarations(String src) {
  final fresh = <String>{};
  final fields = <String>{};
  for (final m in _reassign.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }
  for (final m in _decl.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }
  for (final line in src.split('\n')) {
    final m = _field.firstMatch(line);
    if (m != null) fields.add(m.namedGroup('name')!);
  }
  return (fresh: fresh, fields: fields);
}

/// Buckets a mutating call by what its receiver actually is.
Bucket classify(String recv, Set<String> fresh, Set<String> fields) {
  recv = recv.trim();
  final tail = _tail(recv).trim();
  final low = tail.toLowerCase();

  // `state` is the one name a file can never have made for itself: in a
  // Notifier it IS the provider's state, whatever the last line assigned to
  // it. `state = state.sublist(0)` makes a copy on the RIGHT of the
  // assignment and leaves `state` exactly as owned as it was. Getting this
  // backwards silences the single most dangerous receiver in the codebase.
  if (low == 'state') return Bucket.review;
  // A literal receiver is a fresh collection by construction.
  if (recv.startsWith('[') || recv.startsWith('{') || recv.startsWith('<')) {
    return Bucket.fresh;
  }
  if (_copyTail.hasMatch(recv)) return Bucket.fresh;
  if (recv.endsWith(']')) return Bucket.element;
  if (_control.contains(low) || low.endsWith('controller')) {
    return Bucket.control;
  }
  if (_nonlist.hasMatch(recv)) return Bucket.nonlist;
  if (_providerTail.hasMatch(low)) return Bucket.api;
  if (_putIfAbsent.hasMatch(recv)) return Bucket.fresh;
  // OWNED before FRESH so a notifier's own catalog is labelled as its own
  // rather than as a fresh list: both are "not a finding", but only one is the
  // right reason.
  if (fields.contains(tail)) return Bucket.owned;
  if (fresh.contains(tail)) return Bucket.fresh;
  return Bucket.review;
}

/// Scans [root] for in-place collection mutations.
List<InplaceMutation> findInplaceListMutations({
  Directory? root,
  String rootPath = 'lib',
}) {
  final dir = root ?? Directory(rootPath);
  final found = <InplaceMutation>[];
  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final source = stripNoise(file.readAsStringSync());
    final decls = declarations(source);
    for (final entry in {'cascade': _cascade, 'plain': _plain}.entries) {
      for (final m in entry.value.allMatches(source)) {
        final recv = m.group(1)!;
        final method = m.group(2)!;
        final bucket = classify(recv, decls.fresh, decls.fields);
        if (bucket != Bucket.review && entry.key == 'cascade') {
          // Keep going: a cascade target is still classified on its own
          // merits, and the cascade report is what names `plants..add`.
        }
        found.add(
          InplaceMutation(
            bucket,
            file.path.replaceAll('\\', '/'),
            '\n'.allMatches(source.substring(0, m.start)).length + 1,
            _oneLine(entry.key == 'cascade' ? '$recv..$method' : recv),
          ),
        );
      }
    }
  }
  found.sort((a, b) {
    final bySource = a.source.compareTo(b.source);
    return bySource != 0 ? bySource : a.line.compareTo(b.line);
  });
  return found;
}
