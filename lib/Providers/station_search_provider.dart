import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/train_result.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class StationSuggestion {
  final String stationCode;
  final String stationName;

  const StationSuggestion({
    required this.stationCode,
    required this.stationName,
  });

  factory StationSuggestion.fromJson(Map<String, dynamic> json) {
    return StationSuggestion(
      stationCode: (json['station_code'] ?? json['stationCode'] ?? '')
          .toString()
          .trim()
          .toUpperCase(),
      stationName: (json['station_name'] ?? json['stationName'] ?? '')
          .toString()
          .trim(),
    );
  }

  @override
  String toString() => '$stationName ($stationCode)';
}

// ── Provider ──────────────────────────────────────────────────────────────────

class StationSearchProvider extends ChangeNotifier {
  // ── Station autocomplete ─────────────────────────────────────────
  List<dynamic> _allStations = [];
  List<StationSuggestion> sourceSuggestions = [];
  List<StationSuggestion> destSuggestions = [];

  StationSuggestion? selectedSource;
  StationSuggestion? selectedDest;

  // ── Results ──────────────────────────────────────────────────────
  List<TrainResult> trains = [];
  bool isLoading = false;
  String? error;

  // ── Local train data (trains.json) ───────────────────────────────
  // trains.json structure:
  // [
  //   {
  //     "train_number": "50103",
  //     "train_name": "DIVA-RATNAGIRI PASS",
  //     "running_days": { "monday": true, ... "sunday": true },
  //     "stops": ["Diva Junction", "Panvel", ..., "Ratnagiri"]
  //   },
  //   ...
  // ]
  List<dynamic> _allTrains = [];

  // ── Load data ────────────────────────────────────────────────────

  Future<void> loadStations() async {
    try {
      final raw = await rootBundle.loadString('assets/data/stations.json');
      _allStations = jsonDecode(raw);
      debugPrint('✅ Stations loaded: ${_allStations.length}');
    } catch (e) {
      debugPrint('⚠️ stations.json error: $e');
      _allStations = [];
    }

    try {
      final raw = await rootBundle.loadString('assets/data/trains.json');
      _allTrains = jsonDecode(raw);
      debugPrint('✅ Trains loaded: ${_allTrains.length}');
    } catch (e) {
      debugPrint('⚠️ trains.json error: $e');
      _allTrains = [];
    }
  }

  // ── Station autocomplete ──────────────────────────────────────────

  void searchSourceStation(String query) {
    sourceSuggestions = _filterStations(query);
    notifyListeners();
  }

  void searchDestStation(String query) {
    destSuggestions = _filterStations(query);
    notifyListeners();
  }

  List<StationSuggestion> _filterStations(String query) {
    if (query.trim().length < 2) return [];
    final q = query.trim().toLowerCase();
    return _allStations
        .where((s) {
          final name = (s['station_name'] ?? s['stationName'] ?? '')
              .toString()
              .toLowerCase();
          final code = (s['station_code'] ?? s['stationCode'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(q) || code.contains(q);
        })
        .take(15)
        .map((s) => StationSuggestion.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  void selectSource(StationSuggestion station) {
    selectedSource = station;
    sourceSuggestions = [];
    notifyListeners();
  }

  void selectDest(StationSuggestion station) {
    selectedDest = station;
    destSuggestions = [];
    notifyListeners();
  }

  void swapStations() {
    final temp = selectedSource;
    selectedSource = selectedDest;
    selectedDest = temp;
    trains = [];
    error = null;
    notifyListeners();
  }

  void clearAll() {
    selectedSource = null;
    selectedDest = null;
    sourceSuggestions = [];
    destSuggestions = [];
    trains = [];
    error = null;
    notifyListeners();
  }

  void clearSource() {
    selectedSource = null;
    sourceSuggestions = [];
    trains = [];
    error = null;
    notifyListeners();
  }

  void clearDest() {
    selectedDest = null;
    destSuggestions = [];
    trains = [];
    error = null;
    notifyListeners();
  }

  // ── Main search ───────────────────────────────────────────────────
  //
  // Purely local: find every train whose `stops` list contains both the
  // selected source and destination station names (case-insensitive),
  // with source appearing strictly before destination. No API call —
  // trains.json has no per-stop timing data.
  Future<void> fetchTrainsBetweenStations() async {
    if (selectedSource == null || selectedDest == null) {
      error = 'Please select both source and destination stations.';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    trains = [];
    notifyListeners();

    final fromName = selectedSource!.stationName;
    final toName = selectedDest!.stationName;

    debugPrint('🔍 Searching: $fromName → $toName');

    try {
      final results = <TrainResult>[];

      for (final train in _allTrains) {
        final result = _matchTrain(train, fromName, toName);
        if (result != null) results.add(result);
      }

      if (results.isEmpty) {
        error =
            'No trains found between ${selectedSource!.stationName} '
            'and ${selectedDest!.stationName}.';
      } else {
        // Sort by number of stops between source and destination (shortest first)
        results.sort((a, b) => a.stopsBetween.compareTo(b.stopsBetween));
        trains = results;
      }
    } catch (e) {
      error = 'Error: $e';
      debugPrint('❌ $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Match a single train against source/destination names ─────────

  TrainResult? _matchTrain(dynamic train, String fromName, String toName) {
    final stops = _getStops(train);
    if (stops.isEmpty) return null;

    final fromQ = fromName.trim().toLowerCase();
    final toQ = toName.trim().toLowerCase();

    int fromIdx = -1, toIdx = -1;
    for (int i = 0; i < stops.length; i++) {
      final stopName = stops[i].toString().trim().toLowerCase();
      if (fromIdx == -1 && stopName == fromQ) fromIdx = i;
      if (stopName == toQ) toIdx = i;
    }

    if (fromIdx == -1 || toIdx == -1 || fromIdx >= toIdx) return null;

    return TrainResult(
      trainNumber: (train['train_number'] ?? train['trainNumber'] ?? '')
          .toString(),
      trainName: (train['train_name'] ?? train['trainName'] ?? '').toString(),
      fromStation: stops[fromIdx].toString(),
      toStation: stops[toIdx].toString(),
      fromIndex: fromIdx,
      toIndex: toIdx,
      stopsBetween: toIdx - fromIdx - 1,
      runningDays: _parseDays(train),
      allStops: stops.map((e) => e.toString()).toList(),
    );
  }

  List<dynamic> _getStops(dynamic train) {
    if (train['stops'] is List) return train['stops'] as List;
    if (train['schedule'] is List) return train['schedule'] as List;
    if (train['stations'] is List) return train['stations'] as List;
    if (train['stationList'] is List) return train['stationList'] as List;
    return [];
  }

  // ── running_days parsing ────────────────────────────────────────────
  // Handles: { "monday": true, "tuesday": false, ... }

  List<String> _parseDays(dynamic train) {
    final days = <String>[];
    final rd = train['running_days'] ?? train['runningDays'];

    if (rd is Map) {
      const order = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      const labels = {
        'monday': 'Mon',
        'tuesday': 'Tue',
        'wednesday': 'Wed',
        'thursday': 'Thu',
        'friday': 'Fri',
        'saturday': 'Sat',
        'sunday': 'Sun',
      };
      for (final key in order) {
        final val = rd[key];
        if (val == true || val == 'true' || val == 1 || val == '1') {
          days.add(labels[key]!);
        }
      }
    } else if (rd is List) {
      days.addAll(rd.map((e) => e.toString()));
    }

    return days;
  }
}
