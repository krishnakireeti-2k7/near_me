import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  bool _movedToUser = false;

  static const LatLng _defaultLatLng = LatLng(17.4443, 78.3498); // IIIT-H
  static const double _defaultZoom = 15;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Set<Marker> _buildMarkers(List<UserProfileModel> users) {
    return users.where((user) => user.location != null).map((user) {
      return Marker(
        markerId: MarkerId(user.uid),
        position: LatLng(user.location!.latitude, user.location!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => MiniProfileCard(user: user),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          );
        },
      );
    }).toSet();
  }

  void _moveToUserLocation(List<UserProfileModel> users) {
    if (_movedToUser || _mapController == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUser = users.firstWhere(
      (user) => user.uid == currentUid && user.location != null,
      orElse: () => UserProfileModel.empty(),
    );

    if (currentUser.location != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            currentUser.location!.latitude,
            currentUser.location!.longitude,
          ),
          _defaultZoom,
        ),
      );
      _movedToUser = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLocationsAsync = ref.watch(userLocationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: userLocationsAsync.when(
        data: (users) {
          final markers = _buildMarkers(users);
          _moveToUserLocation(users); // 🔥 camera moves to user location
          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _defaultLatLng,
              zoom: _defaultZoom,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading map: $err')),
      ),
    );
  }
}
