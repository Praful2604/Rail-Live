import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LiveStatusProvider extends ChangeNotifier {
  Timer? _refreshTimer;

  Map<String, dynamic>? liveStatus;
  bool liveLoading = false;
  String? liveError;
  String _trainNumber = '';

  // ── Init / lifecycle ─────────────────────────────────────────────

  void init(String trainNumber) {
    _trainNumber = trainNumber;
    fetchLiveStatus();
    _startAutoRefresh();
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
          (_) => fetchLiveStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── API call ─────────────────────────────────────────────────────

  Future<void> fetchLiveStatus() async {
    liveLoading = true;
    liveError = null;
    notifyListeners();

    try {
      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final uri = Uri.https(
        'indian-railway-irctc.p.rapidapi.com',
        '/api/trains/v1/train/status',
        {
          'departure_date': today,
          'isH5': 'true',
          'client': 'web',
          'train_number': _trainNumber,
        },
      );

      debugPrint("TRAIN NUMBER = $_trainNumber");

      final response = await http.get(uri, headers: {
        'x-rapidapi-host': 'indian-railway-irctc.p.rapidapi.com',
        'x-rapidapi-key': 'f6e08704ecmsha3ab93df2f22de0p1cf569jsnf7a107f723ae',
      });

      debugPrint("STATUS CODE: ${response.statusCode}");
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          jsonData['status']?['result'] == 'success') {
        final stations = jsonData['body']?['stations'] as List?;
        if (stations != null && stations.length > 1) {
          debugPrint("STATION FIELDS: ${stations[1]}");
        }
        liveStatus = jsonData;
      } else {
        liveError = jsonData['status']?['message']?['message'] ??
            'Unable to fetch live status';
      }
    } catch (e) {
      liveError = e.toString();
    }

    liveLoading = false;
    notifyListeners();
  }

  // ── Live status getters ──────────────────────────────────────────

  List<dynamic> get liveStations {
    try {
      return (liveStatus?['body']?['stations'] as List?) ?? [];
    } catch (_) {
      return [];
    }
  }

  String get liveTrainStatusMessage {
    final raw =
        liveStatus?['body']?['train_status_message']?.toString() ?? '';
    return raw.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get liveCurrentStation =>
      liveStatus?['body']?['current_station']?.toString() ?? '';

  bool get liveTerminated =>
      liveStatus?['body']?['terminated'] == true;

  String get liveTimeOfAvailability =>
      liveStatus?['body']?['time_of_availability']?.toString() ?? '';

  // ── Station state helpers ────────────────────────────────────────

  bool stationHasDeparted(Map<String, dynamic> s) {
    final d = s['actual_departure_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }

  bool stationHasArrived(Map<String, dynamic> s) {
    final d = s['actual_arrival_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }

  // ── Position helpers ─────────────────────────────────────────────

  int get currentStationIndex {
    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      if (stationHasArrived(s) && !stationHasDeparted(s)) return i;
    }
    return -1;
  }

  int get lastDepartedIndex {
    int last = -1;
    for (int i = 0; i < liveStations.length; i++) {
      if (stationHasDeparted(liveStations[i] as Map<String, dynamic>)) {
        last = i;
      }
    }
    return last;
  }

  bool get isTrainAtStation => currentStationIndex >= 0;

  int get _activeIndex =>
      isTrainAtStation ? currentStationIndex : lastDepartedIndex;

  double get trainProgressBetweenStations {
    final depIdx = lastDepartedIndex;
    if (depIdx < 0 || depIdx >= liveStations.length - 1) return 0.0;
    final nextIdx = depIdx + 1;

    final depStation = liveStations[depIdx] as Map<String, dynamic>;
    final nextStation = liveStations[nextIdx] as Map<String, dynamic>;

    final depTime = _parseTime(
        depStation['actual_departure_time']?.toString() ??
            depStation['departureTime']?.toString());
    final arrTime = _parseTime(nextStation['arrivalTime']?.toString());

    if (depTime == null || arrTime == null) return 0.5;
    final now = DateTime.now();
    final total = arrTime.difference(depTime).inSeconds;
    final elapsed = now.difference(depTime).inSeconds;
    if (total <= 0) return 0.5;
    return (elapsed / total).clamp(0.05, 0.95);
  }

  // ── Summary getters ──────────────────────────────────────────────

  String get liveCurrentDelayText {
    final idx = _activeIndex;
    if (idx < 0) return '0';
    final s = liveStations[idx] as Map<String, dynamic>;
    final dep = delayMinutes(s['departureTime']?.toString(),
        s['actual_departure_time']?.toString());
    if (dep != null && dep > 0) return dep.toString();
    final arr = delayMinutes(s['arrivalTime']?.toString(),
        s['actual_arrival_time']?.toString());
    if (arr != null && arr > 0) return arr.toString();
    return '0';
  }

  bool get liveIsOnTime {
    final d = liveCurrentDelayText.trim();
    return d == '0' || d.isEmpty;
  }

  String get liveNextStationName {
    final nextIdx =
    isTrainAtStation ? currentStationIndex + 1 : lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      return (liveStations[nextIdx] as Map<String, dynamic>)['stationName']
          ?.toString() ??
          '—';
    }
    return '—';
  }

  String get liveEtaForNext {
    final nextIdx =
    isTrainAtStation ? currentStationIndex + 1 : lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      final s = liveStations[nextIdx] as Map<String, dynamic>;
      return fmtTime(s['arrivalTime']?.toString());
    }
    return '—';
  }

  int get livePassedCount {
    int count = 0;
    for (final s in liveStations) {
      if (stationHasDeparted(s as Map<String, dynamic>)) count++;
    }
    return count;
  }

  // ── Train info card getters ──────────────────────────────────────

  String get departureTime {
    if (liveStations.isNotEmpty) {
      final src = liveStations.first as Map<String, dynamic>;
      final actual = src['actual_departure_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return fmtTime(actual);
      return fmtTime(src['departureTime']?.toString());
    }
    return '--';
  }

  String get arrivalTime {
    if (liveStations.isNotEmpty) {
      final dst = liveStations.last as Map<String, dynamic>;
      final actual = dst['actual_arrival_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return fmtTime(actual);
      return fmtTime(dst['arrivalTime']?.toString());
    }
    return '--';
  }

  String get status {
    if (liveTerminated) return 'Terminated';
    if (liveIsOnTime) return 'On Time';
    return '$liveCurrentDelayText min late';
  }

  String get duration {
    if (liveStations.length >= 2) {
      final depRaw = (liveStations.first
      as Map<String, dynamic>)['departureTime']?.toString();
      final arrRaw = (liveStations.last
      as Map<String, dynamic>)['arrivalTime']?.toString();
      final dep = _parseTime(depRaw);
      final arr = _parseTime(arrRaw);
      if (dep != null && arr != null) {
        int mins = arr.difference(dep).inMinutes;
        if (mins < 0) mins += 24 * 60;
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0 ? '${h}h' : '${h}h ${m}m';
      }
    }
    return '--';
  }

  // ── Time helpers ─────────────────────────────────────────────────

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '--') return null;
    final s = raw.trim();
    try {
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) {
        final parts = s.split(':');
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateFormat('hh:mm a').parse(s);
    } catch (_) {
      return null;
    }
  }

  String fmtTime(String? raw) {
    final dt = _parseTime(raw);
    if (dt == null) return '--';
    return DateFormat('hh:mm a').format(dt);
  }

  int? delayMinutes(String? scheduled, String? actual) {
    final sch = _parseTime(scheduled);
    final act = _parseTime(actual);
    if (sch == null || act == null) return null;
    final diff = act.difference(sch).inMinutes;
    return diff <= 0 ? null : diff;
  }

  // ── Halt time helper ─────────────────────────────────────────────

  String? getHaltTime(Map<String, dynamic> station) {
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

    final arr = _parseTime(station['arrivalTime']?.toString());
    final dep = _parseTime(station['departureTime']?.toString());
    if (arr != null && dep != null) {
      final diff = dep.difference(arr).inMinutes;
      if (diff > 0) return diff.toString();
    }

    return null;
  }
}