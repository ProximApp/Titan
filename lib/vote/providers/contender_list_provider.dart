import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/vote/class/contender.dart';
import 'package:titan/vote/repositories/contender_repository.dart';
import 'package:titan/vote/tools/functions.dart';

class ContenderListNotifier extends ListNotifier<Contender> {
  late final ContenderRepository contenderRepository;

  @override
  AsyncValue<List<Contender>> build() {
    contenderRepository = ref.watch(contenderRepositoryProvider);
    tokenExpireWrapperAuth(ref, () async {
      await loadContenderList();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Contender>>> loadContenderList() async {
    await loadList(contenderRepository.getContenders);
    shuffle();
    return state;
  }

  Future<bool> addContender(Contender contender) async {
    return await add(contenderRepository.createContender, contender);
  }

  Future<bool> updateContender(Contender contender) async {
    return await update(
      contenderRepository.updateContender,
      (contenders, contender) =>
          contenders
            ..[contenders.indexWhere((p) => p.id == contender.id)] = contender,
      contender,
    );
  }

  Future<bool> deleteContender(Contender contender) async {
    return await delete(
      contenderRepository.deleteContender,
      (contenders, contender) =>
          contenders..removeWhere((p) => p.id == contender.id),
      contender.id,
      contender,
    );
  }

  Future<bool> deleteContenders({ListType? type}) async {
    return await delete(
      contenderRepository.deleteContenders,
      (contenders, contender) =>
          contenders
            ..removeWhere((p) => type != null ? p.listType == type : true),
      listTypeToString(type),
      Contender.empty(),
    );
  }

  Future<AsyncValue<List<Contender>>> copy() async {
    return state.when(
      data: (contenders) async => AsyncValue.data(contenders),
      loading: () async => const AsyncValue.loading(),
      error: (error, stackTrace) async => AsyncValue.error(error, stackTrace),
    );
  }

  void shuffle() {
    state.maybeWhen(
      data: (contenders) {
        final serious = [];
        final fakes = [];
        final blank = [];
        for (var contender in contenders) {
          if (contender.listType == ListType.serious) {
            serious.add(contender);
          } else if (contender.listType == ListType.fake) {
            fakes.add(contender);
          } else {
            blank.add(contender);
          }
        }
        serious.shuffle();
        fakes.shuffle();
        blank.shuffle();
        state = AsyncValue.data([...fakes, ...serious, ...blank]);
      },
      orElse: () {},
    );
  }
}

final contenderListProvider =
    NotifierProvider<ContenderListNotifier, AsyncValue<List<Contender>>>(
      ContenderListNotifier.new,
    );
