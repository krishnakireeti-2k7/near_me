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
  final Function(LatLng)? onPlaceSelected;
  final Function(String)? onUserSearch;
  final BuildContext? scaffoldContext;
  final Function(bool)? onSearchToggled;
  final String? initialQuery;
  final bool autoFocus;
  final bool showDrawerButton;
  final Function(List<Prediction>, List<UserProfileModel>)? onSearchUpdate;

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
  final places = GoogleMapsPlaces(apiKey: googleApiKey);
  final uuid = const Uuid();

  String? _sessionToken;
  List<Prediction> _placesSuggestions = [];
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
    _sessionToken = uuid.v4();
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
        setState(() {
          _placesSuggestions = res.predictions!;
          // Call the update callback to notify the parent
          widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
        });
      }
    } else {
      debugPrint('Google Places API Error: ${res.errorMessage}');
    }
  }

  void _handlePlaceTap(Prediction place) async {
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearchToggled?.call(false);

    final placeDetails = await places.getDetailsByPlaceId(
      place.placeId!,
      sessionToken: _sessionToken,
    );
    _sessionToken = uuid.v4();

    final geometry = placeDetails.result?.geometry;
    if (geometry?.location != null) {
      widget.onPlaceSelected?.call(
        LatLng(geometry!.location.lat, geometry.location.lng),
      );
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
                // Call the update callback to notify the parent
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
              // Call the update callback on error as well
              widget.onSearchUpdate?.call(_placesSuggestions, _userSuggestions);
            }
          });
    } else {
      if (mounted) {
        setState(() {
          _placesSuggestions = [];
          _userSuggestions = [];
          // Call the update callback for empty query
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
              if (!widget
                  .showDrawerButton) // Show back button on results screen
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

        // This section is only for the map screen and not for the search results screen
        // The condition has been simplified to fix the logical flaw
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
                            'query': _searchController.text,
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
