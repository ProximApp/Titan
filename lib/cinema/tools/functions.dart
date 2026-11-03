import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:titan/tools/image_compression.dart';

String formatDuration(int duration) {
  final hours = duration ~/ 60;
  final minutes = duration % 60;
  if (hours == 0) {
    return "${minutes}m";
  } else if (minutes == 0) {
    return "${hours}h";
  } else {
    return "${hours}h ${minutes}min";
  }
}

String formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year} - ${date.hour.toString().padLeft(2, "0")}h${date.minute.toString().padLeft(2, "0")}";
}

/// Parses the form's `hours:minutes` duration.
///
/// The controller can be blank or half-typed when Save is tapped, and the
/// old `int.parse` turned that into a `FormatException` from an `onTap` —
/// a button that does nothing. An unreadable duration is 0 minutes; the
/// server-side validation is what rejects an empty film length.
int parseDuration(String duration) {
  final parts = duration.split(":");
  final hours = int.tryParse(parts[0].trim()) ?? 0;
  final minutes = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
  return hours * 60 + minutes;
}

String parseDurationBack(int duration) {
  final hours = duration ~/ 60;
  final minutes = duration % 60;
  return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}";
}

Future<Uint8List> getFromUrl(String url) async {
  final bytes = (await http.get(Uri.parse(url))).bodyBytes;
  // Posters come from whatever URL was typed in, so they can be over the size
  // Hyperion accepts. Bytes we fail to compress are kept as they are, the
  // upload will report the problem.
  return await compressImageForUpload(bytes) ?? bytes;
}
