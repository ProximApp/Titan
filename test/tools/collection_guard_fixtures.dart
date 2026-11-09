/// The synthetic fixture both collection-guard implementations are pointed
/// at: one genuinely unsafe site per rule, plus the safe shapes that must be
/// classified clean.
///
/// One file per class on purpose — the detectors report the SOURCE file, so a
/// single file cannot tell `UnsafeBare` from `UnsafeChain`. `firstWhereOrNull`
/// is not imported anywhere: this is source text the detectors parse, never
/// code the suite compiles.
const collectionGuardFixtureFiles = <String, String>{
  'unsafe_bare.dart': '''
class UnsafeBare {
  String pick(List<String> names) => names.firstWhere((n) => n == 'x');
}
''',
  'unsafe_chain.dart': '''
class UnsafeChain {
  String pick(List<String> names) => names.where((n) => n == 'x').first;
}
''',
  'unsafe_unwrapped.dart': '''
class UnsafeUnwrapped {
  String pick(List<String> names) => names.firstWhereOrNull((n) => n == 'x')!;
}
''',
  'safe_or_else.dart': '''
class SafeOrElse {
  String pick(List<String> names) =>
      names.firstWhere((n) => n == 'x', orElse: () => '');
}
''',
  'safe_nullable.dart': '''
class SafeNullable {
  String? pick(List<String> names) => names.firstWhereOrNull((n) => n == 'x');
}
''',
  'safe_loop.dart': '''
class SafeIndexed {
  String? pick(List<String> names) {
    for (final name in names) {
      if (name == 'x') return name;
    }
    return null;
  }
}
''',
};

/// The rule each unsafe fixture FILE must be flagged with.
const unsafeCollectionGuards = <String, String>{
  'unsafe_bare.dart': 'bareFirstWhere',
  'unsafe_chain.dart': 'whereChainFirst',
  'unsafe_unwrapped.dart': 'unwrappedOptional',
};

/// The fixture files both implementations must classify clean.
const safeCollectionGuardFiles = <String>[
  'safe_or_else.dart',
  'safe_nullable.dart',
  'safe_loop.dart',
];
