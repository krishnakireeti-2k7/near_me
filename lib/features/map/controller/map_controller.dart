
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:geolocator/geolocator.dart';

final mapControllerProvider = Provider((ref) {
  final profileRepository = ref.read(profileRepositoryProvider);
  return MapController(profileRepository: profileRepository);
});

final userLocationsProvider = StreamProvider<List<UserProfileModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => UserProfileModel.fromMap(doc.data()))
        .where((user) => user.location != null)
        .toList();
  });
});

class MapController {
  final ProfileRepository _profileRepository;
  Timer? _locationUpdateTimer;

  MapController({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  // New method to start the periodic location updates
  void startLocationUpdates(String userId) {
    // Cancel any existing timer to avoid duplicates
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    ) async {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        final GeoPoint newLocation = GeoPoint(
          position.latitude,
          position.longitude,
        );
        await _profileRepository.updateUserLocation(userId, newLocation);
      } catch (e) {
        // Handle location service errors, e.g., permission denied
        debugPrint('Failed to get or update location: $e');
      }
    });
  }

  // New method to stop the timer when no longer needed
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }
}
