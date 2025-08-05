// file: lib/features/map/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:uuid/uuid.dart';

// Your Google Maps API Key
const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchBarWidget extends StatefulWidget {
  // A callback function to notify the parent widget when a place is selected.
  final Function(Prediction) onPlaceSelected;
  final Function(String) onUserSearch;

  const SearchBarWidget({
    super.key,
    required this.onPlaceSelected,
    required this.onUserSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final places = GoogleMapsPlaces(apiKey: googleApiKey);
  final uuid = const Uuid();

  String? _sessionToken;
  List<Prediction> _placesSuggestions = [];
  // You'll add user suggestions here later
  // List<UserProfileModel> _userSuggestions = [];

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

    // Reset session token for a new search
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
    // We'll reset the session token and clear the suggestions after a selection.
    _sessionToken = null;
    _searchController.clear();
    setState(() {
      _placesSuggestions = [];
    });
    // Call the parent's callback with the selected place.
    widget.onPlaceSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 100,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for places or users...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      _getPlacesSuggestions(value);
                      // This will be for user search later.
                      widget.onUserSearch(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // This can be used for a direct search submission
                    // without needing to tap a suggestion.
                  },
                ),
              ],
            ),
          ),
          if (_placesSuggestions.isNotEmpty)
            Container(
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
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _placesSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _placesSuggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(suggestion.description ?? ''),
                    onTap: () => _handlePlaceTap(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
