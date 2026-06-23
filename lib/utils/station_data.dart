import 'package:rail_live/models/station_model.dart';

/// Predefined list of railway stations for nearest-station detection.
/// Add more stations here as the app grows.
const List<Map<String, dynamic>> kStationJsonList = [
  {
    'station_code': 'KHED',
    'station_name': 'Khed Railway Station',
    'latitude': 17.7180,
    'longitude': 73.3960,
  },
  {
    'station_code': 'RN',
    'station_name': 'Ratnagiri Railway Station',
    'latitude': 16.9902,
    'longitude': 73.3120,
  },
  {
    'station_code': 'CHI',
    'station_name': 'Chiplun Railway Station',
    'latitude': 17.5315,
    'longitude': 73.5139,
  },
  {
    'station_code': 'SNDD',
    'station_name': 'Sangameshwar Road Railway Station',
    'latitude': 17.2200,
    'longitude': 73.5700,
  },
  {
    'station_code': 'PUNE',
    'station_name': 'Pune Junction Railway Station',
    'latitude': 18.5284,
    'longitude': 73.8742,
  },
  {
    'station_code': 'LONAVALA',
    'station_name': 'Lonavala Railway Station',
    'latitude': 18.7481,
    'longitude': 73.4072,
  },
];

List<StationModel> get allStations =>
    kStationJsonList.map(StationModel.fromJson).toList();