import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:titan/tools/image_compression.dart';

Uint8List _jpegBytes({int width = 300, int height = 200}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 30, 90));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

/// Pseudo-random noise compresses poorly, so the JPEG stays over the limit.
Uint8List _noisyJpeg({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  var seed = 42;
  for (final pixel in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    pixel.r = seed & 0xff;
    pixel.g = (seed >> 8) & 0xff;
    pixel.b = (seed >> 16) & 0xff;
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

void main() {
  group('compressImageForUpload', () {
    test('returns small images untouched', () async {
      final bytes = _jpegBytes();

      expect(bytes.length, lessThanOrEqualTo(maxUploadedImageSize));

      final result = await compressImageForUpload(bytes);

      expect(result, same(bytes));
    });

    test('shrinks a huge opaque image under the upload limit', () async {
      // A noise-filled image barely compresses; encode at high quality until
      // the source is over the limit.
      final Uint8List bytes = _noisyJpeg(width: 3000, height: 3000);

      expect(bytes.length, greaterThan(maxUploadedImageSize));

      final result = await compressImageForUpload(bytes);

      expect(result, isNotNull);
      expect(result!.length, lessThanOrEqualTo(maxUploadedImageSize));
    });

    test('returns null for bytes no decoder understands', () async {
      final bytes = Uint8List.fromList(List.filled(2 * 1024 * 1024, 7));

      final result = await compressImageForUpload(bytes);

      expect(result, null);
    });
  });
}
