import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:titan/tools/image_compression.dart';

/// A picture no encoder can cheat on: pure noise, so it stays heavy until it
/// is actually resized.
img.Image noisyImage(int width, int height) {
  final random = Random(0);
  final image = img.Image(width: width, height: height, numChannels: 3);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return image;
}

/// Black and white noise: heavy enough to go over the limit, but compressible
/// enough that a PNG can still fit once resized, like the logos and stickers
/// people actually upload with a transparent background.
img.Image ditheredTransparentImage(int width, int height) {
  final random = Random(0);
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (final pixel in image) {
    final value = random.nextBool() ? 255 : 0;
    pixel
      ..r = value
      ..g = value
      ..b = value
      ..a = 255;
  }
  // A see-through corner, the way a logo has a see-through background.
  for (var y = 0; y < height ~/ 4; y++) {
    for (var x = 0; x < width ~/ 4; x++) {
      image.getPixel(x, y).a = 0;
    }
  }
  return image;
}

void main() {
  group('compressImageForUpload', () {
    test('leaves an image already under the limit untouched', () async {
      final bytes = img.encodeJpg(noisyImage(200, 200), quality: 90);
      expect(bytes.length, lessThan(maxUploadedImageSize));

      expect(await compressImageForUpload(bytes), same(bytes));
    });

    test('brings an oversized photo under the limit', () async {
      final bytes = img.encodePng(noisyImage(3000, 2000));
      expect(bytes.length, greaterThan(maxUploadedImageSize));

      final compressed = await compressImageForUpload(bytes);

      expect(compressed, isNotNull);
      expect(compressed!.length, lessThanOrEqualTo(maxUploadedImageSize));
      final decoded = img.decodeImage(compressed)!;
      expect(decoded.width, greaterThan(decoded.height));
      expect(decoded.width / decoded.height, closeTo(3 / 2, 0.01));
    });

    test('keeps the transparency of an oversized picture', () async {
      final bytes = img.encodePng(ditheredTransparentImage(3000, 3000));
      expect(bytes.length, greaterThan(maxUploadedImageSize));

      final compressed = await compressImageForUpload(bytes);

      expect(compressed, isNotNull);
      expect(compressed!.length, lessThanOrEqualTo(maxUploadedImageSize));
      final decoded = img.decodeImage(compressed)!;
      expect(decoded.hasAlpha, isTrue);
      expect(decoded.getPixel(0, 0).a, 0);
    });

    test('returns null when the bytes are not an image', () async {
      final bytes = Uint8List(maxUploadedImageSize + 1);

      expect(await compressImageForUpload(bytes), isNull);
    });
  });
}
