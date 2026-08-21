import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Expands an RFC 5545 recurrence rule into the dates it produces.
///
/// This lives apart from `tools/functions.dart` on purpose: that file is
/// imported by almost the whole app, so having it reach for the Syncfusion
/// calendar pulled the entire calendar package into the eager chunk that every
/// visitor downloads before the first frame — for one function that only the
/// event module calls.
List<DateTime> getDateInRecurrence(String recurrenceRule, DateTime start) {
  if (recurrenceRule.isEmpty) {
    return [];
  }
  return SfCalendar.getRecurrenceDateTimeCollection(recurrenceRule, start);
}
