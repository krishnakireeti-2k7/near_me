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

  // Method to set the controller once the map is created.
  void setController(GoogleMapController controller) {
    state = controller;
  }

  // Method to move the map camera to a specific location.
  void moveCamera(LatLng location) {
    state?.animateCamera(CameraUpdate.newLatLng(location));
  }
}

/// This provider is a StateNotifierProvider that exposes the GoogleMapControllerNotifier.
/// It allows widgets to access the map controller and call methods on it.
final googleMapControllerProvider =
    StateNotifierProvider<GoogleMapControllerNotifier, GoogleMapController?>((
      ref,
    ) {
      return GoogleMapControllerNotifier();
    });

/// This is the existing MapController, which handles location updates.
/// We'll keep it as a regular Provider.
final mapControllerProvider = Provider((ref) {
  final profileRepository = ref.read(profileRepositoryProvider);
  return MapController(profileRepository: profileRepository);
});

/// Stream of user locations from Firestore, but only after user is authenticated
final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  final authState = ref.watch(authStateProvider).asData?.value;

  if (authState == null) {
    return const Stream.empty(); // Wait until user is logged in
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

/// Controller to manage location updates
class MapController {
  final ProfileRepository _profileRepository;
  Timer? _locationUpdateTimer;

  MapController({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  /// Start sending user location to Firestore every 5 minutes
  void startLocationUpdates(String userId) {
    _locationUpdateTimer?.cancel(); // Cancel any previous timer
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    ) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        final newLocation = GeoPoint(position.latitude, position.longitude);
        await _profileRepository.updateUserLocation(userId, newLocation);
      } catch (e) {
        debugPrint('Failed to get or update location: $e');
      }
    });
  }

  /// Stop location updates (call this on logout)
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Call this on logout to clean up state
  void signOutCleanup() {
    stopLocationUpdates();
  }
}
