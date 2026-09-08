class UserModel {
  final String id;
  final String firebaseId;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profilePic;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.firebaseId,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profilePic,
    this.role = 'user',
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      firebaseId: json['firebaseId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      profilePic: json['profilePic'],
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firebaseId': firebaseId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'role': role,
      'isActive': isActive,
    };
  }
}
