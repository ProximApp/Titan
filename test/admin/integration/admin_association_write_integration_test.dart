import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
// Two different TextEntry widgets exist: the edit-association modal uses
// the styleguide one, the add-association modal the widgets one.
import 'package:titan/tools/ui/styleguide/text_entry.dart' as styleguide;
import 'package:titan/tools/ui/widgets/text_entry.dart' as widgets;

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

/// The admin associations sub-page (`/admin/association`, 110 uncovered
/// lines): rows with a manager-group subtitle and an auto-loaded logo,
/// the add-association modal (POST round-trip) and the per-row edit
/// modal (PATCH round-trip).
///
/// The pre-existing admin_associations_integration_test covers the empty
/// page shell; here the association list is populated so the rows, the
/// modals and the write endpoints are exercised for the first time.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
  });

  void stubPopulatedAssociations() {
    when(() => scaffold.repository.associationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        Association.empty().copyWith(id: 'asso-1', name: 'BDE', groupId: 'g-1'),
        Association.empty().copyWith(id: 'asso-2', name: 'BNE', groupId: 'g-1'),
      ]),
    );
    // The row icons auto-load the association logo; a 404 falls back to
    // the placeholder asset (same pattern as the advert tests).
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
  }

  // The association rows resolve their manager-group name from the group
  // list with a bare firstWhere: the group list must already hold g-1
  // when the rows first build, so the derived provider is pre-seeded
  // synchronously instead of racing groupsGet against the row mount.
  ProviderContainer pumpAssociations() => scaffold.makeContainer(
    user: adminUser,
    groups: [
      CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
      CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Clubs'),
    ],
  );

  // qlevar_router 1.12.4 only processes the init-path middleware chain on
  // the first navigation of the isolate, so every sub-page shell lives in
  // its own file with a single deep-link test (see the purchases NOTE).
  testWidgets('the association rows show name and manager group', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/association');
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('BNE'), findsOneWidget);
    expect(find.text('Manager group : Admins'), findsWidgets);
  });

  testWidgets('the add-association modal creates through the API', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(
      () => scaffold.repository.associationsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          chopper.Response<Association>(http.Response('body', 200), null),
    );

    // AdminTemplate's permanent animation makes pumpAndSettle-based
    // modal helpers time out: raw taps and a bounded frame pump instead.
    await tester.tap(find.byType(CustomIconButton).first);
    await settle(tester, frames: 14);

    expect(find.text('Add association'), findsOneWidget);
    expect(find.text('Association name'), findsOneWidget);
    expect(
      find.text('Choose a group to manage this association'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(widgets.TextEntry).first, 'New BDE');
    await tester.tap(find.text('Choose a group to manage this association'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);

    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    final captured =
        verify(
              () => scaffold.repository.associationsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as AppCoreAssociationsSchemasAssociationsAssociationBase;
    expect(captured.name, 'New BDE');
    expect(captured.groupId, 'g-2');
    await scaffold.drainToast(tester);
  });

  testWidgets('the edit-association modal patches through the API', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(
      () => scaffold.repository.associationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 14);

    expect(find.text('Edit association : BDE'), findsOneWidget);
    expect(find.text('Association name'), findsOneWidget);
    // Two row subtitles + the modal's group row all show this string.
    expect(find.text('Manager group : Admins'), findsNWidgets(3));
    // Nothing changed yet: confirm stays disabled.
    expect(find.text('Confirm'), findsOneWidget);

    await tester.enterText(
      find.byType(styleguide.TextEntry).first,
      'BDE Lille',
    );
    await settle(tester, frames: 4);
    await tester.tap(find.text('Manager group : Admins').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 20);

    expect(
      verify(
        () => scaffold.repository.associationsAssociationIdPatch(
          associationId: 'asso-1',
          body: captureAny(named: 'body'),
        ),
      ).captured.single.name,
      'BDE Lille',
    );
    await scaffold.drainToast(tester);
  });
}
