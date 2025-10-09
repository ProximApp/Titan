import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/service/class/message.dart';
import 'package:titan/service/providers/firebase_token_provider.dart';
import 'package:titan/service/repositories/notification_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class MessagesProvider extends ListNotifier<Message> {
  NotificationRepository get notificationRepository =>
      ref.watch(notificationRepositoryProvider);
  String firebaseToken = "";

  @override
  AsyncValue<List<Message>> build() {
    final firebaseTokenFuture = ref.watch(firebaseTokenProvider);
    firebaseTokenFuture.then((value) => setFirebaseToken(value));
    return const AsyncValue.loading();
  }

  void setFirebaseToken(String token) {
    firebaseToken = token;
  }

  Future<AsyncValue<List<Message>>> getMessages() async {
    return await loadList(
      () async => notificationRepository.getMessages(firebaseToken),
    );
  }

  Future<bool> registerDevice() async {
    return await notificationRepository.registerDevice(firebaseToken);
  }

  Future<bool> forgetDevice() async {
    return await notificationRepository.forgetDevice(firebaseToken);
  }
}

final messagesProvider =
    NotifierProvider<MessagesProvider, AsyncValue<List<Message>>>(
      MessagesProvider.new,
    );
