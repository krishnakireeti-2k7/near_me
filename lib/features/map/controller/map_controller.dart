// file: lib/features/map/controller/map_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:geolocator/geolocator.dart';

/// This is the StateNotifier to manage the GoogleMapController.
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

// NEW: State class to hold the location sharing status
class MapLocationState {
  final bool isLocationSharingEnabled;

  MapLocationState({this.isLocationSharingEnabled = true});

  MapLocationState copyWith({bool? isLocationSharingEnabled}) {
    return MapLocationState(
      isLocationSharingEnabled:
          isLocationSharingEnabled ?? this.isLocationSharingEnabled,
    );
  }
}

// NEW: The MapLocationNotifier will handle the location logic.
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

  // NEW METHOD: Toggle location sharing
  void toggleLocationSharing(bool isEnabled) {
    if (_currentUserId == null) return;
    state = state.copyWith(isLocationSharingEnabled: isEnabled);
    if (isEnabled) {
      _startLocationUpdates(_currentUserId!);
    } else {
      _stopLocationUpdates();
    }
  }

  // UPDATED METHOD: Manual location update with permission check
  Future<bool> updateLocationNow() async {
    if (_currentUserId == null) return false;

    // Check for permission first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false; // Permission denied, cannot update location
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      final newLocation = GeoPoint(position.latitude, position.longitude);
      await _profileRepository.updateUserLocation(_currentUserId!, newLocation);
      return true; // Location updated successfully
    } catch (e) {
      debugPrint('Failed to get or update location: $e');
      return false; // An error occurred
    }
  }

  // CORRECTED: This method was missing before. It stops the timer and resets the state for a clean logout.
  void signOutCleanup() {
    _stopLocationUpdates();
    _currentUserId = null;
    state = state.copyWith(isLocationSharingEnabled: false);
  }

  // The existing logic is now encapsulated here.
  void _startLocationUpdates(String userId) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
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

// NEW: This provider exposes the MapLocationNotifier
final mapLocationProvider =
    StateNotifierProvider<MapLocationNotifier, MapLocationState>((ref) {
      final profileRepository = ref.read(profileRepositoryProvider);
      return MapLocationNotifier(profileRepository: profileRepository);
    });

final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  final authState = ref.watch(authStateProvider).asData?.value;
  if (authState == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => UserProfileModel.fromMap(doc.data()))
        .where((user) => user.location != null)
        .toList();
  });
});
