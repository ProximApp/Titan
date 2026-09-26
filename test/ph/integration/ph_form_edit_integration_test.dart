import 'package:chopper/chopper.dart' as chopper;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/providers/ph_provider.dart';
import 'package:titan/ph/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../../shared/file_picker_stub.dart';

/// The edit arm of `/ph/admin/add_ph`: the selected journal comes from
/// phProvider (the pencil on the admin list does `setPh` before navigating),
/// so the page boots straight into edit mode — isEdit flips the button
/// labels, the submit path to `phPaperIdPatch`, and the picked-PDF branch
/// that re-uploads through `phPaperIdPdfPost`.

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    registerFallbackValue(<int>[]);
  });

  Future<ProviderContainer> pumpEditForm(
    WidgetTester tester,
    IntegrationScaffold scaffold,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: adminPhGroupId,
            name: 'admin_ph',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.phGet()).thenAnswer(
      (_) async => chopperListResponse(<PaperComplete>[
        paperFixture('p1', 'Journal March 2026', 2026),
        paperFixture('p2', 'Journal 2025', 2025),
      ]),
    );
    // Leave pdfGet unstubbed: nothing in the form chain reads it (the leaf
    // route replaces the pages above it), and any stray read lands in the
    // provider's AsyncError state instead of crashing the shell.

    // The list must be data by the time the submit runs: editPh refuses to
    // act on a loading state, and the pdf re-upload reads list.last.id.
    await container.read(phListProvider.notifier).loadPhList();
    // The pencil's setPh, done up front so the page boots in edit mode.
    container
        .read(phProvider.notifier)
        .setPh(paperFixture('p1', 'Journal March 2026', 2026));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhRouter.root}${PhRouter.admin}${PhRouter.add_ph}',
      pumpAndSettle: false,
    );
    await settle(tester);
    return container;
  }

  testWidgets('the edit form shows the picked journal and edit labels', (
    tester,
  ) async {
    await pumpEditForm(tester, scaffold);

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Edit PDF file'), findsOneWidget);
    // The journal is prefilled into the form field (the admin list card
    // below carries the same name as plain text, hence widgetWithText).
    expect(
      find.widgetWithText(TextFormField, 'Journal March 2026'),
      findsOneWidget,
    );
    expect(find.text('Mar 7, 2026'), findsOneWidget);
    // Add-mode-only strings stay absent.
    expect(find.text('Add a PDF file'), findsNothing);
  });

  // Runs LAST: its success path calls QR.back(), and a test that leaves the
  // router wedged breaks the next deep link in the same file.
  testWidgets('picking a pdf and submitting patches and re-uploads it', (
    tester,
  ) async {
    // Pump the edit form first — without it there is no page at all and the
    // very first tap below finds nothing (the rest of this body's comment
    // about QR.back() only makes sense once the form is on screen).
    await pumpEditForm(tester, scaffold);

    when(
      () => scaffold.repository.phPaperIdPatch(
        paperId: any(named: 'paperId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('', 200), null),
    );
    when(
      () => scaffold.repository.phPaperIdPdfPost(
        paperId: any(named: 'paperId'),
        pdf: any(named: 'pdf'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('', 200), null),
    );

    final picker = StubFilePicker();
    final previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = previousPicker);

    // Pick the replacement pdf: isEdit makes this flip editPdfProvider on.
    picker.queue.add(stubPick('replacement.pdf', size: 64));
    await tester.tap(find.text('Edit PDF file'));
    await settle(tester);
    expect(find.text('Edit PDF file'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await settle(tester);

    final patched = verify(
      () => scaffold.repository.phPaperIdPatch(
        paperId: captureAny(named: 'paperId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(patched[0], 'p1');
    expect((patched[1] as PaperUpdate).name, 'Journal March 2026');
    // editPdf was true, so the page re-uploads the pdf onto the LAST journal
    // of the list.
    verify(
      () => scaffold.repository.phPaperIdPdfPost(
        paperId: 'p2',
        pdf: any(named: 'pdf'),
      ),
    ).called(1);

    expect(find.text('Edited'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
