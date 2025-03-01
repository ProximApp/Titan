import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/single_notifier%20copy.dart';
import 'package:titan/tools/repository/repository2.dart';

class VersionVerifierNotifier extends SingleNotifier2<CoreInformation> {
  late final Openapi versionRepository;

  @override
  AsyncValue<Version> build() {
    versionRepository = ref.watch(versionRepositoryProvider);
    loadVersion();
    return const AsyncLoading();
  }

  Future<AsyncValue<CoreInformation>> loadVersion() async {
    return await load(versionRepository.informationGet);
  }
}

final versionVerifierProvider =
    NotifierProvider<VersionVerifierNotifier, AsyncValue<Version>>(
      VersionVerifierNotifier.new,
    );
