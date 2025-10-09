import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/admin/repositories/user_invitation_repository.dart';

class UserInvitationNotifier extends Notifier {
  @override
  void build() {
    return;
  }

  Future<List<String>> createUsers(
    List<String> mailList,
    String? groupId,
  ) async {
    final userInvitationRepository = ref.watch(
      userInvitationRepositoryProvider,
    );
    return await userInvitationRepository.createUsers(mailList, groupId);
  }
}

final userInvitationProvider = NotifierProvider<UserInvitationNotifier, void>(
  () => UserInvitationNotifier(),
);
