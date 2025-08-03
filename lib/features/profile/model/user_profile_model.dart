// file: lib/features/profile/model/user_profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String name;
  final List<String> tags;
  final String profileImageUrl;
  final Map<String, String> socialHandles;
  final GeoPoint? location;
  final String shortBio;
  final Timestamp? lastActive;
  final String? fcmToken;
  final int totalInterestsCount; // Keep this for all-time count

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.tags,
    required this.profileImageUrl,
    required this.socialHandles,
    this.location,
    required this.shortBio,
    this.lastActive,
    this.fcmToken,
    this.totalInterestsCount = 0, // Default for total count
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'tags': tags,
      'profileImageUrl': profileImageUrl,
      'socialHandles': socialHandles,
      'location': location,
      'shortBio': shortBio,
      'lastActive': lastActive,
      'fcmToken': fcmToken,
      'totalInterestsCount': totalInterestsCount,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      profileImageUrl: map['profileImageUrl'] as String,
      socialHandles:
          map['socialHandles'] != null
              ? Map<String, String>.from(map['socialHandles'])
              : {},
      location: map['location'] != null ? map['location'] as GeoPoint : null,
      shortBio: map['shortBio'] as String? ?? '',
      lastActive: map['lastActive'] as Timestamp?,
      fcmToken: map['fcmToken'] as String?,
      totalInterestsCount: map['totalInterestsCount'] as int? ?? 0,
    );
  }

  factory UserProfileModel.empty() {
    return UserProfileModel(
      uid: '',
      name: '',
      tags: [],
      profileImageUrl: '',
      socialHandles: {},
      location: null,
      shortBio: '',
      lastActive: null,
      fcmToken: null,
      totalInterestsCount: 0,
    );
  }

  UserProfileModel copyWith({
    String? uid,
    String? name,
    List<String>? tags,
    String? profileImageUrl,
    Map<String, String>? socialHandles,
    GeoPoint? location,
    String? shortBio,
    Timestamp? lastActive,
    String? fcmToken,
    int? totalInterestsCount,
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
      fcmToken: fcmToken ?? this.fcmToken,
      totalInterestsCount: totalInterestsCount ?? this.totalInterestsCount,
    );
  }
}
