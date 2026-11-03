import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';
import 'package:titan/vote/providers/list_members.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/image_stub.dart';
import '../../shared/repository_stubs.dart';
import '../vote_fixtures.dart';

/// Editing a list WITH a new picture, plus the member row's edit hook.
///
/// The edit-side logo branch uploads to the list being edited (the create
/// test covers the other one), and it is the only path that runs the
/// `orElse`-free `listList.maybeWhen(data: …)` arm before the upload. The
/// member card's `onEdit` is an empty closure in production code, but it
/// still has to be invoked for the modal's Edit button to do nothing rather
/// than throw.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubImagePicker() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = StubImagePicker(
      next: XFile.fromData(
        Uint8List.fromList(_pngBytes()),
        mimeType: 'image/png',
      ),
    );
    addTearDown(() => ImagePickerPlatform.instance = previous);
  }

  testWidgets(
    'an edited list uploads its new picture to the list id and its member row opens the modal',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubVoteAdmin(
        scaffold,
        status: enums.StatusType.waiting,
        lists: [voteListFixture('l-1', 'BDE')],
      );
      stubImagePicker();
      when(
        () => scaffold.repository.campaignListsListIdLogoGet(
          listId: any(named: 'listId'),
        ),
      ).thenAnswer((_) async => fileNotFound());
      when(
        () => scaffold.repository.campaignListsListIdPatch(
          listId: any(named: 'listId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(
          ListReturn.empty().copyWith(
            id: 'l-1',
            name: 'BDE',
            section: sectionFixture('s-1', 'Bureau des Sports'),
          ),
        ),
      );
      when(
        () => scaffold.repository.campaignListsListIdLogoPost(
          listId: any(named: 'listId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(AppTypesStandardResponsesResult.empty()),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 20);

      // The admin card opens the Edit/Delete modal; Edit carries the list
      // into the form.
      await tester.tap(find.text('BDE'));
      await settle(tester, frames: 12);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      for (
        var i = 0;
        i < 30 && find.byType(ImagePickerOnTap).evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.byType(ImagePickerOnTap), findsOneWidget);

      // A member row: its modal's Edit button calls the page's empty onEdit,
      // which must be a no-op rather than an unhandled callback.
      container.read(listMembersProvider.notifier).setMembers([
        ListMemberComplete(
          userId: 'u-1',
          role: 'Treasurer',
          user: CoreUserSimple.empty().copyWith(
            id: 'u-1',
            firstname: 'Jane',
            name: 'Doe',
          ),
        ),
      ]);
      await settle(tester, frames: 4);
      await tester.tap(find.text('Jane Doe'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      // The form's own submit is also labelled Edit, so the modal's button is
      // the last one in the tree.
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Edit').last);
      await settle(tester, frames: 6);
      expect(tester.takeException(), isNull);
      await scaffold.closeModal(tester);

      // New picture, then submit.
      await tester.tap(find.byType(ImagePickerOnTap));
      await settle(tester, frames: 12);
      // Program is a required field and the fixture leaves it empty; without
      // it validate() refuses the save and no PATCH would fire at all.
      await tester.enterText(
        find.byType(TextField).at(2),
        'Un banquet par mois',
      );
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Edit').last,
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit').last);
      await settle(tester, frames: 20);

      verify(
        () => scaffold.repository.campaignListsListIdPatch(
          listId: 'l-1',
          body: any(named: 'body'),
        ),
      ).called(1);
      verify(
        () => scaffold.repository.campaignListsListIdLogoPost(
          listId: 'l-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}

/// A decodable 1x1 PNG, pinned as a literal (convention 34: file-private).
List<int> _pngBytes() => <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0d,
  0x0a,
  0x2d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
