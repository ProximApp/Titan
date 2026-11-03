import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin/add_edit_association shows the add form',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: phonebookAdminGroupId,
              name: 'admin_phonebook',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(
        () => scaffold.repository.phonebookAssociationsGet(),
      ).thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Add mode: no association selected. TextEntry renders the label via
      // InputDecoration.labelText; canBeEmpty fields get " (Optional)".
      expect(find.text('Add an association'), findsOneWidget);
      expect(find.text('Association name'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
    },
  );

  testWidgets(
    'the add_edit_association form prefills from the selected association in edit mode',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: phonebookAdminGroupId,
              name: 'admin_phonebook',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
      );
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );

      container
          .read(associationProvider.notifier)
          .setAssociation(association('a-1', 'Robot Club'));
      container
          .read(associationGroupementProvider.notifier)
          .setAssociationGroupement(groupement('grp-1', 'Clubs'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Edit mode title (a second "Edit" is the submit Button's label).
      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.text('Robot Club'), findsOneWidget);
      expect(find.text('We build robots'), findsOneWidget);
    },
  );

  testWidgets('the editable groupement bar toggles chips and a failed '
      'delete toasts without closing the dialog', (tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([
        groupement('grp-1', 'Clubs'),
        groupement('grp-2', 'Culture'),
      ]),
    );
    when(
      () => scaffold.repository.phonebookGroupementsGroupementIdDelete(
        groupementId: any(named: 'groupementId'),
      ),
    ).thenAnswer((_) async => chopperError<AssociationGroupement>(400));

    // A pre-selected groupement is what drives the bar's ensureVisible
    // scroll effect on mount.
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    // The editable branch: the "+" chip leads, then both chips.
    expect(find.text('+'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);
    expect(find.text('Culture'), findsOneWidget);

    // Tap toggles both ways: selecting another chip swaps the selection,
    // tapping the selected chip resets it (the ternary's two arms).
    await tester.tap(find.text('Culture'));
    await settle(tester, frames: 4);
    expect(container.read(associationGroupementProvider).id, 'grp-2');
    await tester.tap(find.text('Culture'));
    await settle(tester, frames: 4);
    expect(container.read(associationGroupementProvider).id, '');

    // Long-press opens the edit dialog over the bar.
    await tester.longPress(find.text('Clubs'));
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // A rejected delete takes the error arm: toast, dialog stays open.
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 8);
    expect(find.text('Error deleting association groupement'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the dialog delete removes the chip and confirms with a toast', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([
        groupement('grp-1', 'Clubs'),
        groupement('grp-2', 'Culture'),
      ]),
    );
    String? deletedId;
    when(
      () => scaffold.repository.phonebookGroupementsGroupementIdDelete(
        groupementId: any(named: 'groupementId'),
      ),
    ).thenAnswer((inv) async {
      deletedId = inv.namedArguments[#groupementId] as String;
      return chopperResponseVoid();
    });

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    await tester.longPress(find.text('Clubs'));
    await tester.pump();
    await settle(tester, frames: 8);
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 8);

    // Success arm: real DELETE with the chip's id, the modal pops and the
    // chip leaves the list with it.
    expect(deletedId, 'grp-1');
    expect(find.text('Association groupement deleted'), findsOneWidget);
    expect(find.text('Clubs'), findsNothing);
    expect(find.text('Culture'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
