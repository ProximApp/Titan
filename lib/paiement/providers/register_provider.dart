import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/repositories/users_me_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class RegisterNotifier extends SingleNotifier<bool> {
  UsersMeRepository get usersMeRepository =>
      ref.watch(usersMeRepositoryProvider);

  @override
  AsyncValue<bool> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<bool>> register() async {
    return await load(usersMeRepository.register);
  }
}

final registerProvider = NotifierProvider<RegisterNotifier, AsyncValue<bool>>(
  RegisterNotifier.new,
);
