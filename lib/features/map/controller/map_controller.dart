// file: lib/features/map/controller/map_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapControllerNotifier extends StateNotifier<GoogleMapController?> {
  GoogleMapControllerNotifier() : super(null);

  void setController(GoogleMapController controller) {
    state = controller;
  }

  void moveCamera(LatLng location) {
    state?.animateCamera(CameraUpdate.newLatLng(location));
  }
}

final googleMapControllerProvider =
    StateNotifierProvider<GoogleMapControllerNotifier, GoogleMapController?>((
      ref,
    ) {
      return GoogleMapControllerNotifier();
    });

class MapLocationState {
  final bool isLocationSharingEnabled;
  final bool isGhostModeEnabled;

  MapLocationState({
    this.isLocationSharingEnabled = true,
    this.isGhostModeEnabled = false,
  });

  MapLocationState copyWith({
    bool? isLocationSharingEnabled,
    bool? isGhostModeEnabled,
  }) {
    return MapLocationState(
      isLocationSharingEnabled:
          isLocationSharingEnabled ?? this.isLocationSharingEnabled,
      isGhostModeEnabled: isGhostModeEnabled ?? this.isGhostModeEnabled,
    );
  }
}

class MapLocationNotifier extends StateNotifier<MapLocationState> {
  final ProfileRepository _profileRepository;
  Timer? _locationUpdateTimer;
  String? _currentUserId;

  MapLocationNotifier({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(MapLocationState());

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  void toggleLocationSharing(bool isEnabled) {
    if (_currentUserId == null) return;
    state = state.copyWith(isLocationSharingEnabled: isEnabled);
    if (isEnabled) {
      _startLocationUpdates(_currentUserId!);
    } else {
      _stopLocationUpdates();
    }
  }

  void toggleGhostMode(bool isEnabled) {
    state = state.copyWith(isGhostModeEnabled: isEnabled);
    if (_currentUserId != null) {
      _profileRepository.updateGhostModeStatus(_currentUserId!, isEnabled);
    }
  }

  Future<bool> updateLocationNow() async {
    if (_currentUserId == null) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      final newLocation = GeoPoint(position.latitude, position.longitude);
      await _profileRepository.updateUserLocation(_currentUserId!, newLocation);
      return true;
    } catch (e) {
      debugPrint('Failed to get or update location: $e');
      return false;
    }
  }

  void signOutCleanup() {
    _stopLocationUpdates();
    _currentUserId = null;
    state = state.copyWith(isLocationSharingEnabled: false);
  }

  void _startLocationUpdates(String userId) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _getCurrentLocationAndSendUpdate(userId);
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  Future<void> _getCurrentLocationAndSendUpdate(String userId) async {
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

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }
}

final mapLocationProvider =
    StateNotifierProvider<MapLocationNotifier, MapLocationState>((ref) {
      final profileRepository = ref.read(profileRepositoryProvider);
      return MapLocationNotifier(profileRepository: profileRepository);
    });
