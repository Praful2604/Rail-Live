import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rail_live/utils/station_data.dart';
import '../models/restaurant_model.dart';
import '../models/station_model.dart';
import '../services/location_service.dart';
import '../utils/restaurant_data.dart';
import '';

enum NearbyRestaurantStatus {
  initial,
  locating,
  loaded,
  noStationNearby,
  error,
}

class RestaurantProvider extends ChangeNotifier {
  final LocationService _locationService;

  RestaurantProvider({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  // ── State ──────────────────────────────────────────────────────────────────

  NearbyRestaurantStatus _status = NearbyRestaurantStatus.initial;
  NearbyRestaurantStatus get status => _status;

  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> get restaurants => _filteredRestaurants;

  StationModel? _nearestStation;
  StationModel? get nearestStation => _nearestStation;

  double? _stationDistanceKm;
  double? get stationDistanceKm => _stationDistanceKm;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _isPermanentlyDenied = false;
  bool get isPermanentlyDenied => _isPermanentlyDenied;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Position? _userPosition;
  Position? get userPosition => _userPosition;

  /// Max radius (km) within which a station is considered "nearby".
  static const double kNearbyStationRadiusKm = 5.0;

  // ── Derived ────────────────────────────────────────────────────────────────

  List<RestaurantModel> get _filteredRestaurants {
    if (_searchQuery.isEmpty) return _restaurants;
    final q = _searchQuery.toLowerCase();
    return _restaurants.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.menu.any((m) => m.item.toLowerCase().contains(q));
    }).toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadNearbyRestaurants() async {
    _status = NearbyRestaurantStatus.locating;
    _errorMessage = '';
    _isPermanentlyDenied = false;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      _userPosition = position;

      final station = _findNearestStation(position);
      if (station == null) {
        _status = NearbyRestaurantStatus.noStationNearby;
        _nearestStation = null;
        _restaurants = [];
        notifyListeners();
        return;
      }

      _nearestStation = station.station;
      _stationDistanceKm = station.distanceKm;

      _restaurants = _loadRestaurantsForStation(
        station.station.stationCode,
        position,
      );

      _status = NearbyRestaurantStatus.loaded;
    } on LocationException catch (e) {
      _status = NearbyRestaurantStatus.error;
      _errorMessage = e.message;
      _isPermanentlyDenied = e.isPermanentlyDenied;
    } catch (e) {
      _status = NearbyRestaurantStatus.error;
      _errorMessage = 'Unexpected error: ${e.toString()}';
    }

    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  ({StationModel station, double distanceKm})? _findNearestStation(
      Position userPos,
      ) {
    StationModel? nearest;
    double minDistKm = double.infinity;

    for (final station in allStations) {
      final distM = _locationService.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        station.latitude,
        station.longitude,
      );
      final distKm = distM / 1000.0;
      if (distKm < minDistKm) {
        minDistKm = distKm;
        nearest = station;
      }
    }

    if (nearest == null || minDistKm > kNearbyStationRadiusKm) return null;
    return (station: nearest, distanceKm: minDistKm);
  }

  List<RestaurantModel> _loadRestaurantsForStation(
      String stationCode,
      Position userPos,
      ) {
    final data = kRestaurantDataByStation[stationCode] as Map<String, dynamic>?;
    if (data == null) return [];

    final stationName = data['station_name'] as String;
    final rawList = data['restaurants'] as List<dynamic>;

    final List<RestaurantModel> list = rawList.map((e) {
      final r = RestaurantModel.fromJson(
        e as Map<String, dynamic>,
        stationName,
      );

      // Distance from user = distance to station + distance from station.
      // This approximation works well for restaurants within a few km of station.
      final stationDistM = _locationService.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        _nearestStation!.latitude,
        _nearestStation!.longitude,
      );
      r.distanceFromUserKm =
          (stationDistM / 1000.0) + r.distanceFromStationKm;

      return r;
    }).toList();

    // Sort ascending by distance from station
    list.sort((a, b) =>
        a.distanceFromStationKm.compareTo(b.distanceFromStationKm));

    return list;
  }
}