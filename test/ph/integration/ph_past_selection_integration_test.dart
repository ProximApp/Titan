import 'package:chopper/chopper.dart' as chopper;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/ph/ui/pages/past_ph_selection_page/ph_card.dart';

import '../../shared/app_scaffold.dart';

/// A valid 1x1 PNG: PhCard renders the cover bytes as an Image.memory, and
/// invalid image data crashes the codec.
final coverPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

PaperComplete paper(String id, String name, int year, int month) =>
    PaperComplete.empty().copyWith(
      id: id,
      name: name,
      releaseDate: DateTime(year, month, 7),
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /ph/past_ph_selection renders the journal grid for the current year',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(() => scaffold.repository.phGet()).thenAnswer(
        (_) async => chopperListResponse([
          // In the past: shown. In the future: filtered out by the list.
          paper('p1', 'Journal May', 2026, 5),
          paper('p2', 'Journal December', 2026, 12),
        ]),
      );
      // Each card auto-loads its cover and renders the bytes directly.
      when(
        () => scaffold.repository.phPaperIdCoverGet(
          paperId: any(named: 'paperId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response.bytes(coverPng, 200),
          coverPng,
        ),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${PhRouter.root}${PhRouter.past_ph_selection}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The grid shows the year chip and only past journals of that year;
      // the cards are cover-image-only (the name is the download filename).
      expect(find.text('2026'), findsOneWidget);
      expect(find.byType(PhCard), findsOneWidget);
    },
  );
}
