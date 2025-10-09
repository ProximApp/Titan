import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/vote/class/result.dart';
import 'package:titan/vote/repositories/result_repository.dart';

class ResultNotifier extends ListNotifier<Result> {
  late final ResultRepository resultRepository;

  @override
  AsyncValue<List<Result>> build() {
    resultRepository = ref.watch(resultRepositoryProvider);
    tokenExpireWrapperAuth(ref, () async {
      await loadResult();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Result>>> loadResult() async {
    return await loadList(resultRepository.getResult);
  }
}

final resultProvider =
    NotifierProvider<ResultNotifier, AsyncValue<List<Result>>>(
      ResultNotifier.new,
    );
