import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/vote/repositories/section_vote_count_repository.dart';

class SectionVoteCountNotifier extends SingleNotifier<int> {
  late final SectionVoteCountRepository repository;

  @override
  AsyncValue<int> build() {
    repository = ref.watch(sectionVoteCountRepositoryProvider);
    return const AsyncLoading();
  }

  Future<AsyncValue<int>> loadCount(String id) async {
    return await load(() => repository.getSectionVoteCount(id));
  }
}

final sectionVoteCountProvider =
    NotifierProvider<SectionVoteCountNotifier, AsyncValue<int>>(
      SectionVoteCountNotifier.new,
    );
