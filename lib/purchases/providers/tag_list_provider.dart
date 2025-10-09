import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/repositories/scanner_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class TagListNotifier extends ListNotifier<String> {
  ScannerRepository get scannerRepository =>
      ref.watch(scannerRepositoryProvider);
  AsyncValue<List<String>> tagList = const AsyncValue.loading();

  @override
  AsyncValue<List<String>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> loadTags(
    String sellerId,
    String productId,
    String generatorId,
  ) async {
    return await loadList(
      () => scannerRepository.getTags(sellerId, productId, generatorId),
    );
  }
}

final tagListProvider =
    NotifierProvider<TagListNotifier, AsyncValue<List<String>>>(
      TagListNotifier.new,
    );
