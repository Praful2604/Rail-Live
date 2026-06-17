import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class TrainProvider extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? trainData;
  String? error;

  Map<String, dynamic>? liveStatus;
  bool liveStatusLoading = false;
  String? liveStatusError;

  List<dynamic> allTrains = [];
  List<dynamic> suggestions = [];

  // ── Recent searches ──────────────────────────────────────────────
  static const _prefKey = 'recent_searches';
  List<Map<String, String>> recentSearches = [];

  Future<void> loadTrains() async {
    final String response = await rootBundle.loadString(
      'assets/data/trains.json',
    );
    allTrains = jsonDecode(response);
    await _loadRecentSearches();
    notifyListeners();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefKey) ?? [];
    recentSearches = raw
        .map((e) => Map<String, String>.from(
              jsonDecode(e) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> saveRecentSearch(
      String trainNumber, String trainName) async {
    final entry = {'train_number': trainNumber, 'train_name': trainName};

    // Remove duplicate
    recentSearches.removeWhere((e) => e['train_number'] == trainNumber);

    // Add to front
    recentSearches.insert(0, entry);

    // Keep max 5
    if (recentSearches.length > 4) {
      recentSearches = recentSearches.sublist(0, 4);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefKey,
      recentSearches.map((e) => jsonEncode(e)).toList(),
    );

    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
  }
  // ─────────────────────────────────────────────────────────────────

  Future<void> fetchTrain(String trainNo, {String? trainName}) async {
    try {
      isLoading = true;
      error = null;
      trainData = null;
      notifyListeners();

      final url = Uri.https(
        Env.rapidApiHost,
        '/api/trains-search/v1/train/$trainNo',
        {
          'isH5': 'true',
          'client': 'web',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-host': Env.rapidApiHost,
          'x-rapidapi-key': Env.rapidApiKey,
          'x-rapid-api': Env.rapidApi,
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['body'] == null ||
            result['body'] is! List ||
            result['body'].isEmpty ||
            result['body'][0]['trains'] == null ||
            result['body'][0]['trains'].isEmpty) {
          error = "Train not found";
          trainData = null;
        } else {
          trainData = result['body'][0]['trains'][0];

          await saveRecentSearch(
            trainData!['trainNumber']?.toString() ?? trainNo,
            trainData!['trainName']?.toString() ?? (trainName ?? ''),
          );

          error = null;
        }
      } else if (response.statusCode == 403) {
        error = "API access denied. Check your API key.";
        trainData = null;
      } else if (response.statusCode == 429) {
        error = "Too many requests. Please wait before retrying.";
        trainData = null;
      } else if (response.statusCode == 404) {
        error = "Train not found";
        trainData = null;
      } else {
        error = "API Error: ${response.statusCode}";
        trainData = null;
      }
    } catch (e) {
      error = "Error: $e";
      trainData = null;
    }

    isLoading = false;
    notifyListeners();
  }


  Future<void> fetchLiveStatus(String trainNumber) async {
    try {
      liveStatusLoading = true;
      liveStatusError = null;
      notifyListeners();

      final today = DateFormat('yyyyMMdd').format(DateTime.now());

      final uri = Uri.https(
        'indian-railway-irctc.p.rapidapi.com',
        '/api/trains/v1/train/status',
        {
          'departure_date': today,
          'isH5': 'true',
          'client': 'web',
          'train_number': trainNumber,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'x-rapidapi-host': Env.rapidApiHost,
          'x-rapidapi-key': Env.rapidApiKey,
        },
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonData['status']?['result'] == 'success') {
        liveStatus = jsonData;
      } else {
        liveStatusError =
            jsonData['status']?['message']?['message'] ??
                'Unable to fetch live status';
      }
    } catch (e) {
      liveStatusError = e.toString();
    }

    liveStatusLoading = false;
    notifyListeners();
  }

 /* Future<void> fetchTrain(String trainNo, {String? trainName}) async {
    try {
      isLoading = true;
      error = null;
      trainData = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('https://rappid.in/apis/train.php?train_no=$trainNo'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result == null ||
            (result is Map && result.isEmpty) ||
            result['data'] == null) {
          error = "Invalid Train Number";
          trainData = null;
        } else {
          trainData = result;
          error = null;
        }
      } else if (response.statusCode == 404) {
        error = "Invalid Train Number";
        trainData = null;
      } else {
        error = "Unable to fetch train details";
        trainData = null;
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
*/
  void searchTrain(String query) {
    if (query.trim().length < 2) {
      suggestions.clear();
      notifyListeners();
      return;
    }

    final lowerQuery = query.trim().toLowerCase();

    suggestions = allTrains.where((train) {
      final name = train['train_name'].toString().toLowerCase();
      final number = train['train_number'].toString();
      return name.contains(lowerQuery) || number.contains(lowerQuery);
    }).take(20).toList();

    notifyListeners();
  }

  void clearSuggestions() {
    suggestions.clear();
    notifyListeners();
  }
}
