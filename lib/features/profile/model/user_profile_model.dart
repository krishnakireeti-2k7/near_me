// file: lib/features/profile/model/user_profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Add this import for `@required` if you use it

class UserProfileModel {
  final String uid;
  final String name;
  final String? nameLowercase; // New field for case-insensitive search
  final List<String> tags;
  final String profileImageUrl;
  final Map<String, String> socialHandles;
  final GeoPoint? location;
  final String shortBio;
  final Timestamp? lastActive;
  final String? fcmToken;
  final int totalInterestsCount;

  UserProfileModel({
    required this.uid,
    required this.name,
    this.nameLowercase, // New parameter
    required this.tags,
    required this.profileImageUrl,
    required this.socialHandles,
    this.location,
    required this.shortBio,
    this.lastActive,
    this.fcmToken,
    this.totalInterestsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'name_lowercase':
          name.toLowerCase(), // Automatically save the lowercase version
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
      nameLowercase: map['name_lowercase'] as String?, // Retrieve the new field
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
      nameLowercase: '', // Provide a default value
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
    String? nameLowercase,
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
      nameLowercase: nameLowercase ?? this.nameLowercase,
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
