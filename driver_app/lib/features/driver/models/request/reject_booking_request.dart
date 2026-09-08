import 'package:equatable/equatable.dart';

class RejectBookingRequest extends Equatable {
  final String bookingId;
  final String reason;

  const RejectBookingRequest({required this.bookingId, required this.reason});

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [bookingId, reason];
}
