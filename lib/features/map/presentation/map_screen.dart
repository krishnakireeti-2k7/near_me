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
import 'package:near_me/features/map/widgets/daily_friend_request_counter_widget.dart';
import 'package:near_me/features/map/widgets/mini_profile_card.dart';
import 'package:near_me/features/map/widgets/search_bar_widget.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart'
    as profile_repo;
import 'package:near_me/features/auth/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:near_me/widgets/main_drawer.dart';
import 'package:near_me/widgets/showFloatingsnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:near_me/features/map/widgets/daily_interests_counter_widget.dart';
import 'package:near_me/services/location_service.dart';
import 'package:collection/collection.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final GlobalKey<SearchBarWidgetState> _searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  Set<Marker> _markers = {};
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = false;
  String? _locationStatusMessage;
  bool _isSearchResultsVisible = false;
  CameraPosition? _cameraPosition;

  BitmapDescriptor? _defaultMarker;

  // Use `late` instead of `late final` because they might be re-initialized.
  late ProviderSubscription _disposeUserProfileListener;
  late ProviderSubscription _disposeUserLocationsListener;
  late ProviderSubscription _disposeAuthStateListener;

  UserProfileModel? _lastCurrentUserProfile;
  List<UserProfileModel> _lastUserLocations = [];

  @override
  void initState() {
    super.initState();
    _setDefaultMarker();

    // ✅ FIX: Call a new initialization method that sets up the listeners.
    _initializeListeners();
  }

  // ✅ NEW METHOD: To set up all listeners once.
  void _initializeListeners() {
    _disposeAuthStateListener = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        if (next.hasValue && next.value != null) {
          _startLocationUpdatesIfPermitted(next.value);
        }
      },
      fireImmediately: true,
    );

    _disposeUserProfileListener = ref.listenManual<
      AsyncValue<UserProfileModel?>
    >(profile_repo.currentUserProfileStreamProvider, (previous, next) {
      debugPrint('currentUserProfileStreamProvider updated: ${next.value}');
      final newProfile = next.value;
      if (newProfile?.location != null &&
          newProfile!.location!.latitude != 0 &&
          newProfile!.location!.longitude != 0 &&
          (_lastCurrentUserProfile?.location?.latitude !=
                  newProfile.location!.latitude ||
              _lastCurrentUserProfile?.location?.longitude !=
                  newProfile.location!.longitude)) {
        final newLatLng = LatLng(
          newProfile.location!.latitude,
          newProfile.location!.longitude,
        );
        final distance = _calculateDistance(
          _cameraPosition?.target ??
              LatLng(
                newProfile.location!.latitude,
                newProfile.location!.longitude,
              ),
          newLatLng,
        );
        if (distance > 10) {
          setState(() {
            _cameraPosition = CameraPosition(target: newLatLng, zoom: 19);
          });
        }
      }
      _lastCurrentUserProfile = newProfile;
      _updateAllMarkers();
    }, fireImmediately: true);

    _disposeUserLocationsListener = ref.listenManual<
      AsyncValue<List<UserProfileModel>>
    >(profile_repo.userLocationsProvider, (previous, next) {
      debugPrint('userLocationsProvider updated: ${next.value?.length} users');
      _lastUserLocations = next.value ?? [];
      _updateAllMarkers();
    }, fireImmediately: true);
  }

  Future<void> _setDefaultMarker() async {
    try {
      _defaultMarker = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/default_marker.png',
        width: 120,
      );
    } catch (e) {
      debugPrint('Error loading default marker: $e');
      _defaultMarker = BitmapDescriptor.defaultMarker;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ FIX: Remove the listener initialization from here to prevent the error.
  }

  @override
  void dispose() {
    _disposeUserProfileListener.close();
    _disposeUserLocationsListener.close();
    _disposeAuthStateListener.close();
    super.dispose();
  }

  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
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
    _goToCurrentLocationAndRecenter();

    ref.read(mapLocationProvider.notifier).setUserId(currentUser.uid);
    ref.read(mapLocationProvider.notifier).toggleLocationSharing(true);
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

  Future<void> _updateAllMarkers() async {
    if (_lastCurrentUserProfile == null) return;
    final Set<Marker> newMarkers = {};
    final String currentUserId = _lastCurrentUserProfile!.uid!;

    final currentMarker = await _createMarker(
      user: _lastCurrentUserProfile!,
      isCurrentUser: true,
    );
    if (currentMarker != null) {
      newMarkers.add(currentMarker);
    }

    for (final user in _lastUserLocations) {
      if (user.uid == currentUserId) continue;

      final otherMarker = await _createMarker(user: user, isCurrentUser: false);
      if (otherMarker != null) {
        newMarkers.add(otherMarker);
      }
    }

    if (!mounted) return;
    setState(() {
      _markers = newMarkers;
    });
  }

  Future<Marker?> _createMarker({
    required UserProfileModel user,
    required bool isCurrentUser,
  }) async {
    if (user.location == null ||
        (user.location!.latitude == 0 && user.location!.longitude == 0)) {
      return null;
    }

    String? imageUrlToShow = user.profileImageUrl;
    if (isCurrentUser) {
      if (imageUrlToShow == null || imageUrlToShow.isEmpty) {
        imageUrlToShow = ref.read(authStateProvider).value?.photoURL;
      }
    }

    final bool isActive =
        user.lastActive != null &&
        DateTime.now().difference(user.lastActive!.toDate()).inMinutes <= 5;

    final markerIcon = await _getCustomMarker(imageUrlToShow, isActive);

    return Marker(
      markerId: MarkerId(user.uid!),
      position: LatLng(user.location!.latitude, user.location!.longitude),
      icon: markerIcon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: user.name ?? user.uid),
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
  }

  Future<BitmapDescriptor> _getCustomMarker(
    String? imageUrl,
    bool isActive,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('No profile image, using default marker');
      return _defaultMarker ?? BitmapDescriptor.defaultMarker;
    }

    try {
      final imageProvider = NetworkImage(imageUrl);
      final Completer<ui.Image> completer = Completer();
      imageProvider
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener(
              (ImageInfo info, bool synchronousCall) {
                if (!completer.isCompleted) {
                  completer.complete(info.image);
                }
              },
              onError: (exception, stackTrace) {
                debugPrint('Error loading image for marker: $exception');
                if (!completer.isCompleted) {
                  completer.completeError(exception);
                }
              },
            ),
          );
      final ui.Image image = await completer.future;

      const double markerSize = 120.0;
      const double borderSize = 6.0;
      const double onlineIndicatorSize = 30.0;
      const double profilePicSize = markerSize - (borderSize * 2);

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

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
    } catch (e) {
      debugPrint('Error creating custom marker: $e');
      return _defaultMarker ?? BitmapDescriptor.defaultMarker;
    }
  }

  void _onPlaceSelected(Prediction place) async {}

  void _handlePlaceSelected(LatLng location) {
    final mapController = ref.read(googleMapControllerProvider);
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(location, 19));
    }
  }

  Future<void> _goToCurrentLocationAndRecenter() async {
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentLocation();
      final mapController = ref.read(googleMapControllerProvider);

      if (position != null && mapController != null) {
        final newCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 20,
        );
        setState(() {
          _cameraPosition = newCameraPosition;
        });
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(newCameraPosition),
        );
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MapScreen build called at ${DateTime.now()}');
    if (_cameraPosition == null) {
      final LatLng cameraTarget;
      if (_lastCurrentUserProfile?.location != null &&
          _lastCurrentUserProfile!.location!.latitude != 0 &&
          _lastCurrentUserProfile!.location!.longitude != 0) {
        cameraTarget = LatLng(
          _lastCurrentUserProfile!.location!.latitude,
          _lastCurrentUserProfile!.location!.longitude,
        );
      } else {
        cameraTarget = const LatLng(37.7749, -122.4194);
      }
      _cameraPosition = CameraPosition(target: cameraTarget, zoom: 19);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (controller) async {
                final mapControllerNotifier = ref.read(
                  googleMapControllerProvider.notifier,
                );
                mapControllerNotifier.setController(controller);

                try {
                  final jsonString = await rootBundle.loadString(
                    'assets/map_style.json',
                  );
                  await controller.setMapStyle(jsonString);
                  if (_isLocationPermissionGranted &&
                      _isLocationServiceEnabled) {
                    _goToCurrentLocationAndRecenter();
                  } else if (_lastCurrentUserProfile?.location != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _lastCurrentUserProfile!.location!.latitude,
                          _lastCurrentUserProfile!.location!.longitude,
                        ),
                        19,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to load map style: $e');
                }
              },
              initialCameraPosition: _cameraPosition!,
              markers: _markers,
              myLocationEnabled: _isLocationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          if (_isSearchResultsVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _searchBarKey.currentState?.clearSuggestions();
                  setState(() {
                    _isSearchResultsVisible = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.0)),
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Builder(
              builder: (context) {
                return SearchBarWidget(
                  key: _searchBarKey,
                  scaffoldContext: context,
                  onPlaceSelected: (location) {
                    _handlePlaceSelected(location);
                    _searchBarKey.currentState?.clearSuggestions();
                    setState(() {
                      _isSearchResultsVisible = false;
                    });
                  },
                  onUserSearch: (query) {
                    // TODO: Implement user search logic here.
                  },
                  onSearchToggled: (isVisible) {
                    setState(() {
                      _isSearchResultsVisible = isVisible;
                    });
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 130,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'locationButton',
              onPressed: _goToCurrentLocationAndRecenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 130,
            left: 20,
            child: Consumer(
              builder: (context, ref, child) {
                return Row(
                  children: const [
                    DailyInterestsCounterWidget(),
                    SizedBox(width: 10),
                    DailyFriendRequestsCounterWidget(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
