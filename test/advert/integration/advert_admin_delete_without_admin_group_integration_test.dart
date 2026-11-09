import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The delete closure on `/advert/admin` has two arms that do the same thing,
/// one per `isAdminProvider`. The admin-group member's arm is covered by
/// `advert_admin_session_integration_test.dart`; this file covers the arm a
/// plain association member takes — the member who passes AdminMiddleware on
/// membership alone, without the `admin` group.
void main() {
  late IntegrationScaffold scaffold;
  final myAssociation = Association.empty().copyWith(
    id: 'asso-1',
    name: 'BDE de Lille',
  );
  final advert = AdvertComplete.empty().copyWith(
    id: 'a-1',
    title: 'Members only sale',
    content: 'From the association itself',
    advertiserId: 'asso-1',
    date: DateTime(2026, 5, 1),
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder trash() =>
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash);

  testWidgets('a member who is not an app admin can still delete an advert', (
    tester,
  ) async {
    // No `admin` group: the gate passes on membership, isAdminProvider stays
    // false, and the delete's other arm is the one that runs.
    final container = scaffold.makeContainer(myAssociations: [myAssociation]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.advertAdvertsGet())
        .thenAnswer((_) async => chopperListResponse([advert]));
    when(() => scaffold.repository.associationsGet())
        .thenAnswer((_) async => chopperListResponse([myAssociation]));
    // The association bar and the card auto-load logos; a 404 falls back to
    // the placeholder asset.
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
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
    when(
      () => scaffold.repository.advertAdvertsAdvertIdDelete(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AdvertRouter.root}${AdvertRouter.admin}',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);
    expect(find.text('Members only sale'), findsOneWidget);

    await tester.ensureVisible(trash());
    await settle(tester, frames: 2);
    await tester.tap(trash());
    await settle(tester, frames: 6);
    expect(find.text('Deleting'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    verify(
      () => scaffold.repository.advertAdvertsAdvertIdDelete(advertId: 'a-1'),
    ).called(1);
    expect(find.text('Members only sale'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
