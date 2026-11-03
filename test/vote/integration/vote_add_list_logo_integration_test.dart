import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../../shared/image_stub.dart';
import '../../shared/repository_stubs.dart';
import '../vote_fixtures.dart';

/// Creating a list WITH a picture.
///
/// The existing create test submits a text-only form, so the page never had
/// `logo.value != null`: the picked-bytes preview (which is a different
/// `DecorationImage` branch from the loaded-file one) and the create-side
/// logo upload — the list whose id the POST just answered with — were both
/// unreachable. This test picks a real in-memory PNG through the platform
/// fake and asserts the upload targets the NEW id, not the empty draft.
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

  testWidgets('a list created with a picture uploads it to the new id', (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubVoteAdmin(scaffold, status: enums.StatusType.waiting);
    stubImagePicker();
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());
    when(() => scaffold.repository.campaignListsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async => chopperResponse(
            ListReturn.empty().copyWith(
              id: 'l-new',
              name: 'Liste Pique-Assiette',
              section: sectionFixture('s-1', 'Bureau des Sports'),
              type: enums.ListType.serio,
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
    await settle(tester);

    await tester.tap(find.byType(CustomIconButton));
    for (var i = 0; i < 20 && find.text('Add a list').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Add a list'), findsOneWidget);

    // Pick the picture: the platform fake hands the page in-memory bytes, so
    // both notifiers fill and the preview switches to the picked-bytes arm.
    await tester.tap(find.byType(ImagePickerOnTap));
    await settle(tester, frames: 12);
    expect(
      find.byType(ImagePickerOnTap),
      findsOneWidget,
      reason: 'the preview area stays mounted after a pick',
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Liste Pique-Assiette',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Des repas, de la convivialité',
    );
    await tester.enterText(find.byType(TextField).at(2), 'Un banquet par mois');
    await settle(tester, frames: 4);

    await tester.dragUntilVisible(
      find.text('Add'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 20);

    verify(
      () => scaffold.repository.campaignListsPost(body: any(named: 'body')),
    ).called(1);
    // The upload follows the create and addresses the returned id.
    verify(
      () => scaffold.repository.campaignListsListIdLogoPost(
        listId: 'l-new',
        image: any(named: 'image'),
      ),
    ).called(1);
    expect(find.text('List added'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
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
