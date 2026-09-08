import 'package:equatable/equatable.dart';

class BookingItemModel extends Equatable {
  final String bookingId;
  final String passengerName;
  final String pickupLocation;
  final String dropLocation;
  final double fare;
  final double distance;
  final int duration;
  final String status;
  final String completedAt;

  const BookingItemModel({
    required this.bookingId,
    required this.passengerName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.status,
    required this.completedAt,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      bookingId: json['bookingId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      fare: (json['fare'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      status: json['status'] ?? '',
      completedAt: json['completedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        passengerName,
        pickupLocation,
        dropLocation,
        fare,
        distance,
        duration,
        status,
        completedAt
      ];
}

class BookingHistoryModel extends Equatable {
  final int page;
  final int limit;
  final int total;
  final List<BookingItemModel> bookings;

  const BookingHistoryModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.bookings,
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    var list = json['bookings'] as List? ?? [];
    List<BookingItemModel> items =
        list.map((i) => BookingItemModel.fromJson(i)).toList();

    return BookingHistoryModel(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      bookings: items,
    );
  }

  @override
  List<Object?> get props => [page, limit, total, bookings];
}
