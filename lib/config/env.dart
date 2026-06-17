import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get rapidApiKey => dotenv.env['RAPID_API_KEY'] ?? '';
  static String get rapidApiHost => dotenv.env['RAPID_API_HOST'] ?? '';
  static String get rapidApi => dotenv.env['RAPID_API'] ?? '';
  static String get rapidPnrApiKey => dotenv.env['RAPID_PNP_API']??'';
  static String trainSearchUrl(String trainNo) =>
      'https://$rapidApiHost/api/trains-search/v1/train/$trainNo';
}