import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/widgets/text_entry.dart' as widgets;

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../admin_fixtures.dart';

/// The association page's pull-to-refresh, and the add modal's refusal: a
/// create the backend rejects keeps the modal open and reports the error
/// rather than closing as if it had saved.
void main() {
  late IntegrationScaffold scaffold;
  var associationsRequests = 0;

  setUp(() {
    scaffold = IntegrationScaffold();
    associationsRequests = 0;
  });

  Future<void> pumpAssociations(WidgetTester tester) async {
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.associationsGet()).thenAnswer((_) async {
      associationsRequests++;
      return chopperListResponse([
        Association.empty().copyWith(id: 'asso-1', name: 'BDE', groupId: 'g-1'),
      ]);
    });
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
      ]),
    );
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: adminUser,
        groups: [CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins')],
      ),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(find.text('BDE'), findsOneWidget);
  }

  testWidgets('pulling the association list reloads it', (tester) async {
    await pumpAssociations(tester);
    final before = associationsRequests;

    final refresher = tester.widget<Refresher>(find.byType(Refresher));
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 12);

    expect(associationsRequests, before + 1);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });

  testWidgets('a refused association creation says so and stays open', (
    tester,
  ) async {
    await pumpAssociations(tester);
    when(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .thenAnswer((_) async => chopperError<Association>(500));

    await tester.tap(find.byType(CustomIconButton).first);
    await settle(tester, frames: 14);
    await tester.enterText(find.byType(widgets.TextEntry).first, 'New BDE');
    await tester.tap(find.text('Choose a group to manage this association'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Admins').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    expect(
      anyVisibleTextContains(tester, 'error'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    // The refusal keeps the sheet and the typed name on screen.
    expect(find.text('Association name'), findsOneWidget);
    expect(find.text('New BDE'), findsOneWidget);
    verify(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .called(1);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });
}
