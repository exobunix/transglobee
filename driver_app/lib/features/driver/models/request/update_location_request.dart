import 'package:equatable/equatable.dart';

class UpdateLocationRequest extends Equatable {
  final double lat;
  final double lng;
  final double? heading;
  final String? bookingId;

  const UpdateLocationRequest({
    required this.lat,
    required this.lng,
    this.heading,
    this.bookingId,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (bookingId != null) 'bookingId': bookingId,
    };
  }

  @override
  List<Object?> get props => [lat, lng, heading, bookingId];
}
