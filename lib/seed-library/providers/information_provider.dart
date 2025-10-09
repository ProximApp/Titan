import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/seed-library/class/information.dart';
import 'package:titan/seed-library/repositories/information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class InformationNotifier extends SingleNotifier<Information> {
  late final InformationRepository informationRepository;

  @override
  AsyncValue<Information> build() {
    informationRepository = ref.watch(informationRepositoryProvider);
    tokenExpireWrapperAuth(ref, () async {
      loadInformation();
    });
    return const AsyncLoading();
  }

  Future<AsyncValue<Information>> loadInformation() async {
    return await load(informationRepository.getInformation);
  }

  Future<bool> updateInformation(Information information) async {
    return await update(informationRepository.updateInformation, information);
  }
}

final informationProvider =
    NotifierProvider<InformationNotifier, AsyncValue<Information>>(
      InformationNotifier.new,
    );

final syncInformationProvider = Provider<Information>((ref) {
  final info = ref.watch(informationProvider);
  return info.maybeWhen(data: (data) => data, orElse: Information.empty);
});
