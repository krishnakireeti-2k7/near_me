import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:geolocator/geolocator.dart'; // NEW: Import geolocator

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // NEW: Add initState and a permission check method
  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndStartUpdates();
  }

  // NEW: Add a dispose method to clean up the timer
  @override
  void dispose() {
    ref.read(mapControllerProvider).stopLocationUpdates();
    super.dispose();
  }

  // NEW: Method to handle permission requests and starting the timer
  Future<void> _checkLocationPermissionAndStartUpdates() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      // Optional: show a dialog to enable services
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permissions are permanently denied.");
      return;
    }

    // If we have permission, start the periodic updates
    ref.read(mapControllerProvider).startLocationUpdates(currentUser.uid);
  }

  Future<void> _updateMarkers(List<UserProfileModel> users) async {
    final Set<Marker> newMarkers = {};
    for (final user in users) {
      if (user.location != null &&
          user.location!.latitude != 0 &&
          user.location!.longitude != 0) {
        String? imageUrlToShow = user.profileImageUrl;
        if (imageUrlToShow.isEmpty) {
          final currentUserFromAuth = ref.read(authStateProvider).value;
          if (currentUserFromAuth != null &&
              currentUserFromAuth.uid == user.uid) {
            imageUrlToShow = currentUserFromAuth.photoURL;
          }
        }

        final markerIcon = await _getCustomMarker(imageUrlToShow);
        newMarkers.add(
          Marker(
            markerId: MarkerId(user.uid),
            position: LatLng(user.location!.latitude, user.location!.longitude),
            icon: markerIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => MiniProfileCard(user: user),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              );
            },
          ),
        );
      }
    }
    setState(() {
      _markers = newMarkers;
    });
  }

  Future<BitmapDescriptor> _getCustomMarker(String? imageUrl) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double markerSize = 100.0;
    const double borderSize = 4.0;
    const double profilePicSize = markerSize - (borderSize * 2);

    // Paint for the outer border
    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderSize;

    // Paint for the shadow
    final Paint shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8.0);

    // Draw the shadow
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2),
      shadowPaint,
    );

    // Draw the outer border circle
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2) - (borderSize / 2),
      borderPaint,
    );

    // Draw the profile image in a circular shape
    final Rect imageRect = Rect.fromCircle(
      center: const Offset(markerSize / 2, markerSize / 2),
      radius: profilePicSize / 2,
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imageProvider = NetworkImage(imageUrl);
      final Completer<ui.Image> completer = Completer();
      imageProvider
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((ImageInfo info, bool synchronousCall) {
              if (!completer.isCompleted) {
                completer.complete(info.image);
              }
            }),
          );
      final ui.Image image = await completer.future;

      canvas.saveLayer(imageRect, Paint());
      canvas.clipRRect(
        RRect.fromRectAndRadius(imageRect, Radius.circular(profilePicSize / 2)),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint(),
      );
      canvas.restore();
    } else {
      // Draw a sleek placeholder icon if no image
      final placeholderPaint = Paint()..color = Colors.grey[300]!;
      canvas.drawCircle(
        const Offset(markerSize / 2, markerSize / 2),
        profilePicSize / 2,
        placeholderPaint,
      );

      final textPainter = TextPainter(
        text: const TextSpan(
          text: '👤', // Using a professional-looking person emoji or icon
          style: TextStyle(fontSize: 40),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (markerSize - textPainter.width) / 2,
          (markerSize - textPainter.height) / 2,
        ),
      );
    }

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
      markerSize.toInt(),
      markerSize.toInt(),
    );
    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    final userLocationsAsync = ref.watch(userLocationsProvider);
    final currentUserProfileAsync = ref.watch(userProfileProvider(user.uid));

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
              _updateMarkers(users);
              return GoogleMap(
                onMapCreated: (controller) async {
                  _mapController = controller;
                  try {
                    final jsonString = await rootBundle.loadString(
                      'assets/map_style.json',
                    );
                    await _mapController?.setMapStyle(jsonString);
                  } catch (e) {
                    debugPrint('Failed to load map style: $e');
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(userLocation.latitude, userLocation.longitude),
                  zoom:
                      19, 
                ),
                markers: _markers,
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
