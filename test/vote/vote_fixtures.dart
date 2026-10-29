import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

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
