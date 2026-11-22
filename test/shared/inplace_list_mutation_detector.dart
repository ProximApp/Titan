import 'dart:io';

/// The in-place list-mutation detector. Dart-only: the ratchet built on it
/// never shells out to another language, so this file is the single
/// implementation of the rule.
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

/// Group 3 is the first-argument prefix: `add(Duration(` is how a date
/// computation is told apart from `list.add(x)`.
final _plain = RegExp('($_receiver)\\.($_alt)\\s*\\(([^;)]{0,64})');
// `..method(` — the extra dot is the cascade, so group 1 is the cascade TARGET,
// classified the same way a receiver is.
final _cascade = RegExp('($_receiver)\\.\\.($_alt)\\s*\\(([^;)]{0,64})');

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
/// The suffix list also carries the object names a provider hands out —
/// `keyService` comes from `keyServiceProvider`, and its `clear()` is the
/// service's own unregister call. A collection is never named after a
/// service, a manager or a client.
final _providerTail = RegExp(
  r'(notifier|provider|repository|repo|service|manager|helper|client)$',
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

/// A listener registry the framework owns: `QR.observer.onNavigate.remove(f)`
/// is qlevar's documented subscribe API, not a collection this app reads.
final _registry = RegExp(
  r'\.(?:observer|listeners|callbacks|subs|handlers)\s*\.',
);

/// Types whose mutator-named methods are their own API rather than a
/// collection mutation — Flutter's controllers, Rx subjects, and Flutter's
/// own diagnostics builder. Matched both as an annotation
/// (`DiagnosticPropertiesBuilder properties`) and as a constructor on the
/// right of `=` (`final q = useTextEditingController();`).
const _objectTypes =
    'useTextEditingController|TextEditingController|ScrollController'
    '|AnimationController|FocusNode|BehaviorSubject|StreamController'
    '|ReplaySubject|PublishSubject|DiagnosticPropertiesBuilder'
    '|SharedPreferences';

/// The tail that follows the type in an annotation: optional generics, then
/// the name. Split out so the concatenation below fits on one line.
const _objectAnnotTail =
    r')\s*(?:<[^;]*?>)?\s*(?:final\s+|const\s+|late\s+|var\s+)?'
    r'(?<name>[A-Za-z_$][\w$]*)';

final _objectAnnot = RegExp(r'(?:' + _objectTypes + _objectAnnotTail);

final _objectCtor = RegExp(
  r'(?<name>[A-Za-z_$][\w$]*)\s*=\s*(?:' + _objectTypes + r')\b',
);

/// `now.add(Duration(days: i))` — the FIRST argument says what the receiver
/// is. Only a date computation adds a Duration; `lib/` holds no
/// `List<Duration>`, and if one ever appears this is the line to revisit.
final _durationArg = RegExp(r'^\s*(?:const\s+)?Duration\b');

/// A name the file itself says is a date: `final DateTime base;` or
/// `final now = DateTime.now();`. This is the proof for a receiver that is a
/// date field or local (`base.add(..)`), independent of what the argument
/// text happens to look like.
final _dateTimeDecl = RegExp(
  r'(?:final\s+|const\s+|late\s+|var\s+)?DateTime\s+'
  r'(?<name>[A-Za-z_$][\w$]*)',
);

final _dateTimeRhs = RegExp(
  r'(?<name>[A-Za-z_$][\w$]*)\s*=\s*(?:DateTime|Duration)\b',
);

/// `for (List<X> list in ownedMap.values) list.sort(..)` — the loop variable
/// ranges over values the map literal in THIS file allocated.
final _freshValues = RegExp(
  r'for\s*\(\s*(?:final\s+|var\s+|const\s+)?[\w<>,\s?]+\??\s+'
  r'(?<name>[A-Za-z_$][\w$]*)\s+in\s+'
  r'(?<base>[A-Za-z_$][\w$]*)\s*\.\s*values\b',
  multiLine: true,
);

/// `.fold([], (a, b) => a..addAll(b))` — the accumulator starts as a fresh
/// literal, so every mutation of it is local to this call.
final _foldSeed = RegExp(
  r'\.fold\s*\(\s*(?:\[\]|<[^;]*?>\s*\[\])\s*,\s*\(\s*'
  r'(?<name>[A-Za-z_$][\w$]*)',
);

/// A declaration that builds a new collection right here.
const _typed = r'(?:final|const|var|late|static)?\s*[\w<>,\s?]*\??\s+';
const _freshRhs =
    r'(?:const\s+|final\s+|late\s+)?'
    r'(?:\[|\{|<[^;]*?>\s*[\[{]|List\s*[.<]|Set\s*[.<]|Map\s*[.<]'
    r'|\w[\w.()\[\]]*\s*\.\s*(?:toList|toSet|sublist|split|cast|getStringList)\s*(?:<[^>]*>)?\s*\([^()]*\)'
    r'|\w+\s*\.\s*(?:where|map|entries|keys|values)\b[^;]*\.(?:toList|toSet)\(\))';

/// One arm of a ternary declaration: a literal (whose brackets the generic
/// pattern above cannot span — `[...associations]` is one) or any ordinary
/// fresh right-hand side.
const _ternaryArm = r'(?:\[[^\[\]]*\]|\{[^{}]*\}|' + _freshRhs + r')';

/// `name = ` — the head `_decl`, `_freshIndex` and `_ternaryFresh` share.
///
/// Every pattern that splices a fragment in stays on ONE line: a `+` split
/// across lines is what `prefer_interpolation_to_compose_strings` flags, and
/// this file has to be both format-clean and lint-clean.
const _declHead = r'\b' + _typed + r'(?<name>[A-Za-z_$][\w$]*)\s*=\s*';

/// A declaration whose two ternary arms are both copies, so the sort that
/// follows mutates one of them: `cond ? [copy] : other.where(..).toList()`.
const _ternaryPrefix = _declHead + r'[^;{}]*?\?\s*';
const _ternaryFirst = _ternaryPrefix + _ternaryArm;
const _ternaryPattern = _ternaryFirst + r'\s*:\s*' + _ternaryArm;

final _ternaryFresh = RegExp(_ternaryPattern, multiLine: true);

/// `final bucket = owned[key];` — an element of a container this file built.
const _indexTail = r'(?<base>[A-Za-z_$][\w$]*)\s*\[';

final _freshIndex = RegExp(_declHead + _indexTail, multiLine: true);

/// NOTE: Dart RAW strings do NOT interpolate. `r'...$_freshRhs'` compiles to a
/// pattern containing the literal text `$freshRhs`, which still parses as a
/// valid regex and simply never matches — a silent failure that cost an hour
/// and looked like a classification bug, not a string-literal bug. So the
/// patterns that splice a fragment in are built by CONCATENATION, never by
/// interpolation inside `r'...'`.
final _decl = RegExp(_declHead + _freshRhs, multiLine: true);

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

/// True when [base] was declared in THIS file as a collection literal whose
/// contents are literals too.
///
/// This is the proof behind `bucket = owned[id]` and
/// `for (x in owned.values)`: the container was allocated here, and every
/// value in it was allocated here, so a value handed out through it is local
/// to this call. A map holding somebody else's lists (`{'a': shared}`) fails
/// the `:` check and is left as a finding — the rule buys provable safety, not
/// the appearance of it.
bool _ownsItsValues(String src, String base) {
  final m = RegExp(r'\b' + RegExp.escape(base) + r'\s*=\s*([^;]*;)')
      .firstMatch(src);
  if (m == null) return false;
  final rhs = m.group(1)!.trimLeft();
  final startsAsLiteral =
      rhs.startsWith('{') ||
      rhs.startsWith('[') ||
      RegExp(r'^<[^;]*?>\s*[{[]').hasMatch(rhs);
  if (!startsAsLiteral) return false;
  for (final c in RegExp(r':').allMatches(m.group(1)!)) {
    final after = m.group(1)!.substring(c.end);
    if (!RegExp(r'^\s*(?:\[\]|<[^\[\]]*>\s*\[\])').hasMatch(after)) {
      return false;
    }
  }
  return true;
}

({
  Set<String> fresh,
  Set<String> fields,
  Set<String> object,
  Set<String> nonlist,
})
declarations(String src) {
  final fresh = <String>{};
  final fields = <String>{};
  final object = <String>{};
  final nonlist = <String>{};

  // Direct facts first: a name is fresh because its own right-hand side is a
  // copy, a literal or a fresh constructor. The rules below derive names from
  // OTHER names, so they run afterwards.
  for (final m in _reassign.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }
  for (final m in _decl.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }
  for (final m in _ternaryFresh.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }
  for (final m in _foldSeed.allMatches(src)) {
    fresh.add(m.namedGroup('name')!);
  }

  // Derived: a copy of a copy. Each guard is the proof that the container on
  // the right is local to this file.
  for (final m in _freshIndex.allMatches(src)) {
    final base = m.namedGroup('base')!;
    if (fresh.contains(base) && _ownsItsValues(src, base)) {
      fresh.add(m.namedGroup('name')!);
    }
  }
  for (final m in _freshValues.allMatches(src)) {
    final base = m.namedGroup('base')!;
    if (fresh.contains(base) && _ownsItsValues(src, base)) {
      fresh.add(m.namedGroup('name')!);
    }
  }

  for (final m in _objectAnnot.allMatches(src)) {
    object.add(m.namedGroup('name')!);
  }
  for (final m in _objectCtor.allMatches(src)) {
    object.add(m.namedGroup('name')!);
  }
  for (final m in _dateTimeDecl.allMatches(src)) {
    nonlist.add(m.namedGroup('name')!);
  }
  for (final m in _dateTimeRhs.allMatches(src)) {
    nonlist.add(m.namedGroup('name')!);
  }

  for (final line in src.split('\n')) {
    final m = _field.firstMatch(line);
    if (m != null) fields.add(m.namedGroup('name')!);
  }
  return (fresh: fresh, fields: fields, object: object, nonlist: nonlist);
}

/// Buckets a mutating call by what its receiver actually is.
///
/// [arg] is the text of the call's first argument, up to the first `)` or
/// `;` — enough to see a `Duration(` and know the receiver is a date.
Bucket classify(
  String recv,
  String method,
  String arg, {
  required Set<String> fresh,
  required Set<String> fields,
  required Set<String> object,
  required Set<String> nonlist,
}) {
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
  if (_control.contains(low) ||
      low.endsWith('controller') ||
      object.contains(tail) ||
      _registry.hasMatch(recv)) {
    return Bucket.control;
  }
  if (method == 'add' && _durationArg.hasMatch(arg)) {
    return Bucket.nonlist;
  }
  if (_nonlist.hasMatch(recv) || nonlist.contains(tail)) {
    return Bucket.nonlist;
  }
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
        final bucket = classify(
          recv,
          method,
          m.group(3) ?? '',
          fresh: decls.fresh,
          fields: decls.fields,
          object: decls.object,
          nonlist: decls.nonlist,
        );
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
