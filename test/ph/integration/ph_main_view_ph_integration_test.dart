import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/ph/ui/pages/past_ph_selection_page/ph_card.dart';
import 'package:titan/ph/ui/pages/view_ph/view_ph.dart';
import 'package:pdfx/pdfx.dart';

import '../../shared/app_scaffold.dart';
import '../ph_fixtures.dart';

/// One journey from the ph main page: the last journal's pdf branch renders
/// (the list is non-empty), "See previous journals" opens the grid, and a
/// card tap opens the viewer. Both PdfViews open garbage/real bytes against
/// a pdf renderer that does not exist in tests — pdfx catches that into its
/// loading-error state, so the pages stay up and `settle()` (never
/// pumpAndSettle, the spinner runs forever) observes them.
///
/// A valid 1x1 PNG: PhCard renders the cover bytes as an Image.memory, and
/// invalid image data crashes the codec.
final coverPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'main shows the last journal pdf, then previous journals, then the viewer',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      when(() => scaffold.repository.phGet()).thenAnswer(
        (_) async => chopperListResponse(<PaperComplete>[
          paperFixture('p1', 'Journal March', 2026, 3),
        ]),
      );
      when(
        () =>
            scaffold.repository.phPaperIdPdfGet(paperId: any(named: 'paperId')),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response.bytes(utf8.encode('%PDF-1.4 fake'), 200),
          utf8.encode('%PDF-1.4 fake'),
        ),
      );
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
        initialPath: PhRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester);

      // Non-empty list: the last journal's pdf viewer replaces the empty
      // message, and a plain user gets no admin button.
      expect(find.text('No PH yet in database'), findsNothing);
      expect(find.byType(PdfView), findsOneWidget);
      expect(find.text('See previous journals'), findsOneWidget);

      await tester.tap(find.text('See previous journals'));
      await settle(tester);
      expect(find.byType(PhCard), findsOneWidget);

      // Tapping the card itself (not its download button) opens the viewer.
      await tester.tap(find.byType(PhCard));
      await settle(tester);
      expect(find.byType(ViewPhPage), findsOneWidget);
    },
  );
}
