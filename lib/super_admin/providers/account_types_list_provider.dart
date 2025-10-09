import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/super_admin/class/account_type.dart';
import 'package:titan/super_admin/repositories/account_type_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AccountTypesNotifier extends ListNotifier<AccountType> {
  AccountTypeRepository get accountTypeRepository =>
      ref.watch(accountTypeRepositoryProvider);

  @override
  AsyncValue<List<AccountType>> build() {
    loadAccountTypes();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<AccountType>>> loadAccountTypes() async {
    return await loadList(accountTypeRepository.getAccountTypeList);
  }
}

final allAccountTypesListProvider =
    NotifierProvider<AccountTypesNotifier, AsyncValue<List<AccountType>>>(
      AccountTypesNotifier.new,
    );
