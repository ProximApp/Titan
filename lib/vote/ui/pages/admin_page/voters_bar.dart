import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/providers/voter_list_provider.dart';
import 'package:titan/vote/providers/voting_group_list_provider.dart';
import 'package:titan/vote/ui/pages/admin_page/voter_chip.dart';

class VotersBar extends HookConsumerWidget {
  const VotersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voters = ref.watch(votingGroupListProvider);
    final votersNotifier = ref.watch(voterListProvider.notifier);
    final votersGroupId = voters.map((e) => e.id).toList();
    final groups = ref.watch(allGroupListProvider);
    final asyncStatus = ref.watch(statusProvider);
    VoteStatus status = VoteStatus(status: StatusType.open);
    asyncStatus.whenData((value) => status = value);
    return SizedBox(
      height: 50,
      child: groups.when(
        data: (data) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 15),
              ...data.map(
                (e) => VoterChip(
                  label: capitalize(e.name),
                  selected: votersGroupId.contains(e.id),
                  onTap: () async {
                    if (status.status == StatusType.waiting) {
                      if (votersGroupId.contains(e.id)) {
                        await votersNotifier.deleteVoter(
                          VoterGroup(groupId: e.id),
                        );
                      } else {
                        await votersNotifier.addVoter(
                          VoterGroup(groupId: e.id),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ),
        error: (Object error, StackTrace? stackTrace) =>
            Center(child: Text("Error : $error")),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
