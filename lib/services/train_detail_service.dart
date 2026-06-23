import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/env.dart';

class TrainDetailService {
  static const _liveHost = 'indian-railway-irctc.p.rapidapi.com';

  Future<Map<String, dynamic>> fetchLiveStatus(String trainNumber) async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());

    final uri = Uri.https(
      _liveHost,
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
        'x-rapidapi-host': Env.rapidApiHost.isNotEmpty
            ? Env.rapidApiHost
            : _liveHost,
        'x-rapidapi-key': Env.rapidApiKey,
      },
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCoachCompositionRaw(
      String trainNumber) async {
    final uri = Uri.https(
      _liveHost,
      '/api/trains/v1/train/coach-composition',
      {'train_number': trainNumber},
    );

    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-host': Env.rapidApiHost.isNotEmpty
            ? Env.rapidApiHost
            : _liveHost,
        'x-rapidapi-key': Env.rapidApiKey,
      },
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
