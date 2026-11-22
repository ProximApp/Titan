import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// The image-picker and image-cropper platform seams, plus the PNG payload the
/// upload paths decode — one copy instead of the seven this used to be
/// (advert ×2, feed, phonebook, recommendation, settings and user each carried
/// their own).
///
/// Install with `ImagePickerPlatform.instance = fake` /
/// `ImageCropperPlatform.instance = fake` and restore the previous instance in
/// an `addTearDown`: a leaked fake silently absorbs the NEXT test's pick in
/// the same isolate, which looks like the page-under-test never opening its
/// picker.
///
/// A test that needs a fixed payload builds the [XFile] itself and hands it to
/// [StubImagePicker], so the bytes, name and mime type stay the test's choice:
///
/// ```dart
/// ImagePickerPlatform.instance = StubImagePicker(
///   next: XFile.fromData(await tester.runAsync(solidPng)),
/// );
/// ```
class StubImagePicker extends ImagePickerPlatform {
  StubImagePicker({this.next});

  /// What the next `getImageFromSource` resolves to. Left `null` (the
  /// default) it is the "the user cancelled" answer, which is what every
  /// cancel branch asserts on.
  XFile? next;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => next;
}

/// The cropper seam: [nextCrop] is what `cropImage` resolves to, and
/// [cropCalled] completes on the FIRST call so a test can await the app's
/// un-awaited `whenData` pipeline before tearing the container down (its
/// trailing `state = previousState` must not run against a disposed one).
class StubImageCropper extends ImageCropperPlatform {
  StubImageCropper({this.nextCrop});

  CroppedFile? nextCrop;

  /// Completed on the first crop call.
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

/// A genuinely decodable 8x8 green PNG: real codec-safe bytes for
/// `Image.memory` and every poster-upload path, without touching the disk.
Future<Uint8List> solidPng() async {
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
