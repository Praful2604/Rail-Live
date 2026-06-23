class StationModel {
  final String stationCode;
  final String stationName;
  final double latitude;
  final double longitude;

  const StationModel({
    required this.stationCode,
    required this.stationName,
    required this.latitude,
    required this.longitude,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      stationCode: json['station_code'] as String,
      stationName: json['station_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'station_code': stationCode,
    'station_name': stationName,
    'latitude': latitude,
    'longitude': longitude,
  };
}