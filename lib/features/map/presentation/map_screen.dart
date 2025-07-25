import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/auth/auth_controller.dart'; 

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    final userLocationsAsync = ref.watch(userLocationsProvider);
    final currentUserProfileAsync = ref.watch(
      userProfileProvider(user.uid),
    ); 

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: currentUserProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (currentUser) {
          final userLocation = currentUser!.location;
          if (userLocation == null ||
              userLocation.latitude == 0 ||
              userLocation.longitude == 0) {
            return const Center(child: Text('Your location is not set.'));
          }

          return userLocationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (users) {
              final markers =
                  users
                      .where(
                        (user) =>
                            user.uid.isNotEmpty &&
                            user.location != null &&
                            user.location!.latitude != 0 &&
                            user.location!.longitude != 0,
                      )
                      .map((user) {
                        return Marker(
                          markerId: MarkerId(user.uid),
                          position: LatLng(
                            user.location!.latitude,
                            user.location!.longitude,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => MiniProfileCard(user: user),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                            );
                          },
                        );
                      })
                      .toSet();

              return GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: LatLng(userLocation.latitude, userLocation.longitude),
                  zoom: 15,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              );
            },
          );
        },
      ),
    );
  }
}
