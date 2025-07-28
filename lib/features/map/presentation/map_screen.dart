// file: lib/features/map/presentation/map_screen.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
// IMPORTANT: Add 'as profile_repo' to clarify which userLocationsProvider to use
import 'package:near_me/features/profile/repository/profile_repository_provider.dart'
    as profile_repo; // Aliased for clarity
import 'package:near_me/features/profile/repository/profile_repository_provider.dart'; // Keep this for userProfileProvider
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:near_me/widgets/main_drawer.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp/GeoPoint if not already

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // State variables to track permission and service status
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  String? _locationStatusMessage;

  // A default campus location (replace with your actual campus center)
  static const LatLng _defaultCampusLocation = LatLng(
    17.4375,
    78.4482,
  ); // Example: Center of Hyderabad

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndStartUpdates();
  }

  @override
  void dispose() {
    // Only stop updates if location permission was granted and updates were started
    if (_isLocationPermissionGranted && _isLocationServiceEnabled) {
      ref.read(mapControllerProvider).stopLocationUpdates();
    }
    _mapController?.dispose(); // Dispose map controller
    super.dispose();
  }

  Future<void> _checkLocationPermissionAndStartUpdates() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      _updateLocationStatus(message: "User not logged in.");
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateLocationStatus(
        isServiceEnabled: false,
        message: "Location services are disabled. Tap here to enable.",
        action: () async {
          await Geolocator.openLocationSettings();
        },
      );
      return;
    }
    _updateLocationStatus(isServiceEnabled: true); // Service is enabled

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateLocationStatus(
          isPermissionGranted: false,
          message:
              "Location permission denied. Map might not show your current location.",
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updateLocationStatus(
        isPermissionGranted: false,
        message:
            "Location permission permanently denied. Enable in app settings.",
        action: () async {
          await Geolocator.openAppSettings();
        },
      );
      return;
    }

    // If we reach here, permissions are granted and service is enabled
    _updateLocationStatus(isPermissionGranted: true, message: null);

    // Only start location updates if we have permission
    ref.read(mapControllerProvider).startLocationUpdates(currentUser.uid);
  }

  void _updateLocationStatus({
    bool? isPermissionGranted,
    bool? isServiceEnabled,
    String? message,
    VoidCallback? action,
  }) {
    if (!mounted) return;
    setState(() {
      if (isPermissionGranted != null) {
        _isLocationPermissionGranted = isPermissionGranted;
      }
      if (isServiceEnabled != null) {
        _isLocationServiceEnabled = isServiceEnabled;
      }
      _locationStatusMessage = message;

      // Show snackbar if there's a new message
      if (message != null) {
        // Changed to check for message existence only
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showFloatingSnackBar(
            context,
            message,
            actionLabel:
                action != null
                    ? 'Settings'
                    : null, // Only show label if action exists
            onActionPressed: action,
            duration: const Duration(seconds: 5), // Keep it on screen longer
          );
        });
      }
    });
  }

  Future<void> _updateMarkers(List<UserProfileModel> users) async {
    final Set<Marker> newMarkers = {};
    // Get the current user's UID to determine 'You' marker status
    final currentUserId = ref.read(authStateProvider).value?.uid;

    for (final user in users) {
      if (user.location != null &&
          user.location!.latitude != 0 &&
          user.location!.longitude != 0) {
        String? imageUrlToShow = user.profileImageUrl;
        // Fallback for current user's photoURL if profileImageUrl is empty
        if (imageUrlToShow == null || imageUrlToShow.isEmpty) {
          if (currentUserId != null && currentUserId == user.uid) {
            imageUrlToShow = ref.read(authStateProvider).value?.photoURL;
          }
        }

        // Determine if the user is active based on lastActive timestamp
        final bool isActive =
            user.lastActive != null &&
            DateTime.now().difference(user.lastActive!.toDate()).inMinutes <=
                5; // Active if last seen within 5 minutes

        final markerIcon = await _getCustomMarker(
          imageUrlToShow,
          isActive,
        ); // Pass isActive
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

  Future<BitmapDescriptor> _getCustomMarker(
    String? imageUrl,
    bool isActive,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double markerSize = 120.0; // Increased size for better visibility
    const double borderSize = 6.0; // Border around profile pic
    const double onlineIndicatorSize = 30.0; // Size of the online dot
    const double profilePicSize = markerSize - (borderSize * 2);

    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill; // Changed to fill for solid border

    final Paint shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(
            0.3,
          ) // Slightly more prominent shadow
          ..maskFilter = const ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            10.0,
          ); // Increased blur for better shadow

    // Draw shadow
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2) - 5,
      shadowPaint,
    );

    // Draw outer border (white circle)
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2),
      borderPaint,
    );

    // Draw the profile image
    final Rect imageRect = Rect.fromCircle(
      center: Offset(markerSize / 2, markerSize / 2),
      radius: profilePicSize / 2,
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
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
          RRect.fromRectAndRadius(
            imageRect,
            Radius.circular(profilePicSize / 2),
          ),
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          imageRect,
          Paint(),
        );
        canvas.restore();
      } catch (e) {
        debugPrint('Error loading image for marker: $e');
        // Fallback to placeholder if image fails to load
        _drawPlaceholder(canvas, markerSize, profilePicSize);
      }
    } else {
      _drawPlaceholder(canvas, markerSize, profilePicSize);
    }

    // Draw online/offline indicator
    if (isActive) {
      final Paint onlinePaint =
          Paint()..color = Colors.greenAccent[700]!; // Vibrant green
      final Paint onlineBorderPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0; // White border for contrast

      final Offset indicatorPosition = Offset(
        markerSize -
            onlineIndicatorSize / 2 -
            borderSize, // Position at bottom-right
        markerSize - onlineIndicatorSize / 2 - borderSize,
      );

      canvas.drawCircle(
        indicatorPosition,
        onlineIndicatorSize / 2,
        onlineBorderPaint,
      );
      canvas.drawCircle(
        indicatorPosition,
        onlineIndicatorSize / 2 - 2,
        onlinePaint,
      ); // Smaller circle inside border
    } else {
      // Optional: Draw an offline indicator (e.g., grey dot)
      // For now, no indicator means offline to keep it simple.
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

  void _drawPlaceholder(
    Canvas canvas,
    double markerSize,
    double profilePicSize,
  ) {
    final placeholderPaint = Paint()..color = Colors.grey[300]!;
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      profilePicSize / 2,
      placeholderPaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '👤',
        style: TextStyle(fontSize: 48),
      ), // Larger icon for placeholder
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

  // NEW: Helper method to animate camera
  void _animateCameraToUserLocation(GeoPoint? location) {
    if (_mapController != null &&
        location != null &&
        location.latitude != 0 &&
        location.longitude != 0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          19,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    // This provider should give you all other users' locations
    final userLocationsAsync = ref.watch(
      profile_repo.userLocationsProvider,
    ); // Use the prefixed provider
    // This provider gives you the current user's profile, including their location
    final currentUserProfileAsync = ref.watch(userProfileProvider(user.uid));

    // NEW: Listen for changes in the current user's profile location
    ref.listen<AsyncValue<UserProfileModel?>>(userProfileProvider(user.uid), (
      _,
      next,
    ) {
      // Ensure the map controller is ready and new location data is valid
      if (next.hasValue && next.value != null && next.value!.location != null) {
        _animateCameraToUserLocation(next.value!.location);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Stack(
        // Use Stack to place map and potentially messages
        children: [
          // Always render the GoogleMap
          currentUserProfileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, _) => Center(child: Text('Error loading profile: $err')),
            data: (currentUser) {
              final LatLng cameraTarget;
              // Set camera target based on user's location if available and permitted, otherwise use default campus
              if (_isLocationPermissionGranted &&
                  _isLocationServiceEnabled &&
                  currentUser != null &&
                  currentUser.location != null &&
                  currentUser.location!.latitude != 0 &&
                  currentUser.location!.longitude != 0) {
                cameraTarget = LatLng(
                  currentUser.location!.latitude,
                  currentUser.location!.longitude,
                );
              } else {
                cameraTarget = _defaultCampusLocation;
              }

              return userLocationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, _) =>
                        Center(child: Text('Error loading users: $err')),
                data: (users) {
                  _updateMarkers(users); // Update markers for all users on map
                  return GoogleMap(
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      try {
                        final jsonString = await rootBundle.loadString(
                          'assets/map_style.json',
                        );
                        await _mapController?.setMapStyle(jsonString);
                        // Initial move camera to user's location or default after map is created
                        // This ensures centering on initial load/rebuild
                        _animateCameraToUserLocation(
                          currentUser?.location ?? null,
                        ); // Use the new method
                      } catch (e) {
                        debugPrint('Failed to load map style: $e');
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      // This is just the very initial position that will be immediately updated by onMapCreated
                      target: cameraTarget,
                      zoom: 19,
                    ),
                    markers: _markers,
                    myLocationEnabled:
                        _isLocationPermissionGranted, // Enable/disable based on permission
                    myLocationButtonEnabled:
                        _isLocationPermissionGranted, // Enable/disable based on permission
                    zoomControlsEnabled: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
