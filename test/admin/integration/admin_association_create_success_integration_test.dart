import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/widgets/text_entry.dart' as widgets;

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// The success half of the add-association modal: the POST answers a body, so
/// the list notifier's `add()` returns true, the page toasts the creation and
/// pops the sheet. `admin_association_write_integration_test.dart` covers the
/// refused half (a null body reads as a failure there).
///
/// A file of its own because the toast is the subject: the shell's global
/// overlay paints the first toast a file raises, and this journey needs it.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
  });

  testWidgets('a created association toasts and closes the sheet', (
    tester,
  ) async {
    when(() => scaffold.repository.associationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        Association.empty().copyWith(id: 'asso-1', name: 'BDE', groupId: 'g-1'),
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

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        id: 'user-1',
        groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
      ),
      groups: [
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Clubs'),
      ],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async => chopper.Response<Association>(
            http.Response('body', 200),
            Association.empty().copyWith(id: 'a-2', name: 'New BDE'),
          ),
        );

    await tester.tap(find.byType(CustomIconButton).first);
    await settle(tester, frames: 14);
    expect(find.text('Add association'), findsOneWidget);

    await tester.enterText(find.byType(widgets.TextEntry).first, 'New BDE');
    await tester.tap(find.text('Choose a group to manage this association'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    // The success arm is the only one that closes the sheet and says so.
    expect(find.text('Add association'), findsNothing);
    expect(find.text('Association created'), findsOneWidget);
    verify(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .called(1);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
  });
}
