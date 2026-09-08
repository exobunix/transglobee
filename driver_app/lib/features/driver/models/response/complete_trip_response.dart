import 'package:equatable/equatable.dart';

class CompleteTripResponse extends Equatable {
  final String bookingId;
  final String status;
  final double fare;
  final double distance;
  final int duration;
  final String completedAt;

  const CompleteTripResponse({
    required this.bookingId,
    required this.status,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.completedAt,
  });

  factory CompleteTripResponse.fromJson(Map<String, dynamic> json) {
    return CompleteTripResponse(
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
      fare: (json['fare'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      completedAt: json['completedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [bookingId, status, fare, distance, duration, completedAt];
}
