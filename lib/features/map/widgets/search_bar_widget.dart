// file: lib/features/map/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

// Your Google Places API Key
const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchBarWidget extends StatefulWidget {
  // Now, the callback expects a LatLng
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
      _placesSuggestions = [];
    });

    // Get the place details to extract the coordinates
    final placeDetails = await places.getDetailsByPlaceId(
      place.placeId!,
      sessionToken: _sessionToken,
    );

    // Reset the session token for the next search
    _sessionToken = uuid.v4();

    final geometry = placeDetails.result?.geometry;
    if (geometry?.location != null) {
      // Pass the LatLng to the parent widget
      widget.onPlaceSelected(
        LatLng(geometry!.location.lat, geometry.location.lng),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onChanged: (value) {
                    _getPlacesSuggestions(value);
                    widget.onUserSearch(value);
                  },
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
        ),
        if (_placesSuggestions.isNotEmpty)
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
          ),
      ],
    );
  }
}
