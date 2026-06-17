import 'package:intl/intl.dart';

class TrainUtils {
  static DateTime? parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '--') {
      return null;
    }

    try {
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(raw)) {
        final parts = raw.split(':');

        final now = DateTime.now();

        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      return DateFormat('hh:mm a').parse(raw);
    } catch (_) {
      return null;
    }
  }

  static String formatTime(String? raw) {
    final dt = parseTime(raw);

    if (dt == null) {
      return '--';
    }

    return DateFormat('hh:mm a').format(dt);
  }

  static int? delayMinutes(
      String? scheduled,
      String? actual,
      ) {
    final sch = parseTime(scheduled);
    final act = parseTime(actual);

    if (sch == null || act == null) {
      return null;
    }

    final diff = act.difference(sch).inMinutes;

    return diff <= 0 ? null : diff;
  }

  static bool stationHasArrived(
      Map<String, dynamic> station,
      ) {
    final value =
        station['actual_arrival_time']?.toString() ?? '';

    return value.isNotEmpty && value != '--';
  }

  static bool stationHasDeparted(
      Map<String, dynamic> station,
      ) {
    final value =
        station['actual_departure_time']?.toString() ?? '';

    return value.isNotEmpty && value != '--';
  }
}