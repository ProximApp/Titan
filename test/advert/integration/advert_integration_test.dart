import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /advert renders the advert cards for a plain user',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      final advert = AdvertComplete.empty().copyWith(
        id: 'a-1',
        title: 'Garage sale',
        content: 'Everything must go this weekend',
        advertiserId: 'asso-1',
        date: DateTime(2026, 5, 1),
      );
      when(
        () => scaffold.repository.advertAdvertsGet(),
      ).thenAnswer((_) async => chopperListResponse([advert]));
      // The association bar and card header load the association list.
      when(() => scaffold.repository.associationsGet()).thenAnswer(
        (_) async => chopperListResponse([
          Association.empty().copyWith(id: 'asso-1', name: 'BDE'),
        ]),
      );
      // The card auto-loads the association logo; a 404 falls back to the
      // placeholder asset.
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
      // The card auto-loads the advert picture; a 404 is rendered as-is.
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
        initialPath: AdvertRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.text('BDE'), findsWidgets);
      // The title/content render inside a RichText (expandable text).
      expect(
        find.textContaining('Garage sale', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Everything must go', findRichText: true),
        findsWidgets,
      );
      // A plain user (no associations, no admin group) gets no admin button.
      expect(find.text('Admin'), findsNothing);
    },
  );
}
