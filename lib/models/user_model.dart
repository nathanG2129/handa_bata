class UserModel {
  final String uid;
  final String username;
  final String email;
  final String profilePictureUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.profilePictureUrl,
  });

  // Factory method to create a UserModel from a map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      username: data['username'],
      email: data['email'],
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  // Method to convert UserModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}