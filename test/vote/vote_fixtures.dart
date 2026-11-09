import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/providers/list_list_provider.dart';
import 'package:titan/vote/providers/result_provider.dart';
import 'package:titan/vote/providers/sections_list_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/providers/voted_section_provider.dart';
import 'package:titan/vote/providers/votes_provider.dart';

import '../shared/app_scaffold.dart';
import '../shared/repository_stubs.dart';

/// Stubs the four reads every vote admin shell fans out to on mount: the
/// status switch, the section catalog, the list catalog and the voter
/// permission. Six shell files rebuilt this block by hand.
///
/// [sections] defaults to the one seeded section the admin page's cards and
/// forms expect; pass `const []` for the empty-list branch. [lists] defaults
/// to empty; pass the lists the page should render. [withResults] adds the
/// three reads only the closed/counting status panels reach (results, the
/// selected section's stats and the per-list logo 404).
void stubVoteAdmin(
  IntegrationScaffold scaffold, {
  required enums.StatusType status,
  List<SectionComplete>? sections,
  List<ListReturn>? lists,
  bool withResults = false,
}) {
  when(() => scaffold.repository.campaignStatusGet())
      .thenAnswer((_) async => chopperResponse(VoteStatus(status: status)));
  when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
    (_) async => chopperListResponse(
      sections ?? [sectionFixture('s-1', 'Bureau des Sports')],
    ),
  );
  when(() => scaffold.repository.campaignListsGet())
      .thenAnswer((_) async => chopperListResponse(lists ?? <ListReturn>[]));
  when(() => scaffold.repository.campaignVotersGet())
      .thenAnswer((_) async => chopperResponse(CorePermission.empty()));
  if (withResults) {
    // VoteBars reads the results (auto-loaded by resultProvider).
    when(() => scaffold.repository.campaignResultsGet()).thenAnswer(
      (_) async => chopperListResponse([
        AppModulesCampaignSchemasCampaignResult(listId: 'l-1', count: 12),
      ]),
    );
    // VoteCount's AutoLoaderChild fetches the selected section's count.
    when(
      () => scaffold.repository.campaignStatsSectionIdGet(
        sectionId: any(named: 'sectionId'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(VoteStats(sectionId: 's-1', count: 7)),
    );
    // Each list card auto-loads its logo.
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());
  }
}

/// The vote admin gate group.
const voteAdminGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';

/// A vote administrator carrying the module-admin group the `/vote/admin`
/// gate checks.
CoreUser voteAdminUserFixture() => CoreUser.empty().copyWith(
  groups: [
    CoreGroupSimple.empty().copyWith(id: voteAdminGroupId, name: 'admin_vote'),
  ],
);

/// Build the default section used by voting and campaign test fixtures.
SectionComplete sectionFixture(
  String id,
  String name, {
  String description = '',
}) => SectionComplete.empty().copyWith(
  id: id,
  name: name,
  description: description,
);

/// Build a campaign list with predictable vote-admin defaults.
ListReturn voteListFixture(
  String id,
  String name, {
  enums.ListType type = enums.ListType.serio,
  String description = 'Our program',
  SectionComplete? section,
}) => ListReturn.empty().copyWith(
  id: id,
  name: name,
  description: description,
  type: type,
  section: section ?? sectionFixture('s-1', 'Bureau des Sports'),
  members: const [],
);

/// A status answer held instead of read.
///
/// The campaign status decides which of a page's controls exist — the vote
/// button's label, the admin page's count/close/reset rows — and the real
/// notifier can only reach one status per boot through `campaignStatusGet`.
/// Pinning the answer lets one widget test walk every arm of that switch
/// while the widget code under test stays the real one.
class FakeVoteStatusNotifier extends StatusNotifier {
  FakeVoteStatusNotifier(this.answer);

  final AsyncValue<VoteStatus> answer;

  @override
  AsyncValue<VoteStatus> build() => answer;
}

/// The same, plus the five status transitions answered from a fixed outcome
/// instead of the backend: the error toasts only exist for a refused
/// transition, which a successful HTTP stub can never produce.
class FakeVoteStatusActions extends FakeVoteStatusNotifier {
  FakeVoteStatusActions(super.answer, {this.outcome = false});

  final bool outcome;

  @override
  Future<bool> openVote() async => outcome;

  @override
  Future<bool> closeVote() async => outcome;

  @override
  Future<bool> countVote() async => outcome;

  @override
  Future<bool> resetVote() async => outcome;

  @override
  Future<bool> publishVote() async => outcome;
}

/// `addVote`'s answer, which decides the success toast from the error one.
class FakeVotesNotifier extends VotesProvider {
  FakeVotesNotifier(this.outcome);

  final bool outcome;

  @override
  Future<bool> addVote(VoteBase votes) async => outcome;
}

/// The sections the campaign holds, without the `campaignSectionsGet` boot
/// call the real notifier makes (a widget test has no page to wait on).
class FakeSectionsNotifier extends SectionNotifier {
  FakeSectionsNotifier(this.answer);

  final AsyncValue<List<SectionComplete>> answer;

  @override
  AsyncValue<List<SectionComplete>> build() => answer;
}

/// Which sections the voter already voted in, held at any state so the
/// `maybeWhen` guards around it can answer loading and error too.
class FakeVotedSectionNotifier extends VotedSectionProvider {
  FakeVotedSectionNotifier(this.answer);

  final AsyncValue<List<String>> answer;

  @override
  AsyncValue<List<String>> build() => answer;
}

/// The campaign lists, held at any state: the admin page's pull-to-refresh
/// reads them a second time and falls back to an empty list when the read
/// did not land.
class FakeListListNotifier extends ListListNotifier {
  FakeListListNotifier(this.answer);

  final AsyncValue<List<ListReturn>> answer;

  @override
  AsyncValue<List<ListReturn>> build() => answer;
}

/// The per-section list map, held instead of derived, so a page that reads
/// `sectionsList[section]!.maybeWhen(...)` can be pointed at an entry that is
/// still loading.
class FakeSectionListNotifier extends SectionList {
  FakeSectionListNotifier(this.answer);

  final Map<SectionComplete, AsyncValue<List<ListReturn>>?> answer;

  @override
  Map<SectionComplete, AsyncValue<List<ListReturn>>?> build() => answer;
}

/// The campaign results, held instead of read: the chart pages load them on
/// mount, and a widget test only needs one state of that answer.
class FakeResultNotifier extends ResultNotifier {
  FakeResultNotifier(this.answer);

  final AsyncValue<List<AppModulesCampaignSchemasCampaignResult>> answer;

  @override
  AsyncValue<List<AppModulesCampaignSchemasCampaignResult>> build() => answer;
}
