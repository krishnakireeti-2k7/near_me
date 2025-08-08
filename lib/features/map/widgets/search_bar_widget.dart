// file: lib/features/map/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchBarWidget extends ConsumerStatefulWidget {
  final Function(LatLng) onPlaceSelected;
  final Function(String) onUserSearch;
  final BuildContext scaffoldContext;
  // NEW: Add the onSearchToggled callback
  final Function(bool)? onSearchToggled;

  const SearchBarWidget({
    super.key,
    required this.onPlaceSelected,
    required this.onUserSearch,
    required this.scaffoldContext,
    this.onSearchToggled,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => SearchBarWidgetState();
}

class SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final places = GoogleMapsPlaces(apiKey: googleApiKey);
  final uuid = const Uuid();

  String? _sessionToken;
  List<Prediction> _placesSuggestions = [];
  List<UserProfileModel> _userSuggestions = [];
  bool _isSearching = false;

  void clearSuggestions() {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _placesSuggestions = [];
        _userSuggestions = [];
        _searchController.clear();
      });
      FocusManager.instance.primaryFocus?.unfocus();
      // NEW: Call the callback to notify the parent
      widget.onSearchToggled?.call(false);
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionToken = uuid.v4();
    _searchController.addListener(() {
      final isSearchingNow = _searchController.text.isNotEmpty;
      if (isSearchingNow != _isSearching) {
        _isSearching = isSearchingNow;
        // NEW: Call the callback when the search state changes
        widget.onSearchToggled?.call(isSearchingNow);
      }
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getPlacesSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _placesSuggestions = []);
      }
      return;
    }

    if (_sessionToken == null) {
      _sessionToken = uuid.v4();
    }

    final res = await places.autocomplete(
      query,
      sessionToken: _sessionToken,
      language: "en",
    );

    if (res.isOkay) {
      if (mounted) {
        setState(() => _placesSuggestions = res.predictions!);
      }
    } else {
      debugPrint('Google Places API Error: ${res.errorMessage}');
    }
  }

  void _handlePlaceTap(Prediction place) async {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _isSearching = false;
        _placesSuggestions = [];
        _userSuggestions = [];
      });
    }
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearchToggled?.call(false);

    final placeDetails = await places.getDetailsByPlaceId(
      place.placeId!,
      sessionToken: _sessionToken,
    );

    _sessionToken = uuid.v4();

    final geometry = placeDetails.result?.geometry;
    if (geometry?.location != null) {
      widget.onPlaceSelected(
        LatLng(geometry!.location.lat, geometry.location.lng),
      );
    }
  }

  void _onSearchChanged(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _getPlacesSuggestions(query);

      ref
          .read(searchUsersByNameProvider(query).future)
          .then((users) {
            if (mounted) {
              setState(() => _userSuggestions = users);
            }
          })
          .catchError((error) {
            debugPrint('Error searching users: $error');
            if (mounted) {
              setState(() => _userSuggestions = []);
            }
          });
    } else {
      setState(() {
        _isSearching = false;
        _placesSuggestions = [];
        _userSuggestions = [];
      });
    }
    // No need to call onSearchToggled here anymore, as it's handled in the listener.
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
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed:
                    () => Scaffold.of(widget.scaffoldContext).openDrawer(),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for places or users...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  // The onChanged is still needed for filtering, but onSearchToggled is handled by the listener
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
        ),
        if (hasSuggestions)
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
              child: Column(
                children: [
                  Expanded(
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
                              title: Text(place.description ?? ''),
                              onTap: () {
                                _handlePlaceTap(place);
                              },
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
                              onTap: () {
                                context.push('/profile/${user.uid}');
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/searchResults',
                          extra: {
                            'places': _placesSuggestions,
                            'users': _userSuggestions,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('View All Results'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
