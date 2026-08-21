import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;

extension FileResponse on chopper.Response {
  /// The bytes of a file response, or nothing when the file could not be
  /// fetched.
  ///
  /// [chopper.Response.bodyBytes] hands back the raw payload whatever the
  /// status code, so an error page reads exactly like a real file: Hyperion
  /// answers a missing image with `404 {"detail": "File does not exist"}` and
  /// those bytes end up in `Image.memory`, which throws `Invalid image data`.
  /// An unsuccessful response has to read as "no bytes" instead, so that
  /// callers fall back to their placeholder.
  Uint8List get fileBytes => isSuccessful ? bodyBytes : Uint8List(0);
}
