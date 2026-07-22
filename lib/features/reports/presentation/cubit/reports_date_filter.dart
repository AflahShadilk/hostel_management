/// Available preset date filters for the P&L report.
enum ReportsDateFilter {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

extension ReportsDateFilterLabel on ReportsDateFilter {
  String get label {
    switch (this) {
      case ReportsDateFilter.today:
        return 'Today';
      case ReportsDateFilter.thisWeek:
        return 'This Week';
      case ReportsDateFilter.thisMonth:
        return 'This Month';
      case ReportsDateFilter.thisYear:
        return 'This Year';
      case ReportsDateFilter.custom:
        return 'Custom';
    }
  }

  /// Returns a [from, to] date pair for this filter, based on [now].
  (DateTime from, DateTime to) resolve(DateTime now) {
    switch (this) {
      case ReportsDateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case ReportsDateFilter.thisWeek:
        final weekday = now.weekday; // Monday = 1
        final start = DateTime(now.year, now.month, now.day - (weekday - 1));
        return (start, now);
      case ReportsDateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return (start, now);
      case ReportsDateFilter.thisYear:
        final start = DateTime(now.year, 1, 1);
        return (start, now);
      case ReportsDateFilter.custom:
        return (now, now); // caller overrides
    }
  }
}
