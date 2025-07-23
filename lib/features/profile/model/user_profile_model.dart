import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String name;
  final String collegeYear;
  final String branch;
  final List<String> interests;
  final String profileImageUrl;
  final Map<String, String> socialHandles;
  final GeoPoint? location;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.collegeYear,
    required this.branch,
    required this.interests,
    required this.profileImageUrl,
    required this.socialHandles,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'collegeYear': collegeYear,
      'branch': branch,
      'interests': interests,
      'profileImageUrl': profileImageUrl,
      'socialHandles': socialHandles,
      'location': location,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'],
      name: map['name'],
      collegeYear: map['collegeYear'],
      branch: map['branch'],
      interests:
          map['interests'] != null ? List<String>.from(map['interests']) : [],
      profileImageUrl: map['profileImageUrl'],
      socialHandles:
          map['socialHandles'] != null
              ? Map<String, String>.from(map['socialHandles'])
              : {},
      location: map['location'] != null ? map['location'] as GeoPoint : null,
    );
  }

  factory UserProfileModel.empty() {
    return UserProfileModel(
      uid: '',
      name: '',
      collegeYear: '',
      branch: '',
      interests: [],
      profileImageUrl: '',
      socialHandles: {},
      location: null,
    );
  }
}
