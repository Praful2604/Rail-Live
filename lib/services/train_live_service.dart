import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/env.dart';

class TrainLiveService {
  Future<Map<String, dynamic>> fetchLiveStatus(
      String trainNumber) async {
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

    return jsonDecode(response.body);
  }
}