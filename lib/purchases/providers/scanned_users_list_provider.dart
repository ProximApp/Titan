import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/repositories/scanner_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/user/class/simple_users.dart';

class ScannedUsersListNotifier extends ListNotifier<SimpleUser> {
  ScannerRepository get scannerRepository =>
      ref.watch(scannerRepositoryProvider);
  AsyncValue<List<String>> tagList = const AsyncValue.loading();

  @override
  AsyncValue<List<SimpleUser>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<SimpleUser>>> loadUsers(
    String sellerId,
    String productId,
    String generatorId,
    String tag,
  ) async {
    return await loadList(
      () =>
          scannerRepository.getUsersList(sellerId, productId, generatorId, tag),
    );
  }
}

final scannedUsersListProvider =
    NotifierProvider<ScannedUsersListNotifier, AsyncValue<List<SimpleUser>>>(
      ScannedUsersListNotifier.new,
    );
