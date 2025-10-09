import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/vote/repositories/voted_sections_repository.dart';

class VotedSectionProvider extends ListNotifier<String> {
  late final VotedSectionRepository votesRepository;

  @override
  AsyncValue<List<String>> build() {
    votesRepository = ref.watch(votedSectionRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> getVotedSections() async {
    return await loadList(votesRepository.getVotes);
  }

  void addVote(String id) {
    state.maybeWhen(
      data: (value) {
        state = AsyncData(value..add(id));
      },
      orElse: () {},
    );
  }
}

final votedSectionProvider =
    NotifierProvider<VotedSectionProvider, AsyncValue<List<String>>>(
      VotedSectionProvider.new,
    );
