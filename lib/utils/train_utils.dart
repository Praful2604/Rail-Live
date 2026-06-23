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

  static String? getHaltTime(Map<String, dynamic> station) {
    final candidates = [
      station['haltTime'],
      station['halt_time'],
      station['halt'],
      station['haltDuration'],
      station['halt_duration'],
      station['stopTime'],
      station['stop_time'],
    ];

    for (final val in candidates) {
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str != '0' && str != '--' && str != 'null') {
          return str;
        }
      }
    }

    final arr = parseTime(station['arrivalTime']?.toString());
    final dep = parseTime(station['departureTime']?.toString());
    if (arr != null && dep != null) {
      final diff = dep.difference(arr).inMinutes;
      if (diff > 0) return diff.toString();
    }

    return null;
  }

  static String formatDuration(String? depRaw, String? arrRaw) {
    final dep = parseTime(depRaw);
    final arr = parseTime(arrRaw);
    if (dep == null || arr == null) return '--';

    int mins = arr.difference(dep).inMinutes;
    if (mins < 0) mins += 24 * 60;
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}