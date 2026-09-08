import 'package:equatable/equatable.dart';

class RejectBookingResponse extends Equatable {
  final String bookingId;
  final String status;

  const RejectBookingResponse({required this.bookingId, required this.status});

  factory RejectBookingResponse.fromJson(Map<String, dynamic> json) {
    return RejectBookingResponse(
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
    );
  }

  @override
  List<Object?> get props => [bookingId, status];
}
