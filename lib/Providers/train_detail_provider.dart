import 'dart:async';

import 'package:flutter/material.dart';

import '../models/coach_model.dart';
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

  int get currentStationIndex {
    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      if (TrainUtils.stationHasArrived(s) &&
          !TrainUtils.stationHasDeparted(s)) {
        return i;
      }
    }
    return -1;
  }

  int get lastDepartedIndex {
    int last = -1;
    for (int i = 0; i < liveStations.length; i++) {
      if (TrainUtils.stationHasDeparted(liveStations[i] as Map<String, dynamic>)) {
        last = i;
      }
    }
    return last;
  }

  bool get isTrainAtStation => currentStationIndex >= 0;

  int get activeIndex =>
      isTrainAtStation ? currentStationIndex : lastDepartedIndex;

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

  int get livePassedCount {
    int count = 0;
    for (final s in liveStations) {
      if (TrainUtils.stationHasDeparted(s as Map<String, dynamic>)) count++;
    }
    return count;
  }

  void init({
    required String trainNumber,
    required Map<String, dynamic> trainData,
  }) {
    _trainNumber = trainNumber;
    _trainData = Map<String, dynamic>.from(trainData);
    fetchLiveStatus();
    fetchCoachComposition();
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

  Future<void> fetchCoachComposition() async {
    coachLoading = true;
    coachError = null;
    notifyListeners();

    try {
      final jsonData = await _service.fetchCoachCompositionRaw(_trainNumber);

      if (jsonData['status']?['result'] == 'success') {
        final coaches = jsonData['body']?['coaches'] as List? ?? [];
        coachComposition =
            coaches.map((e) => e as Map<String, dynamic>).toList();
      } else {
        coachComposition = fallbackCoachComposition();
      }
    } catch (_) {
      coachComposition = fallbackCoachComposition();
      coachError = null;
    }

    coachLoading = false;
    notifyListeners();
  }

  Future<void> refresh({TrainProvider? trainProvider}) async {
    await fetchLiveStatus();
    await fetchCoachComposition();

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
