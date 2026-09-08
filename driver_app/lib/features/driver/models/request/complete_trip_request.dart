import 'package:equatable/equatable.dart';

class CompleteTripRequest extends Equatable {
  final String bookingId;
  final double distance;
  final int duration;

  const CompleteTripRequest({
    required this.bookingId,
    required this.distance,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'distance': distance,
      'duration': duration,
    };
  }

  @override
  List<Object?> get props => [bookingId, distance, duration];
}
