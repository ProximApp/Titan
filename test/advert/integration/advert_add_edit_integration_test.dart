import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/providers/advert_provider.dart';
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
    'deep link to /advert/admin/add_edit_advert mounts the edit form pre-filled',
    (tester) async {
      final container = scaffold.makeContainer(myAssociations: [myAssociation]);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      container
          .read(advertProvider.notifier)
          .setAdvert(
            AdvertComplete.empty().copyWith(
              id: 'a-1',
              title: 'Summer fête',
              content: 'Bring everyone',
              advertiserId: 'asso-1',
              date: DateTime(2026, 5, 1),
            ),
          );
      // The association bar auto-loads logos; a 404 falls back to the
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

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${AdvertRouter.root}${AdvertRouter.admin}${AdvertRouter.addEditAdvert}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The form is pre-filled from the client-side advert state.
      expect(find.text('Summer fête'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    },
  );
}
