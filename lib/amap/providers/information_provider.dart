import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/amap/class/information.dart';
import 'package:titan/amap/repositories/information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class InformationNotifier extends SingleNotifier<Information> {
  InformationRepository get informationRepository =>
      ref.watch(informationRepositoryProvider);

  @override
  AsyncValue<Information> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<Information>> loadInformation() async {
    return await load(informationRepository.getInformation);
  }

  Future<bool> createInformation(Information information) async {
    return await add(informationRepository.createInformation, information);
  }

  Future<bool> updateInformation(Information information) async {
    return await update(informationRepository.updateInformation, information);
  }

  Future<bool> deleteInformation(Information information) async {
    return await delete(
      informationRepository.deleteInformation,
      information,
      "",
    );
  }
}

final informationProvider =
    NotifierProvider<InformationNotifier, AsyncValue<Information>>(
      InformationNotifier.new,
    );
