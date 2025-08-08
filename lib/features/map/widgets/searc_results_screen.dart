// file: lib/features/map/widgets/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:near_me/features/profile/model/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:near_me/features/map/controller/map_controller.dart'; // Make sure this path is correct

// Your Google Places API Key
const String googleApiKey = 'AIzaSyCmom1vOzH73kkgxgPNMX-F65hSv2LKryI';

class SearchResultsScreen extends ConsumerWidget {
  final List<Prediction> places;
  final List<UserProfileModel> users;

  const SearchResultsScreen({
    Key? key,
    required this.places,
    required this.users,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Results'),
          bottom: const TabBar(tabs: [Tab(text: 'Places'), Tab(text: 'Users')]),
        ),
        body: TabBarView(
          children: [
            // Places Tab
            ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, index) {
                final prediction = places[index];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(prediction.description ?? 'No Description'),
                  onTap: () async {
                    // Use Places API to fetch LatLng before popping back
                    final placesApi = GoogleMapsPlaces(apiKey: googleApiKey);
                    final details = await placesApi.getDetailsByPlaceId(
                      prediction.placeId!,
                    );
                    final location = details.result.geometry?.location;
                    if (location != null) {
                      // Correctly use the updated provider name
                      ref
                          .read(googleMapControllerProvider.notifier)
                          .moveCamera(LatLng(location.lat, location.lng));
                      GoRouter.of(context).pop();
                    }
                  },
                );
              },
            ),

            // Users Tab
            ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
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
                  onTap: () {
                    // Navigate to the user's profile using the UID
                    context.push('/profile/${user.uid}');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
