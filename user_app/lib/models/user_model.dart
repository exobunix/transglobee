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

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory UserRoute.fromJson(Map<String, dynamic> json) {
    final stops = json['stops'] as List?;
    double? stopStartLat;
    double? stopStartLng;
    double? stopEndLat;
    double? stopEndLng;

    if (stops != null && stops.isNotEmpty) {
      final firstStop = stops.first;
      if (firstStop is Map && firstStop['coordinates'] is Map) {
        stopStartLat = _parseDouble(firstStop['coordinates']['lat']);
        stopStartLng = _parseDouble(firstStop['coordinates']['lng']);
      }
      final lastStop = stops.last;
      if (lastStop is Map && lastStop['coordinates'] is Map) {
        stopEndLat = _parseDouble(lastStop['coordinates']['lat']);
        stopEndLng = _parseDouble(lastStop['coordinates']['lng']);
      }
    }

    return UserRoute(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      source: json['source']?.toString(),
      destination: json['destination']?.toString(),
      startLocation: json['startLocation']?.toString(),
      endLocation: json['endLocation']?.toString(),
      startLat: _parseDouble(json['startLat']) ?? stopStartLat,
      startLng: _parseDouble(json['startLng']) ?? stopStartLng,
      endLat: _parseDouble(json['endLat']) ?? stopEndLat,
      endLng: _parseDouble(json['endLng']) ?? stopEndLng,
      distance: _parseDouble(json['distance']),
      estimatedDuration: _parseDouble(json['estimatedDuration']),
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
