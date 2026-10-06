import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /vote/detail renders the pre-selected list', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // The detail page renders entirely from the client-side list state set
    // by the list pages. The main page mounts underneath with an empty
    // list, so no card (and no logo fetch) is rendered.
    when(
      () => scaffold.repository.campaignListsGet(),
    ).thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
    // The list logo auto-loads for the pre-seeded list; a 404 falls back to
    // the placeholder asset.
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
    container
        .read(listProvider.notifier)
        .setId(
          ListReturn.empty().copyWith(
            id: 'list-1',
            name: 'Race List',
            description: 'Assemble to race',
            section: SectionComplete.empty().copyWith(
              name: 'Bureau des Sports',
            ),
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Bureau des Sports'), findsOneWidget);
    expect(find.textContaining('Assemble to race'), findsOneWidget);
  });
}
