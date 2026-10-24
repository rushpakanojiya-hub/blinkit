import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'nominatim_service.dart';

class CurrentLocationResult {
  final double latitude;
  final double longitude;
  final String displayAddress;

  CurrentLocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayAddress,
  });
}

class LocationService {
  static Timer? _timer;

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // This triggers the native "Allow location access" prompt.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    // Permission is granted at the app level; separately check if the
    // device's GPS/location service itself is turned on.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    return true;
  }

  /// Fetches the device's current GPS position and resolves it to a
  /// human-readable address. Triggers the native location permission
  /// prompt if permission hasn't been granted yet.
  static Future<CurrentLocationResult> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it from app settings.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please turn on location services to detect your address.');
    }

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw Exception('Could not detect your location. Please try again or pick it manually.');
      }
      pos = last;
    }

    final reverse = await NominatimService.reverseGeocode(pos.latitude, pos.longitude);
    final address = reverse.cityLine.isNotEmpty
        ? reverse.cityLine
        : (reverse.streetLine.isNotEmpty ? reverse.streetLine : 'Current Location');

    return CurrentLocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      displayAddress: address,
    );
  }

  static void startTracking() {
    _timer?.cancel();
    _sendCurrentLocation();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      _sendCurrentLocation();
    });
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _sendCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('LocationService: permission or location service off');
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('LocationService: getCurrentPosition failed: $e');
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        debugPrint('LocationService: no position available');
        return;
      }
      await ApiService.updateLocation(pos.latitude, pos.longitude);
      debugPrint('LocationService: sent ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      debugPrint('LocationService: update failed: $e');
    }
  }
}
