import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;
  final myAssociation = Association.empty().copyWith(id: 'asso-1', name: 'BDE');

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /advert/admin renders the member-owned advert cards',
    (tester) async {
      final container = scaffold.makeContainer(
        // The AdminMiddleware gate derives from this: a member passes.
        myAssociations: [myAssociation],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      final advert = AdvertComplete.empty().copyWith(
        id: 'a-1',
        title: 'Members only sale',
        content: 'From the association itself',
        advertiserId: 'asso-1',
        date: DateTime(2026, 5, 1),
      );
      when(
        () => scaffold.repository.advertAdvertsGet(),
      ).thenAnswer((_) async => chopperListResponse([advert]));
      when(
        () => scaffold.repository.associationsGet(),
      ).thenAnswer((_) async => chopperListResponse([myAssociation]));
      // The association bar and admin cards auto-load logos; a 404 falls
      // back to the placeholder asset.
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

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${AdvertRouter.root}${AdvertRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin page filters to the member's own adverts and renders the
      // admin card variant (plain Text, unlike the main page's RichText).
      expect(find.text('Members only sale'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
    },
  );
}
