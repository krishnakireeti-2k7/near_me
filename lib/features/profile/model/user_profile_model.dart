// file: lib/features/profile/model/user_profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String name;
  final List<String>
  tags; // MODIFIED: Renamed from 'interests', removed student-specific fields
  final String profileImageUrl;
  final Map<String, String> socialHandles;
  final GeoPoint? location;
  final String shortBio;
  final Timestamp? lastActive; // NEW: Field to store last active timestamp

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.tags, // MODIFIED: Renamed parameter
    required this.profileImageUrl,
    required this.socialHandles,
    this.location,
    required this.shortBio,
    this.lastActive, // NEW: Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'tags': tags, // MODIFIED: Renamed field
      'profileImageUrl': profileImageUrl,
      'socialHandles': socialHandles,
      'location': location,
      'shortBio': shortBio,
      'lastActive': lastActive, // NEW: Add to the map
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] as String, // Explicit cast for safety
      name: map['name'] as String, // Explicit cast for safety
      tags:
          map['tags'] != null
              ? List<String>.from(map['tags'])
              : [], // MODIFIED: Renamed field
      profileImageUrl:
          map['profileImageUrl'] as String, // Explicit cast for safety
      socialHandles:
          map['socialHandles'] != null
              ? Map<String, String>.from(map['socialHandles'])
              : {},
      location: map['location'] != null ? map['location'] as GeoPoint : null,
      shortBio:
          map['shortBio'] as String? ?? '', // Explicit cast and null-check
      lastActive: map['lastActive'] as Timestamp?, // NEW: From the map
    );
  }

  factory UserProfileModel.empty() {
    return UserProfileModel(
      uid: '',
      name: '',
      tags: [], // MODIFIED: Renamed field
      profileImageUrl: '',
      socialHandles: {},
      location: null,
      shortBio: '',
      lastActive: null, // NEW: To the empty constructor
    );
  }

  // OPTIONAL: Add a copyWith method for easier state updates (highly recommended)
  UserProfileModel copyWith({
    String? uid,
    String? name,
    List<String>? tags,
    String? profileImageUrl,
    Map<String, String>? socialHandles,
    GeoPoint? location,
    String? shortBio,
    Timestamp? lastActive,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      socialHandles: socialHandles ?? this.socialHandles,
      location: location ?? this.location,
      shortBio: shortBio ?? this.shortBio,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
