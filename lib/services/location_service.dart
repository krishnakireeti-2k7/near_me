// file: lib/services/location_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

// Provider for the LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final profileRepository = ref.read(profileRepositoryProvider);
  return LocationService(profileRepository: profileRepository);
});

class LocationService {
  final ProfileRepository _profileRepository;
  Timer? _timer;
  bool _isLocationSharingEnabled = true;

  LocationService({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  // New: Method to get the current location once (from your original file)
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  // Toggles location sharing on and off.
  void toggleLocationSharing(bool isEnabled, String userId) {
    _isLocationSharingEnabled = isEnabled;
    if (_isLocationSharingEnabled) {
      _startTimer(userId);
    } else {
      _stopTimer();
    }
  }

  // Manually sends a single location update immediately.
  Future<void> updateLocationNow(String userId) async {
    if (_isLocationSharingEnabled) {
      await _sendLocationUpdate(userId);
    }
  }

  // Starts the periodic timer for location updates.
  void _startTimer(String userId) {
    _stopTimer();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _sendLocationUpdate(userId);
    });
  }

  // Stops the periodic timer.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Gets the current location and sends it to the repository.
  Future<void> _sendLocationUpdate(String userId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      final newLocation = GeoPoint(position.latitude, position.longitude);
      await _profileRepository.updateUserLocation(userId, newLocation);
    } catch (e) {
      debugPrint('Failed to get or update location: $e');
    }
  }
}
