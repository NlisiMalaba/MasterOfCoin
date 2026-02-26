extension DateTimeExtensions on DateTime {
  /// Start of the month (first day at 00:00:00).
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// End of the month (last day at 23:59:59).
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Unix timestamp in seconds (for SQLite storage).
  int get toUnixSeconds => (this.millisecondsSinceEpoch / 1000).round();
}

/// Creates [DateTime] from Unix timestamp in seconds.
DateTime dateTimeFromUnixSeconds(int seconds) {
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
