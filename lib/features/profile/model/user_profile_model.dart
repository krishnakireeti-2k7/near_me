class UserProfileModel {
  final String uid;
  final String name;
  final String collegeYear;
  final String branch;
  final List<String> interests;
  final String profileImageUrl;
  final Map<String, String>? socialHandles;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.collegeYear,
    required this.branch,
    required this.interests,
    required this.profileImageUrl,
    this.socialHandles,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final nonEmptyHandles = <String, String>{};
    if (socialHandles != null) {
      socialHandles!.forEach((key, value) {
        if (value.trim().isNotEmpty) {
          nonEmptyHandles[key] = value.trim();
        }
      });
    }

    return {
      'uid': uid,
      'name': name,
      'collegeYear': collegeYear,
      'branch': branch,
      'interests': interests,
      'profileImageUrl': profileImageUrl,
      'socialHandles': nonEmptyHandles,
    };
  }

  // From Firestore
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      collegeYear: map['collegeYear'] ?? '',
      branch: map['branch'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profileImageUrl: map['profileImageUrl'] ?? '',
      socialHandles: Map<String, String>.from(map['socialHandles'] ?? {}),
    );
  }
}
