import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Hyperion reads multipart bodies with python-multipart, which refuses any
/// part larger than 1024 KB and answers `400 Part exceeded maximum size of
/// 1024KB.` before the endpoint is even reached. Every picture we upload has
/// to fit under that.
const int maxUploadedImageSize = 1024 * 1024;

/// What the encoders aim for, a bit under the hard limit so the multipart
/// headers and the boundary cannot push the part over it.
const int _targetSize = 900 * 1024;

/// The successive (longest side, JPEG quality) attempts, from "barely touched"
/// to "small enough that nothing realistic is still over the limit".
const List<(int, int)> _steps = [
  (2048, 85),
  (1600, 80),
  (1280, 75),
  (1024, 70),
  (800, 60),
  (640, 50),
];

/// Shrinks [bytes] until the upload fits in [maxUploadedImageSize], returning
/// them untouched when they already do.
///
/// Returns null when the picture cannot be brought under the limit, which in
/// practice means the bytes are not an image any of our decoders understands.
///
/// `image_picker`'s `imageQuality` cannot do this job: the web implementation
/// silently ignores `imageQuality`, `maxWidth` and `maxHeight`, so on the web
/// the raw file the user picked is what would be uploaded.
Future<Uint8List?> compressImageForUpload(Uint8List bytes) async {
  if (bytes.length <= maxUploadedImageSize) {
    return bytes;
  }
  return compute(_compress, bytes);
}

Uint8List? _compress(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return null;
  }

  Uint8List? smallest;
  void keep(Uint8List candidate) {
    if (smallest == null || candidate.length < smallest!.length) {
      smallest = candidate;
    }
  }

  // JPEG has no alpha channel, so a picture that really uses transparency has
  // to stay a PNG or it comes back with a black background.
  final keepsAlpha = decoded.hasAlpha && _hasTransparentPixel(decoded);
  if (keepsAlpha) {
    for (final (dimension, _) in _steps) {
      final encoded = img.encodePng(_resize(decoded, dimension));
      if (encoded.length <= _targetSize) {
        return encoded;
      }
      keep(encoded);
    }
  }

  // Either the picture is opaque, or keeping its transparency costs more than
  // the server accepts: a JPEG over a white background beats a refused upload.
  final opaque = keepsAlpha ? _flattenOnWhite(decoded) : decoded;
  for (final (dimension, quality) in _steps) {
    final encoded = img.encodeJpg(_resize(opaque, dimension), quality: quality);
    if (encoded.length <= _targetSize) {
      return encoded;
    }
    keep(encoded);
  }

  final best = smallest;
  return best != null && best.length <= maxUploadedImageSize ? best : null;
}

/// Scales [image] down so its longest side is [dimension], leaving pictures
/// that are already smaller alone.
img.Image _resize(img.Image image, int dimension) {
  if (image.width <= dimension && image.height <= dimension) {
    return image;
  }
  final landscape = image.width >= image.height;
  return img.copyResize(
    image,
    width: landscape ? dimension : null,
    height: landscape ? null : dimension,
    interpolation: img.Interpolation.average,
  );
}

/// Walks the pixels until a translucent one shows up. Pictures taken with a
/// camera have no alpha channel at all and never reach this, so the full walk
/// only ever happens on a screenshot or an export that carries an unused alpha
/// channel.
bool _hasTransparentPixel(img.Image image) {
  final opaque = image.maxChannelValue;
  for (final pixel in image) {
    if (pixel.a < opaque) {
      return true;
    }
  }
  return false;
}

img.Image _flattenOnWhite(img.Image image) {
  final background = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 3,
  );
  img.fill(background, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(background, image);
}
