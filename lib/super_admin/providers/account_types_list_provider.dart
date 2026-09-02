import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class AccountTypesNotifier extends ListNotifierAPI<String> {
  Openapi get accountTypeRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<String>> build() {
    loadAccountTypes();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> loadAccountTypes() async {
    return await loadList(accountTypeRepository.usersAccountTypesGet);
  }
}

final allAccountTypesListProvider =
    NotifierProvider<AccountTypesNotifier, AsyncValue<List<String>>>(
      AccountTypesNotifier.new,
    );
