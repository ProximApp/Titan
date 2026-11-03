import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override a notifier's build state with [value], retaining its concrete type
/// and all notifier methods.
///
/// This is the common path for tests that need data, loading, or error state
/// without adding a test-only subclass for one provider/module.
dynamic notifierBuildOverride<NotifierT extends Notifier<StateT>, StateT>(
  NotifierProvider<NotifierT, StateT> provider,
  StateT value,
) => provider.overrideWithBuild((_, _) => value);

/// Override a notifier's build state using a factory when the initial state
/// should be freshly constructed for every provider build.
dynamic
notifierBuildFactoryOverride<NotifierT extends Notifier<StateT>, StateT>(
  NotifierProvider<NotifierT, StateT> provider,
  StateT Function() create,
) => provider.overrideWithBuild((_, _) => create());
