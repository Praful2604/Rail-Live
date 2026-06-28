import 'dart:async';

import 'package:flutter/material.dart';


import '../services/train_detail_service.dart';
import '../utils/train_utils.dart';
import 'train_provider.dart';

class TrainDetailProvider extends ChangeNotifier {
  TrainDetailProvider({TrainDetailService? service})
      : _service = service ?? TrainDetailService();

  final TrainDetailService _service;
  Timer? _refreshTimer;

  String _trainNumber = '';
  Map<String, dynamic> _trainData = {};

  Map<String, dynamic>? liveStatus;
  bool liveLoading = false;
  String? liveError;

  List<Map<String, dynamic>> coachComposition = [];
  bool coachLoading = false;
  String? coachError;

  Map<String, dynamic> get trainData => _trainData;
  String get trainNumber => _trainNumber;

  String get trainName =>
      _trainData['trainName']?.toString() ??
          _trainData['train_name']?.toString() ??
          'Unknown Train';

  String get origin => _trainData['origin']?.toString() ?? '';
  String get destination => _trainData['destination']?.toString() ?? '';

  String get trainType =>
      _trainData['trainType']?.toString() ??
          _trainData['train_type']?.toString() ??
          '';

  String get runningDays {
    final days = _trainData['runningDays'];
    if (days == null) return '';
    if (days is List) return days.join(', ');
    return days.toString();
  }

  List<dynamic> get liveStations {
    try {
      return (liveStatus?['body']?['stations'] as List?) ?? [];
    } catch (_) {
      return [];
    }
  }

  String get liveTrainStatusMessage {
    final raw = liveStatus?['body']?['train_status_message']?.toString() ?? '';
    return raw.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get liveCurrentStation =>
      liveStatus?['body']?['current_station']?.toString() ?? '';

  bool get liveTerminated => liveStatus?['body']?['terminated'] == true;

  String get liveTimeOfAvailability =>
      liveStatus?['body']?['time_of_availability']?.toString() ?? '';

  String get departureTime {
    if (liveStations.isNotEmpty) {
      final src = liveStations.first as Map<String, dynamic>;
      final actual = src['actual_departure_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') {
        return TrainUtils.formatTime(actual);
      }
      return TrainUtils.formatTime(src['departureTime']?.toString());
    }
    return _trainData['departureTime']?.toString() ??
        _trainData['departure_time']?.toString() ??
        '--';
  }

  String get arrivalTime {
    if (liveStations.isNotEmpty) {
      final dst = liveStations.last as Map<String, dynamic>;
      final actual = dst['actual_arrival_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') {
        return TrainUtils.formatTime(actual);
      }
      return TrainUtils.formatTime(dst['arrivalTime']?.toString());
    }
    return _trainData['arrivalTime']?.toString() ??
        _trainData['arrival_time']?.toString() ??
        '--';
  }

  String get status {
    if (liveTerminated) return 'Terminated';
    if (liveIsOnTime) return 'On Time';
    return '$liveCurrentDelayText min late';
  }

  String get duration {
    if (liveStations.length >= 2) {
      final depRaw = (liveStations.first as Map<String, dynamic>)['departureTime']
          ?.toString();
      final arrRaw = (liveStations.last as Map<String, dynamic>)['arrivalTime']
          ?.toString();
      final formatted = TrainUtils.formatDuration(depRaw, arrRaw);
      if (formatted != '--') return formatted;
    }
    return _trainData['duration']?.toString() ?? '--';
  }

  // ─────────────────────────────────────────────────────────────────
  // CORE FIX: anchor everything to the API's current_station code.
  //
  // The API pre-fills actual_arrival_time / actual_departure_time for
  // ALL stations (even future ones), so we can't trust those fields
  // alone to decide whether a station has been passed.
  //
  // Strategy:
  //   1. Find the index of the station whose code matches
  //      liveStatus['body']['current_station']  ← authoritative source.
  //   2. Use stnSerialNumber as a fallback ranking.
  //   3. "current station" means the train is AT that station
  //      (arrived but not yet departed) OR it is the last departed
  //      station while the train is between stops.
  //   4. Only stations with index < currentStationIndex are "passed".
  // ─────────────────────────────────────────────────────────────────

  /// Index in liveStations of the API's reported current station.
  /// Returns -1 if not determinable.
  int get _anchorIndex {
    final currentCode = liveCurrentStation.trim().toUpperCase();
    if (currentCode.isEmpty) return -1;

    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      final code = (s['stationCode']?.toString() ?? '').trim().toUpperCase();
      if (code == currentCode) return i;
    }
    return -1;
  }

