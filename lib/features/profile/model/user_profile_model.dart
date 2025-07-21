class UserProfileModel {
  final String uid;
  final String name;
  final String collegeYear;
  final String branch;
  final List<String> interests;
  final String profileImageUrl;
  final Map<String, String>? socialHandles;
  final double? latitude;
  final double? longitude;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.collegeYear,
    required this.branch,
    required this.interests,
    required this.profileImageUrl,
    this.socialHandles,
    this.latitude,
    this.longitude,
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
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      collegeYear: map['collegeYear'] ?? '',
      branch: map['branch'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profileImageUrl: map['profileImageUrl'] ?? '',
      socialHandles: Map<String, String>.from(map['socialHandles'] ?? {}),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
