import 'package:equatable/equatable.dart';

class StartTripRequest extends Equatable {
  final String bookingId;
  final String otp;

  const StartTripRequest({required this.bookingId, required this.otp});

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'otp': otp,
    };
  }

  @override
  List<Object?> get props => [bookingId, otp];
}
