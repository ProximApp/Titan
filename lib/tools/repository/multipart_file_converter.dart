import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:titan/generated/openapi.swagger.dart';

/// Gives every byte-based file part of a multipart request the filename and
/// content-type its bytes really have.
class MultipartFileConverter extends $JsonSerializableConverter {
  @override
  chopper.Request convertRequest(chopper.Request request) {
    final converted = super.convertRequest(request);
    if (!converted.multipart || converted.parts.isEmpty) {
      return converted;
    }
    return converted.copyWith(
      parts: [
        for (final part in converted.parts)
          if (part is chopper.PartValueFile<List<int>>)
            chopper.PartValueFile<http.MultipartFile>(
              part.name,
              http.MultipartFile.fromBytes(
                part.name,
                part.value,
                filename: part.name,
                contentType: _mediaTypeOf(part.name, part.value),
              ),
            )
          else
            part,
      ],
    );
  }
}

/// The media type a part's bytes actually are, or null when unrecognised, in
/// which case `MultipartFile.fromBytes` falls back to `application/octet-stream`
MediaType? _mediaTypeOf(String name, List<int> bytes) {
  final mimeType = lookupMimeType(name, headerBytes: bytes);
  return mimeType == null ? null : MediaType.parse(mimeType);
}
