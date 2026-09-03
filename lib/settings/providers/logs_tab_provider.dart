import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogTabs { log, notification }

class LogTabsNotifier extends Notifier<LogTabs> {
  @override
  LogTabs build() => LogTabs.log;

  void setLogTabs(LogTabs tab) {
    state = tab;
  }
}

final logTabProvider = NotifierProvider<LogTabsNotifier, LogTabs>(
  LogTabsNotifier.new,
);
