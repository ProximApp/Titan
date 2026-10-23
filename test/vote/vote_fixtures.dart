import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../shared/app_scaffold.dart';
import '../shared/fixtures.dart';

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
