/// The synthetic fixture both row-spacer implementations are pointed at.
///
/// Two genuinely unsafe classes (a bare `Text` and a bare `Column` sibling of
/// a `Spacer`) and three safe ones (an `Expanded` `Text`, a `Flexible`
/// `Column`, and a row with no `Spacer` at all). The unsafe half keeps the
/// detector's liveness honest when `lib/` reports zero hazards; the safe half
/// keeps it from flagging the shape convention 31 prescribes as the fix.
const rowSpacerFixtureSource = '''
class WithText {
  Widget build() => Row(
        children: [Text('label'), Spacer(), Text('trailing')],
      );
}

class WithColumn {
  Widget build() => Row(
        children: [Spacer(), Column(children: [Text('x')]), Spacer()],
      );
}

class SafeExpandedText {
  Widget build() => Row(
        children: [Expanded(child: Text('label')), Spacer()],
      );
}

class SafeFlexibleColumn {
  Widget build() => Row(
        children: [Flexible(child: Column(children: [Text('x')])), Spacer()],
      );
}

class SafeNoSpacer {
  Widget build() => Row(
        children: [Text('label'), Text('trailing')],
      );
}
''';

/// The classes the scan must report from [rowSpacerFixtureSource].
const unsafeRowSpacerClasses = <String>{'WithText', 'WithColumn'};

/// The classes the scan must classify clean from [rowSpacerFixtureSource].
const safeRowSpacerClasses = <String>{
  'SafeExpandedText',
  'SafeFlexibleColumn',
  'SafeNoSpacer',
};
