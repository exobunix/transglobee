import 'package:equatable/equatable.dart';

class UpdateLocationResponse extends Equatable {
  final double lat;
  final double lng;
  final String updatedAt;

  const UpdateLocationResponse({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory UpdateLocationResponse.fromJson(Map<String, dynamic> json) {
    return UpdateLocationResponse(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [lat, lng, updatedAt];
}
