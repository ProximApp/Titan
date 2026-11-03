class HistoryInterval {
  final DateTime start;
  final DateTime end;

  HistoryInterval(this.start, this.end);

  @override
  String toString() {
    return 'HistoryInterval(start: $start, end: $end)';
  }

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// The interval ending today, starting the same day one month earlier.
  ///
  /// [now] is injectable so the month-end clamp can be pinned against real
  /// Dec-31 / Jan-31 / Feb-28 dates instead of whatever day the suite runs on.
  factory HistoryInterval.currentMonth({DateTime? now}) {
    final end = now ?? DateTime.now();
    return HistoryInterval(
      _sameDayLastMonth(end),
      DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }
}

/// The same day-of-month one month earlier, clamped to that month's length.
///
/// `DateTime(year, month - 1, day)` NORMALIZES rather than failing: on the
/// 31st it gives `DateTime(2026, 9, 31)` → 1 October, so the "last month"
/// interval silently became the current month (start 1 Oct, i.e. one day
/// after it should be). February makes the same thing happen on the 29th,
/// 30th and 31st.
DateTime _sameDayLastMonth(DateTime now) {
  final previous = DateTime(now.year, now.month - 1, 1);
  // Day 0 of the current month is the last day of the previous one.
  final lastDay = DateTime(now.year, now.month, 0).day;
  return DateTime(
    previous.year,
    previous.month,
    now.day <= lastDay ? now.day : lastDay,
  );
}
