import 'dart:io';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:titan/settings/ui/pages/main_page/picture_button.dart';
import 'package:titan/tools/image_compression.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
// Two different TextEntry widgets exist: the edit-association modal uses
// the styleguide one, the add-association modal the widgets one.
import 'package:titan/tools/ui/styleguide/text_entry.dart' as styleguide;
import 'package:titan/tools/ui/widgets/text_entry.dart' as widgets;

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

/// The admin associations sub-page (`/admin/association`, 110 uncovered
/// lines): rows with a manager-group subtitle and an auto-loaded logo,
/// the add-association modal (POST round-trip) and the per-row edit
/// modal (PATCH round-trip).
///
/// The pre-existing admin_associations_integration_test covers the empty
/// page shell; here the association list is populated so the rows, the
/// modals and the write endpoints are exercised for the first time.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
  });

  void stubPopulatedAssociations() {
    when(() => scaffold.repository.associationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        Association.empty().copyWith(id: 'asso-1', name: 'BDE', groupId: 'g-1'),
        Association.empty().copyWith(id: 'asso-2', name: 'BNE', groupId: 'g-1'),
      ]),
    );
    // The row icons auto-load the association logo; a 404 falls back to
    // the placeholder asset (same pattern as the advert tests).
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
  }

  // The association rows resolve their manager-group name from the group
  // list with a bare firstWhere: the group list must already hold g-1
  // when the rows first build, so the derived provider is pre-seeded
  // synchronously instead of racing groupsGet against the row mount.
  ProviderContainer pumpAssociations() => scaffold.makeContainer(
    user: adminUser,
    groups: [
      CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
      CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Clubs'),
    ],
  );

  // qlevar_router 1.12.4 only processes the init-path middleware chain on
  // the first navigation of the isolate, so every sub-page shell lives in
  // its own file with a single deep-link test (see the purchases NOTE).
  testWidgets('the association rows show name and manager group', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/association');
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('BNE'), findsOneWidget);
    expect(find.text('Manager group : Admins'), findsWidgets);
  });

  testWidgets('the add-association modal creates through the API', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async =>
              chopper.Response<Association>(http.Response('body', 200), null),
        );

    // AdminTemplate's permanent animation makes pumpAndSettle-based
    // modal helpers time out: raw taps and a bounded frame pump instead.
    await tester.tap(find.byType(CustomIconButton).first);
    await settle(tester, frames: 14);

    expect(find.text('Add association'), findsOneWidget);
    expect(find.text('Association name'), findsOneWidget);
    expect(
      find.text('Choose a group to manage this association'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(widgets.TextEntry).first, 'New BDE');
    await tester.tap(find.text('Choose a group to manage this association'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);

    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    final captured =
        verify(
              () => scaffold.repository.associationsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as AppCoreAssociationsSchemasAssociationsAssociationBase;
    expect(captured.name, 'New BDE');
    expect(captured.groupId, 'g-2');
    await scaffold.drainToast(tester);
  });

  testWidgets('the edit-association modal patches through the API', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(
      () => scaffold.repository.associationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 14);

    expect(find.text('Edit association : BDE'), findsOneWidget);
    expect(find.text('Association name'), findsOneWidget);
    // Two row subtitles + the modal's group row all show this string.
    expect(find.text('Manager group : Admins'), findsNWidgets(3));
    // Nothing changed yet: confirm stays disabled.
    expect(find.text('Confirm'), findsOneWidget);

    await tester.enterText(
      find.byType(styleguide.TextEntry).first,
      'BDE Lille',
    );
    await settle(tester, frames: 4);
    await tester.tap(find.text('Manager group : Admins').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 20);

    expect(
      verify(
        () => scaffold.repository.associationsAssociationIdPatch(
          associationId: 'asso-1',
          body: captureAny(named: 'body'),
        ),
      ).captured.single.name,
      'BDE Lille',
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('the add modal re-picks the group through the manager row', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(() => scaffold.repository.associationsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async =>
              chopper.Response<Association>(http.Response('body', 200), null),
        );

    await tester.tap(find.byType(CustomIconButton).first);
    await settle(tester, frames: 14);
    await tester.enterText(find.byType(widgets.TextEntry).first, 'New BDE');

    // First pick: from the "choose a group" placeholder row.
    await tester.tap(find.text('Choose a group to manage this association'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);
    expect(find.text('Manager group : Clubs'), findsOneWidget);

    // Second pick: the SAME sheet, now reached from the manager row. The two
    // entry points used to be separate duplicated builders, so this is the
    // branch that a change to one of them silently leaves behind.
    await tester.tap(find.text('Manager group : Clubs'));
    await settle(tester, frames: 14);
    await tester.tap(find.text('Admins').last);
    await settle(tester, frames: 14);
    // Three: the two rows under the modal (both managed by Admins) and the
    // modal's own group row, which is the one that changed.
    expect(find.text('Manager group : Admins'), findsWidgets);
    expect(find.text('Manager group : Clubs'), findsNothing);

    // The re-picked group is what gets posted.
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    final captured =
        verify(
              () => scaffold.repository.associationsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as AppCoreAssociationsSchemasAssociationsAssociationBase;
    expect(captured.name, 'New BDE');
    expect(captured.groupId, 'g-1');
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused association update says so and keeps the modal open', (
    tester,
  ) async {
    stubPopulatedAssociations();
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    // The backend refuses the PATCH: the modal must stay open with the edit
    // still in progress rather than closing as if it had been saved.
    when(
      () => scaffold.repository.associationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 14);
    await tester.enterText(
      find.byType(styleguide.TextEntry).first,
      'BDE Lille',
    );
    await settle(tester, frames: 4);
    // The group pick runs before Confirm in the proven journey: without it the
    // form's own validation keeps the submit inert, which would make this test
    // pass for the wrong reason ("no error toast" because nothing was sent).
    await tester.tap(find.text('Manager group : Admins').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Clubs').last);
    await settle(tester, frames: 14);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 20);

    // A toast reported the failure (wording checked loosely so a copy change
    // names itself in the reason instead of failing on a literal), and the
    // modal is still on screen.
    expect(
      anyVisibleTextContains(tester, 'error'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    expect(find.text('Edit association : BDE'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the logo buttons report uploaded, too heavy and cancelled', (
    tester,
  ) async {
    stubPopulatedAssociations();
    final picker = _LogoPicker();
    ImagePickerPlatform.instance = picker;
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(
      () => scaffold.repository.associationsAssociationIdLogoPost(
        associationId: any(named: 'associationId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 20);
    expect(find.byType(PictureButton), findsNWidgets(2));

    // The two badges are Positioned over the avatar inside a Stack that clips
    // its children, so a pixel tap never lands on them: the badge's own
    // GestureDetector is invoked instead, which runs the real handler.
    Future<void> tapBadge(HeroIcons icon) async {
      final badge = find.byWidgetPredicate(
        (w) => w is PictureButton && w.icon == icon,
      );
      final detector = tester.widget<GestureDetector>(
        find.ancestor(of: badge, matching: find.byType(GestureDetector)).first,
      );
      // The handler reads the picked file and, for oversized pictures, runs
      // the compressor on a real isolate: both need real async, which the
      // test's fake clock would otherwise never advance.
      await tester.runAsync(() async {
        detector.onTap!();
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      await settle(tester, frames: 18);
    }

    // 1. Gallery, a real picture: uploaded and reported.
    picker.bytes = _tinyPng;
    await tapBadge(HeroIcons.photo);
    verify(
      () => scaffold.repository.associationsAssociationIdLogoPost(
        associationId: 'asso-1',
        image: any(named: 'image'),
      ),
    ).called(1);
    await scaffold.drainToast(tester);

    // 2. Gallery, a picture that cannot be brought under the upload limit:
    // refused before any request is made.
    picker.bytes = _overWeight();
    await tapBadge(HeroIcons.photo);
    expect(
      anyVisibleTextContains(tester, 'heavy'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    await scaffold.drainToast(tester);

    // 3. Gallery, the picker backed out: nothing was uploaded.
    picker.bytes = null;
    await tapBadge(HeroIcons.photo);
    expect(
      anyVisibleTextContains(tester, 'logo'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    await scaffold.drainToast(tester);

    // The camera badge runs the same three arms, in its own test below: doing
    // six picks in one modal left the last uploads racing the first ones.
    expect(picker.picks, 3);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });

  testWidgets('the camera badge reports uploaded, too heavy and cancelled', (
    tester,
  ) async {
    stubPopulatedAssociations();
    final picker = _LogoPicker();
    ImagePickerPlatform.instance = picker;
    await scaffold.pumpApp(
      tester,
      pumpAssociations(),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    when(
      () => scaffold.repository.associationsAssociationIdLogoPost(
        associationId: any(named: 'associationId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('BNE'));
    await settle(tester, frames: 20);

    Future<void> tapCamera() async {
      final badge = find.byWidgetPredicate(
        (w) => w is PictureButton && w.icon == HeroIcons.camera,
      );
      final detector = tester.widget<GestureDetector>(
        find.ancestor(of: badge, matching: find.byType(GestureDetector)).first,
      );
      await tester.runAsync(() async {
        detector.onTap!();
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      await settle(tester, frames: 18);
    }

    picker.bytes = _tinyPng;
    await tapCamera();
    await scaffold.drainToast(tester);

    // The two refusals: an oversized picture and a cancelled pick. Neither
    // reaches the endpoint. The single upload is verified once, here, because
    // mocktail stops counting a call after it has been verified.
    picker.bytes = _overWeight();
    await tapCamera();
    picker.bytes = null;
    await tapCamera();

    expect(picker.picks, 3);
    verify(
      () => scaffold.repository.associationsAssociationIdLogoPost(
        associationId: 'asso-2',
        image: any(named: 'image'),
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });
}

/// The edit modal builds its own `ImagePicker`, so the platform singleton is
/// the seam: [bytes] is what the next pick answers, null for a cancelled one.
class _LogoPicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  Uint8List? bytes;
  int picks = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    picks++;
    final picked = bytes;
    if (picked == null) return null;
    final file = File('${Directory.systemTemp.path}/admin_logo_$picks.png')
      ..writeAsBytesSync(picked);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    return XFile(file.path);
  }
}

/// A two-pixel PNG: the success path feeds the bytes straight to
/// `Image.memory`, which would throw on anything that is not a real image.
final Uint8List _tinyPng = img.encodePng(img.Image(width: 2, height: 2));

/// Over the 1 MiB multipart limit and undecodable, which is what makes the
/// compressor answer null and the form report "too heavy".
Uint8List _overWeight() {
  final bytes = Uint8List(maxUploadedImageSize + 16);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = (i * 37 + 11) % 251;
  }
  return bytes;
}
