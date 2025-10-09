import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class ProductIdNotifier extends SingleNotifier<String> {
  final UserInformationRepository productIdRepository =
      UserInformationRepository();

  @override
  AsyncValue<String> build() {
    final token = ref.watch(tokenProvider);
    productIdRepository.setToken(token);
    return const AsyncValue.loading();
  }

  void setProductId(String i) {
    state = AsyncValue.data(i);
  }
}

final productIdProvider =
    NotifierProvider<ProductIdNotifier, AsyncValue<String>>(
      ProductIdNotifier.new,
    );
