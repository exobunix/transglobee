import 'package:equatable/equatable.dart';

class StartTripResponse extends Equatable {
  final String bookingId;
  final String status;
  final String startedAt;

  const StartTripResponse({
    required this.bookingId,
    required this.status,
    required this.startedAt,
  });

  factory StartTripResponse.fromJson(Map<String, dynamic> json) {
    return StartTripResponse(
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
      startedAt: json['startedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [bookingId, status, startedAt];
}
