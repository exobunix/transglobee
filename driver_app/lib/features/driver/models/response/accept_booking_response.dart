import 'package:equatable/equatable.dart';

class AcceptBookingResponse extends Equatable {
  final String bookingId;
  final String status;

  const AcceptBookingResponse({required this.bookingId, required this.status});

  factory AcceptBookingResponse.fromJson(Map<String, dynamic> json) {
    return AcceptBookingResponse(
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
    );
  }

  @override
  List<Object?> get props => [bookingId, status];
}
