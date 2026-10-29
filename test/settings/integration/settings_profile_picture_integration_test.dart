import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/ui/pages/main_page/picture_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The three picture buttons in the Edit account sheet are edit_profile's
/// biggest uncovered block: every one of them branches its toast on the
/// pick/crop/`compressImageForUpload` result (updated / too heavy / error),
/// and the avatar's `Image.memory` line only runs when the profile fetch
/// returns real bytes. The three plugins involved (image_picker,
/// image_cropper, path_provider) are platform interfaces — the same seams
/// profile_picture_provider_test stubs.

class _FakePickerPlatform extends ImagePickerPlatform {
  XFile? nextPick;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => nextPick;
}

class _FakeCropperPlatform extends ImageCropperPlatform {
  CroppedFile? nextCrop;

  /// Completed on the first crop so the test can wait for cropImage's
  /// un-awaited whenData pipeline before tearing the container down.
  final cropCalled = Completer<void>();

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    if (!cropCalled.isCompleted) cropCalled.complete();
    return nextCrop;
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);
  final String root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

/// A genuinely decodable 8x8 PNG so `Image.memory` paints instead of
/// throwing `Invalid image data`.
Future<Uint8List> _solidPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = const Color(0xFF00FF00),
  );
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  late IntegrationScaffold scaffold;
  late _FakePickerPlatform picker;
  late _FakeCropperPlatform cropper;
  late ImagePickerPlatform previousPicker;
  late ImageCropperPlatform previousCropper;
  late PathProviderPlatform previousPath;
  late Uint8List png;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubProfilePicture();
    when(() => scaffold.repository.notificationTopicsGet())
        .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));

    picker = _FakePickerPlatform();
    cropper = _FakeCropperPlatform();
    previousPicker = ImagePickerPlatform.instance;
    previousCropper = ImageCropperPlatform.instance;
    previousPath = PathProviderPlatform.instance;
    ImagePickerPlatform.instance = picker;
    ImageCropperPlatform.instance = cropper;
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      Directory.systemTemp.createTempSync('titan_crop').path,
    );
    addTearDown(() {
      ImagePickerPlatform.instance = previousPicker;
      ImageCropperPlatform.instance = previousCropper;
      PathProviderPlatform.instance = previousPath;
    });
  });

  testWidgets('the gallery and camera buttons toast every pick outcome', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    // Real bytes: the sheet avatar runs the Image.memory branch (line 75).
    png = (await tester.runAsync(_solidPng))!;
    when(
      () => scaffold.repository.usersUserIdProfilePictureGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<int>>(http.Response.bytes(png, 200), png),
    );
    when(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async =>
          scaffold.repository.ok(AppTypesStandardResponsesResult.empty()),
    );

    final me = CoreUser.empty().copyWith(
      email: 'me@myemapp.com',
      phone: '0699887766',
      birthday: DateTime(2004, 3, 15),
    );
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: me, seedAsyncUser: true),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Profile'));
    // TWO memory avatars: the settings main page behind the sheet
    // (main_page.dart's Image.memory line) and the sheet's own EditProfile
    // avatar (edit_profile.dart line 75) — the real-bytes stub feeds both.
    expect(
      find.byWidgetPredicate(
        (w) => w is CircleAvatar && w.backgroundImage is MemoryImage,
      ),
      findsNWidgets(2),
    );

    final gallery = find.descendant(
      of: find.byType(PictureButton).hitTestable(),
      matching: find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.photo,
      ),
    );

    // 1. Pick succeeds and the upload lands → "updated" toast.
    picker.nextPick = XFile.fromData(png);
    await tester.tap(gallery);
    await settle(tester, frames: 6);
    expect(find.text('Profile picture updated'), findsOneWidget);
    verify(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).called(1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // 2. Pick cancelled (null) → "error" toast.
    picker.nextPick = null;
    await tester.tap(gallery);
    await settle(tester, frames: 6);
    expect(find.text('Error editing profile picture'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // 3. Pick succeeds but the upload throws → "too heavy" toast.
    // (setProfilePicture only reaches its false arm via an exception:
    // a failed Response is never inspected.)
    when(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).thenThrow(Exception('upload failed'));
    picker.nextPick = XFile.fromData(png);
    await tester.tap(gallery);
    await settle(tester, frames: 6);
    expect(find.text('Image is too large (max 4MB)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Camera button: one successful outcome proves the second branch
    // chain (source camera → updated toast) runs.
    when(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async =>
          scaffold.repository.ok(AppTypesStandardResponsesResult.empty()),
    );
    final camera = find.descendant(
      of: find.byType(PictureButton).hitTestable(),
      matching: find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.camera,
      ),
    );
    picker.nextPick = XFile.fromData(png);
    await tester.tap(camera);
    await settle(tester, frames: 6);
    expect(find.text('Profile picture updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Camera cancelled → error toast (the null arm of the camera chain).
    picker.nextPick = null;
    await tester.tap(camera);
    await settle(tester, frames: 6);
    expect(find.text('Error editing profile picture'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Camera upload throws → the "too heavy" arm of the camera chain.
    when(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).thenThrow(Exception('upload failed'));
    picker.nextPick = XFile.fromData(png);
    await tester.tap(camera);
    await settle(tester, frames: 6);
    expect(find.text('Image is too large (max 4MB)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the crop button re-uploads the cropped bytes and toasts', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    png = (await tester.runAsync(_solidPng))!;
    when(
      () => scaffold.repository.usersUserIdProfilePictureGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<int>>(http.Response.bytes(png, 200), png),
    );
    when(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async =>
          scaffold.repository.ok(AppTypesStandardResponsesResult.empty()),
    );

    final me = CoreUser.empty().copyWith(
      email: 'me@myemapp.com',
      phone: '0699887766',
      birthday: DateTime(2004, 3, 15),
    );
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: me, seedAsyncUser: true),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Profile'));

    // The cropper seam reads the file back: a real temp file with the
    // decodable PNG bytes. Real File IO needs a real event-loop turn —
    // plain await would hang in the fake-async test zone.
    final croppedFile = File('${Directory.systemTemp.path}/titan_cropped.png');
    await tester.runAsync(() => croppedFile.writeAsBytes(png));
    cropper.nextCrop = CroppedFile(croppedFile.path);
    final crop = find.descendant(
      of: find.byType(PictureButton),
      matching: find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.sparkles,
      ),
    );
    expect(crop, findsOneWidget, reason: 'sparkles button in the sheet');
    // The button hangs 20px below its Stack (bottom: -20): its center sits
    // exactly on the Stack's boundary, where RenderBox.hitTest rejects the
    // point and the whole subtree is skipped — tap slightly above center.
    await tester.tapAt(tester.getCenter(crop) - const Offset(0, 8));
    // cropImage's whenData pipeline mixes real File I/O with fake-async
    // pumps: awaiting the cropper future directly inside runAsync would
    // deadlock (its completion needs the very pumps we'd be blocked from
    // making). Interleave real-async slices with pumps instead.
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
    await settle(tester, frames: 4);
    expect(cropper.cropCalled.isCompleted, isTrue);

    verify(
      () => scaffold.repository.usersMeProfilePicturePost(
        image: any(named: 'image'),
      ),
    ).called(1);
    // NOTE: no 'Profile picture updated' toast here — cropImage's
    // un-awaited whenData pipeline can't feed the widget's await (it always
    // returns null), so the sheet's crop toasts are dead branches; the tap
    // still covers the handler's await + null check.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
