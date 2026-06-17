
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class PnrProvider extends ChangeNotifier {
  bool isLoading = false;

  /// Holds the `data` object from the API response (NOT the full envelope).
  Map<String, dynamic>? data;
  String? error;

  // ── Search history: list of maps with summary + full 'result' snapshot ────
  List<Map<String, dynamic>> _searchHistory = [];
  List<Map<String, dynamic>> get searchHistory => _searchHistory;

  static const String _historyKey = 'pnr_search_history';
  static const int _maxHistory = 10;

  // RapidAPI host for this specific API (different from the old PNR API).
  static const String _rapidApiHost =
      'irctc-indian-railway-pnr-status.p.rapidapi.com';

  PnrProvider() {
    _loadHistory();
  }

  // ── Load history from SharedPreferences ───────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _searchHistory =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("History load error: $e");
    }
  }

  // ── Save history to SharedPreferences ─────────────────────────────────────

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_searchHistory));
    } catch (e) {
      debugPrint("History save error: $e");
    }
  }

  // ── Add a new entry (deduplicated, newest first) ───────────────────────────

  Future<void> _addToHistory(String pnr, Map<String, dynamic> pnrData) async {
    // Remove existing entry for same PNR if any
    _searchHistory.removeWhere((e) => e['pnr'] == pnr);

    final journeyDetails =
    Map<String, dynamic>.from(pnrData['journeyDetails'] as Map? ?? {});
    final passengerDetails =
    (pnrData['passengerDetails'] as List? ?? []).cast<dynamic>();
    final otherDetails =
    Map<String, dynamic>.from(pnrData['otherDetails'] as Map? ?? {});

    final firstPassenger = passengerDetails.isNotEmpty
        ? Map<String, dynamic>.from(passengerDetails.first as Map)
        : <String, dynamic>{};

    // Insert at top
    _searchHistory.insert(0, {
      'pnr': pnr,
      'searchedAt': DateTime.now().toIso8601String(),
      'trainNumber': journeyDetails['trainNumber'] ?? '',
      'trainName': journeyDetails['trainName'] ?? '',
      'from': journeyDetails['from'] ?? '',
      'to': journeyDetails['to'] ?? '',
      'journeyDate': journeyDetails['boardingDate'] ?? '',
      'currentStatus': firstPassenger['currentStatus'] ?? '',
      'chartingStatus': otherDetails['chartingStatus'] ?? '',
      'result': pnrData, // full data snapshot
    });

    // Keep only the latest _maxHistory entries
    if (_searchHistory.length > _maxHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxHistory);
    }

    await _saveHistory();
    notifyListeners();
  }

  // ── Load a past search directly into [data] ────────────────────────────────

  void loadFromHistory(Map<String, dynamic> historyEntry) {
    data = Map<String, dynamic>.from(historyEntry['result'] as Map);
    error = null;
    notifyListeners();
  }

  // ── Delete one history entry ───────────────────────────────────────────────

  Future<void> removeHistoryEntry(String pnr) async {
    _searchHistory.removeWhere((e) => e['pnr'] == pnr);
    await _saveHistory();
    notifyListeners();
  }

  // ── Clear all history ──────────────────────────────────────────────────────

  Future<void> clearHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    notifyListeners();
  }

  // ── Fetch PNR from API ─────────────────────────────────────────────────────

  Future<void> fetchPnr(String pnr) async {
    try {
      isLoading = true;
      error = null;
      data = null;
      notifyListeners();

      final url = Uri.parse(
        "https://$_rapidApiHost/getPNRStatus/$pnr",
      );

      final response = await http.get(
        url,
        headers: {
          "x-rapidapi-key": Env.rapidPnrApiKey,
          "x-rapidapi-host": _rapidApiHost,
        },
      );

      dynamic result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        result = null;
      }

      debugPrint("PNR API Response: $result");

      if (response.statusCode == 200) {
        if (result == null || (result is Map && result.isEmpty)) {
          error = "Invalid PNR Number";
        } else if (result is Map && result["success"] == false) {
          error = (result["message"] ?? result["error"] ?? "Invalid PNR Number")
              .toString();
        } else if (result is Map && result["data"] == null) {
          error = "Invalid PNR Number";
        } else {
          final pnrData = Map<String, dynamic>.from(result["data"] as Map);
          data = pnrData;
          // ✅ Save successful search to history
          await _addToHistory(pnr, pnrData);
        }
      } else if (response.statusCode == 400) {
        error = (result is Map
            ? (result["message"] ?? result["error"])
            : null)
            ?.toString() ??
            "Invalid PNR Number";
      } else if (response.statusCode == 404) {
        error = "Invalid PNR Number";
      } else {
        error = (result is Map
            ? (result["message"] ?? result["error"])
            : null)
            ?.toString() ??
            "Unable to fetch PNR status";
      }
    } catch (e) {
      debugPrint("PNR Error: $e");
      error = "Something went wrong. Please try again.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Clear current result ───────────────────────────────────────────────────

  void clearData() {
    data = null;
    error = null;
    notifyListeners();
  }
}


