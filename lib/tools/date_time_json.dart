/// Serializes a [DateTime] to a UTC ISO-8601 string (with the 'Z' suffix).
String? dateTimeToJson(DateTime? date) {
  return date?.toUtc().toIso8601String();
}
