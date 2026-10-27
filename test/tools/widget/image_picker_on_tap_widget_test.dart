import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart'
    as platform;
import 'package:titan/tools/functions.dart' show TypeMsg;
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';

import '../../shared/app_scaffold.dart';

/// A 1x1 PNG — small enough to pass `compressImageForUpload` untouched.
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// The only way in is the real [ImagePicker]; faking the platform interface
/// keeps pick → read → compress → notifiers alive (the same pattern the
/// recommendation form test uses).
class _FakePickerPlatform extends platform.ImagePickerPlatform {
  XFile? next;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    platform.ImagePickerOptions options = const platform.ImagePickerOptions(),
  }) async => next;
}

void main() {
  late _FakePickerPlatform fake;
  late platform.ImagePickerPlatform original;

  setUp(() {
    original = platform.ImagePickerPlatform.instance;
    fake = _FakePickerPlatform();
    platform.ImagePickerPlatform.instance = fake;
  });

  tearDown(() {
    platform.ImagePickerPlatform.instance = original;
  });

  /// Mounts [ImagePickerOnTap] around a tappable child.
  testWidgets('a cancelled picker leaves both notifiers alone', (tester) async {
    final bytesNotifier = ValueNotifier<Uint8List?>(null);
    final imageNotifier = ValueNotifier<Image?>(null);
    addTearDown(bytesNotifier.dispose);
    addTearDown(imageNotifier.dispose);
    String? toast;

    await pumpWidgetAt(
      tester,
      ImagePickerOnTap(
        picker: ImagePicker(),
        imageBytesNotifier: bytesNotifier,
        imageNotifier: imageNotifier,
        displayToastWithContext: (type, message) => toast = '$type',
        child: const Text('pick me'),
      ),
    );

    fake.next = null;
    await tester.tap(find.text('pick me'));
    await tester.pumpAndSettle();

    expect(bytesNotifier.value, isNull);
    expect(imageNotifier.value, isNull);
    expect(toast, isNull);
  });

  testWidgets('a picked image lands compressed in both notifiers', (
    tester,
  ) async {
    final bytesNotifier = ValueNotifier<Uint8List?>(null);
    final imageNotifier = ValueNotifier<Image?>(null);
    addTearDown(bytesNotifier.dispose);
    addTearDown(imageNotifier.dispose);
    String? toast;

    await pumpWidgetAt(
      tester,
      ImagePickerOnTap(
        picker: ImagePicker(),
        imageBytesNotifier: bytesNotifier,
        imageNotifier: imageNotifier,
        displayToastWithContext: (type, message) => toast = '$type',
        child: const Text('pick me'),
      ),
    );

    fake.next = XFile.fromData(_tinyPng, name: 'tiny.png');
    await tester.tap(find.text('pick me'));
    await tester.pumpAndSettle();

    expect(bytesNotifier.value, isNotNull);
    expect(imageNotifier.value, isA<Image>());
    expect(toast, isNull);
  });

  testWidgets('a photo too big to compress reports the size toast', (
    tester,
  ) async {
    final bytesNotifier = ValueNotifier<Uint8List?>(null);
    final imageNotifier = ValueNotifier<Image?>(null);
    addTearDown(bytesNotifier.dispose);
    addTearDown(imageNotifier.dispose);
    String? toast;

    await pumpWidgetAt(
      tester,
      ImagePickerOnTap(
        picker: ImagePicker(),
        imageBytesNotifier: bytesNotifier,
        imageNotifier: imageNotifier,
        displayToastWithContext: (type, message) => toast = '$type',
        child: const Text('pick me'),
      ),
    );

    // Over the 1 MB upload cap, and not decodable as an image, so the
    // compressor gives up and the widget reports the size instead.
    fake.next = XFile.fromData(Uint8List(1024 * 1024 + 4096), name: 'big.bin');
    await tester.tap(find.text('pick me'));
    // compressImageForUpload runs on a real isolate for the big payload.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(toast, '${TypeMsg.error}');
    expect(bytesNotifier.value, isNull);
    expect(imageNotifier.value, isNull);
  });
}
