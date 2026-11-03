import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/cinema/providers/session_list_provider.dart';

class MainPageIndexNotifier extends Notifier<int> {
  int startPage = 0;

  @override
  int build() {
    final sessionList = ref.watch(sessionListProvider);
    return sessionList.maybeWhen(
      data: (sessionData) {
        if (sessionData.isEmpty) {
          startPage = 0;
          return 0;
        }
        // Copy before sorting: `sessionList`'s data belongs to the provider.
        final data = [...sessionData]
          ..sort((a, b) => a.start.compareTo(b.start));
        final now = DateTime.now();
        final centralElement =
            data.indexWhere((element) => element.start.isAfter(now)) %
            data.length;
        startPage = centralElement;
        return centralElement;
      },
      orElse: () {
        startPage = 0;
        return 0;
      },
    );
  }

  void setMainPageIndex(int event) {
    state = event;
  }

  void setStartPage(int page) {
    startPage = page;
  }

  void reset() {
    state = startPage;
  }
}

final mainPageIndexProvider = NotifierProvider<MainPageIndexNotifier, int>(
  () => MainPageIndexNotifier(),
);
