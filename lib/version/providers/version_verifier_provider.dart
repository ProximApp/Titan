import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/version/class/version.dart';
import 'package:titan/version/repositories/version_repository.dart';

class VersionVerifierNotifier extends SingleNotifier<Version> {
  late final VersionRepository versionRepository;

  @override
  AsyncValue<Version> build() {
    versionRepository = ref.watch(versionRepositoryProvider);
    loadVersion();
    return const AsyncLoading();
  }

  Future<AsyncValue<Version>> loadVersion() async {
    return await load(versionRepository.getVersion);
  }
}

final versionVerifierProvider =
    NotifierProvider<VersionVerifierNotifier, AsyncValue<Version>>(
      VersionVerifierNotifier.new,
    );
