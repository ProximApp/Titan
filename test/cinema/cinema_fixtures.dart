import 'package:titan/generated/openapi.models.swagger.dart';

/// The cinema module's session builders: one copy instead of the six this
/// used to be (every integration test rebuilt `session` by hand).
///
/// Defaults are the "days away, two hours long" record the admin and main
/// pages render — [start] and [duration] are the two axes the flows differ
/// on, and [overview] / [genre] / [tagline] the copy the detail and edit
/// forms fill in.
CineSessionComplete session(
  String id,
  String name, {
  String? overview,
  String? genre,
  String? tagline,
  DateTime? start,
  int duration = 7200,
}) => CineSessionComplete.empty().copyWith(
  id: id,
  name: name,
  overview: overview ?? 'A heart-warming tale of $name',
  genre: genre,
  tagline: tagline,
  start: start ?? DateTime.now().add(const Duration(days: 3)),
  duration: duration,
);

/// The fixed instant the form-based cinema tests render their session at:
/// the add/edit/branch forms pre-fill it and assert the rendered date.
final fixedSessionStart = DateTime(2026, 12, 18, 20);

/// A session at the fixed instant the form flows render against, 120 minutes
/// long: `parseDurationBack` renders that duration as "02:00", which is what
/// the form-branch and edit-session tests assert on.
CineSessionComplete shortSession(
  String id,
  String name, {
  String? genre,
  String? tagline,
}) => session(
  id,
  name,
  start: fixedSessionStart,
  duration: 120,
  genre: genre,
  tagline: tagline,
);
