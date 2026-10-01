import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/tools/repository/multipart_file_converter.dart';

/// A file part sent the way the generated API sends every upload: raw bytes
/// with no filename and no content-type, exactly what the converter rewrites.
chopper.Request multipartRequest(List<int> bytes, {String name = 'image'}) {
  return chopper.Request(
    'POST',
    Uri.parse('/upload'),
    Uri.parse('https://titan.example/'),
    parts: [chopper.PartValueFile<List<int>>(name, bytes)],
    multipart: true,
  );
}

/// The content-type the converter ends up giving the first file part.
///
/// `MediaType` has no value equality, so tests compare the `mimeType` string.
String partContentType(chopper.Request request) {
  final converted = MultipartFileConverter().convertRequest(request);
  final part =
      converted.parts.single as chopper.PartValueFile<http.MultipartFile>;
  return part.value.contentType.mimeType;
}

void main() {
  group('MultipartFileConverter', () {
    test('labels a JPEG part image/jpeg', () {
      expect(
        partContentType(
          multipartRequest(const [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
        ),
        'image/jpeg',
      );
    });

    test('labels a PNG part image/png', () {
      expect(
        partContentType(
          multipartRequest(const [
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
          ]),
        ),
        'image/png',
      );
    });

    test('labels a WEBP part image/webp', () {
      // "RIFF" <size> "WEBP"
      expect(
        partContentType(
          multipartRequest(const [
            0x52,
            0x49,
            0x46,
            0x46,
            0x00,
            0x00,
            0x00,
            0x00,
            0x57,
            0x45,
            0x42,
            0x50,
          ]),
        ),
        'image/webp',
      );
    });

    test('labels a PDF part application/pdf', () {
      expect(
        partContentType(
          multipartRequest([
            0x25,
            0x50,
            0x44,
            0x46,
            0x2D,
            0x31,
            0x2E,
            0x34,
          ], name: 'pdf'),
        ),
        'application/pdf',
      );
    });

    test('falls back to octet-stream for unrecognised bytes', () {
      expect(
        partContentType(multipartRequest(const [0xDE, 0xAD, 0xBE, 0xEF])),
        'application/octet-stream',
      );
    });

    test('keeps non-file parts untouched', () {
      final request = multipartRequest(const [
        0xFF,
        0xD8,
        0xFF,
      ]).copyWith(parts: const [chopper.PartValue<bool>('flag', true)]);
      final converted = MultipartFileConverter().convertRequest(request);
      expect(converted.parts, hasLength(1));
      expect(converted.parts.single, isA<chopper.PartValue<bool>>());
    });
  });
}
