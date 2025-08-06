// file: lib/features/map/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:near_me/features/profile/repository/profile_repository_provider.dart';

// Your Google Places API Key
const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

// Change from StatefulWidget to ConsumerStatefulWidget
class SearchBarWidget extends ConsumerStatefulWidget {
  final Function(LatLng) onPlaceSelected;
  final Function(String) onUserSearch;
  final BuildContext scaffoldContext;

  const SearchBarWidget({
    super.key,
    required this.onPlaceSelected,
    required this.onUserSearch,
    required this.scaffoldContext,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

// Change from State to ConsumerState
class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final places = GoogleMapsPlaces(apiKey: googleApiKey);
  final uuid = const Uuid();

  String? _sessionToken;
  List<Prediction> _placesSuggestions = [];
  List<UserProfileModel> _userSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = uuid.v4();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getPlacesSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placesSuggestions = [];
      });
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
      setState(() {
        _placesSuggestions = res.predictions!;
      });
    } else {
      debugPrint('Google Places API Error: ${res.errorMessage}');
    }
  }

  void _handlePlaceTap(Prediction place) async {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _placesSuggestions = [];
      _userSuggestions = [];
    });

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
      // Trigger the Google Places search
      _getPlacesSuggestions(query);

      // Watch the user search provider and get the results
      ref
          .read(searchUsersByNameProvider(query).future)
          .then((users) {
            setState(() {
              _userSuggestions = users;
            });
          })
          .catchError((error) {
            debugPrint('Error searching users: $error');
            setState(() {
              _userSuggestions = [];
            });
          });
    } else {
      setState(() {
        _isSearching = false;
        _placesSuggestions = [];
        _userSuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the updated build method that combines both place and user results.
    final hasSuggestions =
        _placesSuggestions.isNotEmpty || _userSuggestions.isNotEmpty;

    return Column(
      children: [
        // Your search bar UI remains the same.
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
                  onChanged: _onSearchChanged,
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
        ),

        // Display combined search results.
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
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  // Start of Places Section (now first)
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

                  // Divider between sections
                  if (_placesSuggestions.isNotEmpty &&
                      _userSuggestions.isNotEmpty)
                    const Divider(),

                  // Start of Users Section (now second)
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
                          // Navigate to the user's profile using the UID
                          context.push('/profile/${user.uid}');
                        },
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
