import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests permission and returns the current GPS position.
  /// Throws a [LocationException] with a human-readable message on failure.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are disabled. Please enable GPS and try again.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission denied. Please allow location access to find nearby restaurants.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Please enable it from app settings.',
        isPermanentlyDenied: true,
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns the distance in metres between two coordinates.
  double distanceBetween(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}

class LocationException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  const LocationException(
      this.message, {
        this.isPermanentlyDenied = false,
      });

  @override
  String toString() => message;
}