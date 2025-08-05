// file: lib/features/map/presentation/map_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/map/widgets/search_bar_widget.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart'
    as profile_repo;
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:near_me/widgets/main_drawer.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/map/widgets/daily_interests_counter_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  String? _locationStatusMessage;

  late final MapController _mapControllerInstanceForCleanup;
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);

  // NEW: Places API client
  final places = GoogleMapsPlaces(apiKey: googleApiKey);

  @override
  void initState() {
    super.initState();
    _mapControllerInstanceForCleanup = ref.read(mapControllerProvider);
  }

  @override
  void dispose() {
    _mapControllerInstanceForCleanup.stopLocationUpdates();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationUpdatesIfPermitted(User? currentUser) async {
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
    _updateLocationStatus(isServiceEnabled: true);

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

    _updateLocationStatus(isPermissionGranted: true, message: null);
    _mapControllerInstanceForCleanup.startLocationUpdates(currentUser.uid);
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

      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showFloatingSnackBar(
              context,
              message,
              actionLabel: action != null ? 'Settings' : null,
              onActionPressed: action,
              duration: const Duration(seconds: 5),
            );
          }
        });
      }
    });
  }

  Future<void> _updateMarkers(List<UserProfileModel> users) async {
    final Set<Marker> newMarkers = {};
    final currentUserId = ref.read(authStateProvider).value?.uid;

    for (final user in users) {
      if (user.location != null &&
          user.location!.latitude != 0 &&
          user.location!.longitude != 0) {
        String? imageUrlToShow = user.profileImageUrl;
        if (imageUrlToShow == null || imageUrlToShow.isEmpty) {
          if (currentUserId != null && currentUserId == user.uid) {
            imageUrlToShow = ref.read(authStateProvider).value?.photoURL;
          }
        }

        final bool isActive =
            user.lastActive != null &&
            DateTime.now().difference(user.lastActive!.toDate()).inMinutes <= 5;

        final markerIcon = await _getCustomMarker(imageUrlToShow, isActive);
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
    if (!mounted) return;
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
    const double markerSize = 120.0;
    const double borderSize = 6.0;
    const double onlineIndicatorSize = 30.0;
    const double profilePicSize = markerSize - (borderSize * 2);

    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    final Paint shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10.0);
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2) - 5,
      shadowPaint,
    );
    canvas.drawCircle(
      Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2),
      borderPaint,
    );

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
        _drawPlaceholder(canvas, markerSize, profilePicSize);
      }
    } else {
      _drawPlaceholder(canvas, markerSize, profilePicSize);
    }

    if (isActive) {
      final Paint onlinePaint = Paint()..color = Colors.greenAccent[700]!;
      final Paint onlineBorderPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0;
      final Offset indicatorPosition = Offset(
        markerSize - onlineIndicatorSize / 2 - borderSize,
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
      text: const TextSpan(text: '👤', style: TextStyle(fontSize: 48)),
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

  // NEW METHOD to handle a selected place from the search bar
  void _onPlaceSelected(Prediction place) async {
    if (_mapController == null) return;

    // We need to get the place details to animate the camera.
    // The details API call is needed to get the exact lat/lng of the place
    final placeDetails = await places.getDetailsByPlaceId(place.placeId!);
    final geometry = placeDetails.result?.geometry;

    if (geometry?.location != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(geometry!.location.lat, geometry.location.lng),
          19,
        ),
      );
      // TODO: Here, you would also filter your user list to show users near this location
    }
  }

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
    final userProfileAsyncValue = ref.watch(currentUserProfileStreamProvider);

    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _startLocationUpdatesIfPermitted(next.value);
      }
    });

    ref.listen<AsyncValue<UserProfileModel?>>(
      currentUserProfileStreamProvider,
      (previous, next) {
        if (next.hasValue &&
            next.value != null &&
            next.value!.location != null) {
          _animateCameraToUserLocation(next.value!.location);
        }
      },
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const MainDrawer(),
      body: userProfileAsyncValue.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(
              child: Text("User profile not found. Please log in again."),
            );
          }

          final userLocationsAsync = ref.watch(
            profile_repo.userLocationsProvider,
          );

          return userLocationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading users: $err')),
            data: (users) {
              _updateMarkers(users);
              final LatLng cameraTarget;
              if (_isLocationPermissionGranted &&
                  _isLocationServiceEnabled &&
                  currentUser.location != null &&
                  currentUser.location!.latitude != 0 &&
                  currentUser.location!.longitude != 0) {
                cameraTarget = LatLng(
                  currentUser.location!.latitude,
                  currentUser.location!.longitude,
                );
              } else {
                cameraTarget = _defaultLocation;
              }

              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      try {
                        final jsonString = await rootBundle.loadString(
                          'assets/map_style.json',
                        );
                        await _mapController?.setMapStyle(jsonString);
                        _animateCameraToUserLocation(currentUser.location);
                      } catch (e) {
                        debugPrint('Failed to load map style: $e');
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: cameraTarget,
                      zoom: 19,
                    ),
                    markers: _markers,
                    myLocationEnabled: _isLocationPermissionGranted,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                  Positioned(
                    top: 50,
                    left: 20,
                    child: Builder(
                      builder: (context) {
                        return FloatingActionButton(
                          heroTag: 'drawerButton',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          child: const Icon(Icons.menu),
                          shape:
                              const CircleBorder(), // Explicitly make it a circle
                        );
                      },
                    ),
                  ),
                  // UPDATED: Replaced the old search bar with the new widget
                  Positioned(
                    top: 50,
                    left: 100,
                    right: 20,
                    child: SearchBarWidget(
                      onPlaceSelected: _onPlaceSelected,
                      onUserSearch: (query) {
                        // TODO: Implement user search logic here.
                      },
                    ),
                  ),
                  Positioned(
                    top: 130,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'locationButton',
                      onPressed: () {
                        final userLocation =
                            ref
                                .read(currentUserProfileStreamProvider)
                                .value
                                ?.location;
                        _animateCameraToUserLocation(userLocation);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: DailyInterestsCounterWidget(),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
