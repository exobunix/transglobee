import 'package:equatable/equatable.dart';

class AcceptBookingRequest extends Equatable {
  final String bookingId;

  const AcceptBookingRequest({required this.bookingId});

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
    };
  }

  @override
  List<Object?> get props => [bookingId];
}
