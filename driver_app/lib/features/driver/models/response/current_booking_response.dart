import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String address;
  final double lat;
  final double lng;

  const LocationModel({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [address, lat, lng];
}

class CurrentBookingResponseModel extends Equatable {
  final String bookingId;
  final String passengerName;
  final String passengerPhone;
  final LocationModel? pickupLocation;
  final LocationModel? dropLocation;
  final String otp;
  final String status;
  final double estimatedFare;

  const CurrentBookingResponseModel({
    required this.bookingId,
    required this.passengerName,
    required this.passengerPhone,
    this.pickupLocation,
    this.dropLocation,
    required this.otp,
    required this.status,
    required this.estimatedFare,
  });

  factory CurrentBookingResponseModel.fromJson(Map<String, dynamic> json) {
    return CurrentBookingResponseModel(
      bookingId: json['bookingId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      pickupLocation: json['pickupLocation'] != null
          ? LocationModel.fromJson(json['pickupLocation'])
          : null,
      dropLocation: json['dropLocation'] != null
          ? LocationModel.fromJson(json['dropLocation'])
          : null,
      otp: json['otp'] ?? '',
      status: json['status'] ?? '',
      estimatedFare: (json['estimatedFare'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        passengerName,
        passengerPhone,
        pickupLocation,
        dropLocation,
        otp,
        status,
        estimatedFare
      ];
}
