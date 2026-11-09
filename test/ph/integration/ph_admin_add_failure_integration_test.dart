import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/file_picker_stub.dart';
import '../ph_fixtures.dart';

/// The add form's two edges the happy journey cannot show: its date entry
/// opens the real picker and writes the pick into the field, and a save the
/// backend refuses toasts instead of popping back.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the date entry picks a day and a refused save stays on the form',
    (tester) async {
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
      // The post is what the form reports on: a plain failure comes back as
      // `add()` answering false, which is the toast under test.
      when(() => scaffold.repository.phPost(body: any(named: 'body')))
          .thenThrow(Exception('ph refused'));

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

      await tester.tap(find.text('Add a new journal'));
      await settle(tester);
      expect(find.text('PH name'), findsOneWidget);

      // The picker opens on `now`, so the 15th of the shown month always exists.
      await tester.tap(find.byType(DateEntry));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final picked = DateTime(now.year, now.month, 15);
      expect(find.byType(DatePickerDialog), findsNothing);
      // `getOnlyDayDate` writes the locale's yMd shape into the field.
      expect(
        find.textContaining(picked.day.toString()),
        findsWidgets,
        reason: 'the picked day is now in the date field',
      );

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

      verify(() => scaffold.repository.phPost(body: any(named: 'body')))
          .called(1);
      expect(find.text('Add error'), findsOneWidget);
      // The form is still mounted: the save never popped the route.
      expect(find.text('PH name'), findsOneWidget);
      expect(find.text('Added'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
