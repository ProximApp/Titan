import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/user/class/user.dart';
import 'package:titan/user/repositories/user_repository.dart';

class UserNotifier extends SingleNotifier<User> {
  UserRepository get userRepository => ref.watch(userRepositoryProvider);

  @override
  AsyncValue<User> build() {
    return const AsyncValue.loading();
  }

  Future<bool> setUser(User user) async {
    return await add((u) async => u, user);
  }

  Future<AsyncValue<User>> loadUser(String userId) async {
    return await load(() async => userRepository.getUser(userId));
  }

  Future<AsyncValue<User>> loadMe() async {
    return await load(userRepository.getMe);
  }

  Future<bool> updateUser(User user) async {
    return await update(userRepository.updateUser, user);
  }

  Future<bool> updateMe(User user) async {
    return await update(userRepository.updateMe, user);
  }

  Future<bool> changePassword(
    String oldPassword,
    String newPassword,
    User user,
  ) async {
    return await userRepository.changePassword(
      oldPassword,
      newPassword,
      user.email,
    );
  }

  Future<bool> deletePersonal() async {
    return await userRepository.deletePersonalData();
  }

  Future<bool> askMailMigration(String mail) async {
    return await userRepository.askMailMigration(mail);
  }
}

final asyncUserProvider = NotifierProvider<UserNotifier, AsyncValue<User>>(
  UserNotifier.new,
);

final userProvider = Provider((ref) {
  return ref
      .watch(asyncUserProvider)
      .maybeWhen(
        data: (user) => user,
        orElse: () {
          return User.empty();
        },
      );
});
