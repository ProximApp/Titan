import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../../shared/file_picker_stub.dart';

/// The add-journal journey through `/ph/admin`: the parent admin page's
/// "Add a new journal" tap opens the form (a deferred route — this file's one
/// navigation journey), whose WaitingButton validates the missing PDF, posts
/// through `phPost` once a pick landed, and pops back with the success toast.
///
/// The date entry keeps its prefilled text: the submit parses it through
/// phParseDateEntry, which is what makes the untouched prefill round-trip.

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the add-journal journey validates, picks a pdf and posts', (
    tester,
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
        paperFixture('p1', 'Journal 2026', 2026),
      ]),
    );
    when(() => scaffold.repository.phPost(body: any(named: 'body'))).thenAnswer(
      (_) async => chopperResponse<PaperComplete>(
        PaperComplete.empty().copyWith(id: 'new-1', name: 'Journal April'),
      ),
    );

    // Pre-load the list so add()'s handleState sees data (the parent admin
    // page also reloads it on its own build).
    await container.read(phListProvider.notifier).loadPhList();

    final picker = StubFilePicker();
    final previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = previousPicker);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhRouter.root}${PhRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.text('Add a new journal'), findsOneWidget);

    // Journey: open the add form.
    await tester.tap(find.text('Add a new journal'));
    await settle(tester);
    expect(find.text('PH name'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Add a PDF file'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // No PDF picked: the else branch toasts and never posts.
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Missing information or PDF file'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    verifyNever(() => scaffold.repository.phPost(body: any(named: 'body')));

    // Over the size limit: toast, but the pick is still remembered on the
    // button label (filePickerResultProvider).
    picker.queue.add(stubPick('huge.pdf', size: 10000001));
    await tester.tap(find.text('Add a PDF file'));
    await settle(tester);
    expect(find.text('File too large'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('huge.pdf'), findsOneWidget);

    // Cancelling a later pick resets the label to the empty state.
    picker.queue.add(null);
    await tester.tap(find.text('huge.pdf'));
    await settle(tester);
    expect(find.text('Add a PDF file'), findsOneWidget);

    // A valid pick, then submit: phPost fires and the router pops back.
    picker.queue.add(stubPick('journal.pdf', size: 64));
    await tester.tap(find.text('Add a PDF file'));
    await settle(tester);
    expect(find.text('journal.pdf'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Journal April 2026',
    );
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.text('Add'));
    await settle(tester);

    final captured =
        verify(
              () => scaffold.repository.phPost(body: captureAny(named: 'body')),
            ).captured.single
            as PaperBase;
    expect(captured.name, 'Journal April 2026');
    expect(captured.releaseDate, DateTime(2000));
    // Back on the parent admin page with the success toast.
    expect(find.text('Add a new journal'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    // Drain the success toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
