// lib/utils/heart_rate_date_formatter.dart
import '../../blood_pressure/models/date_range_type.dart';

class HeartRateDateFormatter {
  static String format(DateTime date, DateRangeType type) {
    switch (type) {
      case DateRangeType.day:
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      case DateRangeType.week:
        // Return three-letter weekday
        return _weekdayInitial[date.weekday] ?? '';

      case DateRangeType.month:
        // Return just the date number
        return '${date.day}';

      case DateRangeType.year:
        // Return month initial
        return _monthInitial[date.month] ?? '';
    }
  }

  // Three-letter weekday mapping (matching Blood Pressure implementation)
  static const _weekdayInitial = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  // Single letter month mapping (matching Blood Pressure implementation)
  static const _monthInitial = {
    1: 'J',
    2: 'F',
    3: 'M',
    4: 'A',
    5: 'M',
    6: 'J',
    7: 'J',
    8: 'A',
    9: 'S',
    10: 'O',
    11: 'N',
    12: 'D',
  };
}
