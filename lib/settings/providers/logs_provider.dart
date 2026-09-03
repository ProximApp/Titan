import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class LogsProvider extends ListNotifier<Log> {
  @override
  AsyncValue<List<Log>> build() {
    return const AsyncValue.loading();
  }

  Logger get logger => ref.read(loggerProvider);

  Future<AsyncValue<List<Log>>> getLogs() async {
    return loadList(() async => logger.getLogs());
  }

  Future<bool> deleteLogs() async {
    return delete(
      (id) async => true,
      (listT, t) {
        logger.clearLogs();
        return [];
      },
      "",
      Log.empty(),
    );
  }
}

final logsProvider = NotifierProvider<LogsProvider, AsyncValue<List<Log>>>(
  LogsProvider.new,
);

class NotificationLogsProvider extends ListNotifier<Log> {
  @override
  AsyncValue<List<Log>> build() {
    return const AsyncValue.loading();
  }

  Logger get logger => ref.read(loggerProvider);

  Future<AsyncValue<List<Log>>> getLogs() async {
    return loadList(() async => logger.getNotificationLogs());
  }

  Future<bool> deleteLogs() async {
    return delete(
      (id) async => true,
      (listT, t) {
        logger.clearNotificationLogs();
        return [];
      },
      "",
      Log.empty(),
    );
  }
}

final notificationLogsProvider =
    NotifierProvider<NotificationLogsProvider, AsyncValue<List<Log>>>(
      NotificationLogsProvider.new,
    );
