import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/functions.dart';

/// True when the form's two date fields cannot form a range.
///
/// A blank field is the form validator's business, but it must never reach
/// `processDateBack`'s `DateFormat.parse`: the save handler used to compare
/// the range whenever the END field looked like a date, so an empty start
/// threw a `FormatException` from an `onTap`. An unparseable value is
/// equally invalid rather than fatal.
bool hasInvalidBookingRange(String start, String end, String locale) {
  if (start.trim().isEmpty || end.trim().isEmpty) return true;
  // Time-only fields are combined with today's date by the caller.
  if (!start.contains('/') || !end.contains('/')) return false;
  try {
    return isDateBefore(
      processDateBack(end, locale),
      processDateBack(start, locale),
    );
  } on FormatException {
    return true;
  }
}

String weekDayToLocalizedString(BuildContext context, WeekDays day) {
  final loc = AppLocalizations.of(context)!;
  switch (day) {
    case WeekDays.monday:
      return loc.bookingWeekDayMon;
    case WeekDays.tuesday:
      return loc.bookingWeekDayTue;
    case WeekDays.wednesday:
      return loc.bookingWeekDayWed;
    case WeekDays.thursday:
      return loc.bookingWeekDayThu;
    case WeekDays.friday:
      return loc.bookingWeekDayFri;
    case WeekDays.saturday:
      return loc.bookingWeekDaySat;
    case WeekDays.sunday:
      return loc.bookingWeekDaySun;
  }
}
