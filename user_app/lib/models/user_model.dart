class UserRoute {
  final String id;
  final String name;
  final String? source;
  final String? destination;
  final String? startLocation;
  final String? endLocation;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final double? distance;
  final double? estimatedDuration;

  UserRoute({
    required this.id,
    required this.name,
    this.source,
    this.destination,
    this.startLocation,
    this.endLocation,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.distance,
    this.estimatedDuration,
  });

  factory UserRoute.fromJson(Map<String, dynamic> json) {
    return UserRoute(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      source: json['source'],
      destination: json['destination'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      startLat: json['startLat'] != null ? (json['startLat'] as num).toDouble() : null,
      startLng: json['startLng'] != null ? (json['startLng'] as num).toDouble() : null,
      endLat: json['endLat'] != null ? (json['endLat'] as num).toDouble() : null,
      endLng: json['endLng'] != null ? (json['endLng'] as num).toDouble() : null,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      estimatedDuration: json['estimatedDuration'] != null ? (json['estimatedDuration'] as num).toDouble() : null,
    );
  }
}

class UserModel {
  final String id;
  final String firebaseId;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profilePic;
  final String role;
  final bool isActive;
  final List<UserRoute> assignedRoutes;

  UserModel({
    required this.id,
    required this.firebaseId,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profilePic,
    this.role = 'user',
    this.isActive = true,
    this.assignedRoutes = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var routesList = json['assignedRoutes'] as List?;
    List<UserRoute> parsedRoutes = [];
    if (routesList != null) {
      parsedRoutes = routesList
          .map((r) => r is Map ? UserRoute.fromJson(Map<String, dynamic>.from(r)) : null)
          .whereType<UserRoute>()
          .toList();
    }
    return UserModel(
      id: json['_id'] ?? '',
      firebaseId: json['firebaseId'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      phoneNumber: json['phoneNumber'] ?? json['mobileNumber'],
      profilePic: json['profilePic'],
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
      assignedRoutes: parsedRoutes,
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
