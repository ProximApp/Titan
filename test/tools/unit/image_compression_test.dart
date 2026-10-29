import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:titan/tools/image_compression.dart';

/// A random-noise image: noise barely compresses, which is exactly what
/// pushes an encoded picture over the multipart limit the uploader guards.
Uint8List noiseImage(
  int width,
  int height, {
  bool alpha = false,
  int seed = 7,
}) {
  final rnd = Random(seed);
  final image = img.Image(
    width: width,
    height: height,
    numChannels: alpha ? 4 : 3,
  );
  for (final pixel in image) {
    pixel.r = rnd.nextInt(256);
    pixel.g = rnd.nextInt(256);
    pixel.b = rnd.nextInt(256);
    if (alpha) pixel.a = rnd.nextInt(256);
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('images already under the limit are returned untouched', () async {
    final small = Uint8List.fromList(List.filled(1024, 1));
    final result = await compressImageForUpload(small);
    expect(identical(result, small), isTrue);
  });

  test('over-limit bytes that decode to nothing compress to null', () async {
    // Bigger than the cap but not an image any decoder understands: the
    // decode-failure arm of _compress.
    final garbage = Uint8List(maxUploadedImageSize + 1);
    expect(await compressImageForUpload(garbage), isNull);
  });

  test(
    'an opaque over-limit photo comes back as a JPEG under the cap',
    () async {
      final noisy = noiseImage(800, 800);
      expect(noisy.length, greaterThan(maxUploadedImageSize));

      final result = await compressImageForUpload(noisy);
      expect(result, isNotNull);
      expect(result!.length, lessThanOrEqualTo(maxUploadedImageSize));

      // The opaque path encodes JPEG — decodable, no alpha channel left.
      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.hasAlpha, isFalse);
    },
  );

  test('a wide opaque image is resized along its longest side', () async {
    // Width over every step dimension: the resize (not early-return) arm
    // of _resize runs for every attempt.
    final wide = noiseImage(2600, 700);
    expect(wide.length, greaterThan(maxUploadedImageSize));

    final result = await compressImageForUpload(wide);
    expect(result, isNotNull);
    expect(result!.length, lessThanOrEqualTo(maxUploadedImageSize));

    final decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(2048));
  });

  test(
    'a transparent over-limit image survives as a decodable picture',
    () async {
      // Random alpha always finds a translucent pixel: the transparency walk
      // runs, every PNG step stays over the target on noise, and the
      // flatten-on-white fallback carries it the rest of the way.
      final transparent = noiseImage(700, 700, alpha: true);
      expect(transparent.length, greaterThan(maxUploadedImageSize));

      final result = await compressImageForUpload(transparent);
      expect(result, isNotNull);
      expect(result!.length, lessThanOrEqualTo(maxUploadedImageSize));
      expect(img.decodeImage(result), isNotNull);
    },
  );
}