  /// True if the train is currently halted AT the anchor station
  /// (arrived but not yet departed).
  bool get isTrainAtStation {
    final idx = _anchorIndex;
    if (idx < 0) return false;
    final s = liveStations[idx] as Map<String, dynamic>;
    final hasActualArr = _hasValue(s['actual_arrival_time']);
    final hasActualDep = _hasValue(s['actual_departure_time']);
    // At station = arrived but NOT yet departed
    return hasActualArr && !hasActualDep;
  }

  /// Index of the station where the train currently is (halted).
  /// Returns -1 if the train is between stations.
  int get currentStationIndex => isTrainAtStation ? _anchorIndex : -1;

  /// Index of the last station the train has fully departed from.
  /// When the train is AT a station this is the station before it.
  /// Returns -1 if the train hasn't departed any station yet.
  int get lastDepartedIndex {
    if (isTrainAtStation) {
      // Train is halted: last departed = station before anchor
      return _anchorIndex - 1;
    }
    // Train is between stations: anchor IS the last departed station
    final idx = _anchorIndex;
    if (idx >= 0) return idx;

    // Fallback: scan for the last station with an actual departure time
    // but ONLY up to the first station that has NO actual arrival time,
    // to avoid trusting pre-filled future times.
    int last = -1;
    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      if (!_hasValue(s['actual_arrival_time'])) break; // stop at first unpassed station
      if (_hasValue(s['actual_departure_time'])) last = i;
    }
    return last;
  }

  int get activeIndex =>
      isTrainAtStation ? currentStationIndex : lastDepartedIndex;

  /// Whether a station at [index] has been passed (train has departed it).
  /// This is the single source of truth used by RouteTimelineCard.
  bool stationIsPassed(int index) {
    // Stations strictly before the anchor are always passed
    final anchor = _anchorIndex;
    if (anchor >= 0) return index < anchor;
    // No anchor: fall back to lastDepartedIndex
    return index <= lastDepartedIndex;
  }

  double get trainProgressBetweenStations {
    final depIdx = lastDepartedIndex;
    if (depIdx < 0 || depIdx >= liveStations.length - 1) return 0.0;
    final nextIdx = depIdx + 1;
    final depStation = liveStations[depIdx] as Map<String, dynamic>;
    final nextStation = liveStations[nextIdx] as Map<String, dynamic>;
    final depTime = TrainUtils.parseTime(
      depStation['actual_departure_time']?.toString() ??
          depStation['departureTime']?.toString(),
    );
    final arrTime =
    TrainUtils.parseTime(nextStation['arrivalTime']?.toString());
    if (depTime == null || arrTime == null) return 0.5;
    final now = DateTime.now();
    final total = arrTime.difference(depTime).inSeconds;
    final elapsed = now.difference(depTime).inSeconds;
    if (total <= 0) return 0.5;
    return (elapsed / total).clamp(0.05, 0.95);
  }

  String get liveCurrentDelayText {
    final idx = activeIndex;
    if (idx < 0) return '0';
    final s = liveStations[idx] as Map<String, dynamic>;
    final dep = TrainUtils.delayMinutes(
      s['departureTime']?.toString(),
      s['actual_departure_time']?.toString(),
    );
    if (dep != null && dep > 0) return dep.toString();
    final arr = TrainUtils.delayMinutes(
      s['arrivalTime']?.toString(),
      s['actual_arrival_time']?.toString(),
    );
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
      return TrainUtils.formatTime(s['arrivalTime']?.toString());
    }
    return '—';
  }

  /// Number of stations the train has passed through (departed from).
  /// Only counts stations up to and including lastDepartedIndex.
  int get livePassedCount {
    final depIdx = lastDepartedIndex;
    if (depIdx < 0) return 0;
    return depIdx + 1;
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  bool _hasValue(dynamic raw) {
    if (raw == null) return false;
    final s = raw.toString().trim();
    return s.isNotEmpty && s != '--' && s != 'null';
  }

  // ─────────────────────────────────────────────────────────────────
  // INIT / LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  void init({
    required String trainNumber,
    required Map<String, dynamic> trainData,
  }) {
    _trainNumber = trainNumber;
    _trainData = Map<String, dynamic>.from(trainData);
    fetchLiveStatus();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
          (_) => refresh(),
    );
  }

  Future<void> fetchLiveStatus() async {
    liveLoading = true;
    liveError = null;
    notifyListeners();

    try {
      final jsonData = await _service.fetchLiveStatus(_trainNumber);

      if (jsonData['status']?['result'] == 'success') {
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

  Future<void> refresh({TrainProvider? trainProvider}) async {
    await fetchLiveStatus();

    if (trainProvider != null) {
      await trainProvider.fetchTrain(_trainNumber);
      if (trainProvider.trainData != null) {
        _trainData = trainProvider.trainData!;
        notifyListeners();
      }
    }
  }

  void updateTrainData(Map<String, dynamic> data) {
    _trainData = Map<String, dynamic>.from(data);
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}