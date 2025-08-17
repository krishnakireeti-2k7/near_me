// file: lib/features/map/widgets/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as place_fields;
import 'package:go_router/go_router.dart';
// Aliased `Maps_flutter` to avoid import conflicts with `flutter_google_places_sdk`.
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:near_me/features/map/widgets/search_bar_widget.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/map/controller/map_controller.dart';
// Correct import for the Google Places SDK.
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
// Aliased import for PlaceField to avoid ambiguity with other packages.

// The API key is now passed to the FlutterGooglePlacesSdk constructor.
const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final List<AutocompletePrediction> places;
  final List<UserProfileModel> users;
  final String initialQuery;

  const SearchResultsScreen({
    Key? key,
    required this.places,
    required this.users,
    required this.initialQuery,
  }) : super(key: key);

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late List<AutocompletePrediction> _places;
  late List<UserProfileModel> _users;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _places = widget.places;
    _users = widget.users;
  }

  void _onSearchUpdate(
    List<AutocompletePrediction> places,
    List<UserProfileModel> users,
  ) {
    setState(() {
      _places = places;
      _users = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: SearchBarWidget(
                    initialQuery: widget.initialQuery,
                    autoFocus: true,
                    showDrawerButton: false,
                    onSearchUpdate: _onSearchUpdate,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton('Places', 0),
                  const SizedBox(width: 6),
                  _buildToggleButton('Users', 1),
                ],
              ),
            ),
          ),

          Expanded(
            child:
                _selectedIndex == 0
                    ? _buildResultsList(
                      context,
                      _places,
                      (prediction) async {
                        // Instantiating the Places SDK with the API key
                        final placesApi = FlutterGooglePlacesSdk(googleApiKey);
                        try {
                          final details = await placesApi.fetchPlace(
                            prediction.placeId,
                            fields: [place_fields.PlaceField.Location],
                          );
                          final location = details.place?.latLng;
                          if (location != null) {
                            // Using the aliased `LatLng` from `Maps_flutter`.
                            ref
                                .read(googleMapControllerProvider.notifier)
                                .moveCamera(
                                  gmf.LatLng(location.lat, location.lng),
                                );
                            GoRouter.of(context).pop();
                          }
                        } catch (e) {
                          debugPrint('Error fetching place details: $e');
                        }
                      },
                      (prediction) => ListTile(
                        leading: const Icon(
                          Icons.place,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          prediction.fullText ??
                              prediction.primaryText ??
                              'No Description',
                        ),
                      ),
                    )
                    : _buildResultsList(
                      context,
                      _users,
                      (user) {
                        context.push('/profile/${user.uid}');
                      },
                      (user) => ListTile(
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
                        subtitle: Text(
                          user.shortBio.isNotEmpty
                              ? user.shortBio
                              : 'No bio available',
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected
                  ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList<T>(
    BuildContext context,
    List<T> items,
    Function(T) onTap,
    Widget Function(T) builder,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No results found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder:
          (context, index) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(onTap: () => onTap(item), child: builder(item));
      },
    );
  }
}
