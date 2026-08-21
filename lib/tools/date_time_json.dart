/// Serializes a [DateTime] to a UTC ISO-8601 string (with the 'Z' suffix).
///
/// The API stores timezone-aware datetimes (UTC), so values are converted to
/// UTC before serialization.
String? dateTimeToJson(DateTime? date) {
  return date?.toUtc().toIso8601String();
}

/// Parses an API ISO-8601 string into a local [DateTime].
DateTime dateTimeFromJson(dynamic json) => DateTime.parse(json).toLocal();
