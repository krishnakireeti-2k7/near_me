// file: lib/features/map/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as place_fields;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Corrected import to avoid conflict with LatLng from places SDK
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;

import 'package:uuid/uuid.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

// Corrected import to the public API of the Places SDK
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
// Aliased import for PlaceField to avoid ambiguity with other packages

const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchBarWidget extends ConsumerStatefulWidget {
  // CORRECTED: Changed the type of LatLng to use the aliased one
  final Function(gmf.LatLng)? onPlaceSelected;
  final Function(String)? onUserSearch;
  final BuildContext? scaffoldContext;
  final Function(bool)? onSearchToggled;
  final String? initialQuery;
  final bool autoFocus;
  final bool showDrawerButton;
  // CHANGED: The type of the `onSearchUpdate` list to `AutocompletePrediction`
  final Function(List<AutocompletePrediction>, List<UserProfileModel>)?
  onSearchUpdate;

  const SearchBarWidget({
    super.key,
    this.onPlaceSelected,
    this.onUserSearch,
    this.scaffoldContext,
    this.onSearchToggled,
    this.initialQuery,
    this.autoFocus = false,
    this.showDrawerButton = true,
    this.onSearchUpdate,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => SearchBarWidgetState();
}

class SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  // CORRECTED: The FlutterGooglePlacesSdk constructor now requires an API key.
  final placesSdk = FlutterGooglePlacesSdk(googleApiKey);
  final uuid = const Uuid();

  List<AutocompletePrediction> _placesSuggestions = [];
  List<UserProfileModel> _userSuggestions = [];

  void clearSuggestions() {
    if (mounted) {
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      widget.onSearchToggled?.call(false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _searchController.addListener(() {
      final query = _searchController.text;
      if (widget.onSearchToggled != null) {
        widget.onSearchToggled!(query.isNotEmpty);
      }
      _onSearchChanged(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // CHANGED: The logic for getting place suggestions
  void _getPlacesSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _placesSuggestions = []);
      }
      return;
    }

    try {
      final response = await placesSdk.findAutocompletePredictions(
        query,
        countries: ['us', 'in'],
      );
      if (mounted) {
        setState(() {
          _placesSuggestions = response.predictions ?? [];
          widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
        });
      }
    } catch (e) {
      debugPrint('Google Places API Error: $e');
      if (mounted) {
        setState(() => _placesSuggestions = []);
        widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
      }
    }
  }

  // CHANGED: The logic for handling place tap and getting details
  void _handlePlaceTap(AutocompletePrediction place) async {
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearchToggled?.call(false);

    // CORRECTED: Aliased PlaceField to resolve the "Undefined name 'google_place'" error
    final placeDetails = await placesSdk.fetchPlace(
      place.placeId,
      fields: [place_fields.PlaceField.Location],
    );

    final location = placeDetails.place?.latLng;
    if (location != null) {
      // CORRECTED: Use the aliased LatLng
      widget.onPlaceSelected?.call(gmf.LatLng(location.lat, location.lng));
    }
  }

  void _onSearchChanged(String query) {
    if (query.isNotEmpty) {
      _getPlacesSuggestions(query);
      ref
          .read(searchUsersByNameProvider(query).future)
          .then((users) {
            if (mounted) {
              setState(() {
                _userSuggestions = users;
                widget.onSearchUpdate?.call(
                  _placesSuggestions,
                  _userSuggestions,
                );
              });
            }
          })
          .catchError((error) {
            debugPrint('Error searching users: $error');
            if (mounted) {
              setState(() => _userSuggestions = []);
              widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
            }
          });
    } else {
      if (mounted) {
        setState(() {
          _placesSuggestions = [];
          _userSuggestions = [];
          widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSuggestions =
        _placesSuggestions.isNotEmpty || _userSuggestions.isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.showDrawerButton && widget.scaffoldContext != null)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed:
                      () => Scaffold.of(widget.scaffoldContext!).openDrawer(),
                ),
              if (!widget.showDrawerButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: widget.autoFocus,
                  decoration: const InputDecoration(
                    hintText: 'Search for places or users...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
        ),

        if (hasSuggestions && widget.onSearchToggled != null)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  if (_placesSuggestions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Places',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._placesSuggestions.map((place) {
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(place.fullText ?? place.primaryText ?? ''),
                        onTap: () => _handlePlaceTap(place),
                      );
                    }).toList(),
                  ],
                  if (_placesSuggestions.isNotEmpty &&
                      _userSuggestions.isNotEmpty)
                    const Divider(),
                  if (_userSuggestions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Users',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._userSuggestions.map((user) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              user.profileImageUrl.isNotEmpty
                                  ? NetworkImage(user.profileImageUrl)
                                  : null,
                          child:
                              user.profileImageUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.shortBio),
                        onTap: () => context.push('/profile/${user.uid}'),
                      );
                    }).toList(),
                  ],
                  if (_searchController.text.isNotEmpty)
                    ListTile(
                      title: const Text(
                        'View All Results',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () {
                        context.push(
                          '/searchResults',
                          extra: {
                            'query': _searchController.text,
                            'places': _placesSuggestions,
                            'users': _userSuggestions,
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
