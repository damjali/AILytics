class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final String? gender;
  final DateTime? dateOfBirth;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.gender,
    this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
    );
  }
}