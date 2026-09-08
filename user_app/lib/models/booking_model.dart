import 'ride_model.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String type;
  final String status;
  final double? fare;
  final double? estimatedFare;
  final double? estimatedCost;
  final LocationData? pickupLocation;
  final LocationData? dropLocation;
  final DriverData? driver;
  final PackageDetails? packageDetails;
  final String? vehicleType;
  final DateTime? scheduledTime;
  final String? date;
  final List<LogisticsSegment> segments;
  final Map<String, dynamic> rawJson;

  BookingModel({
    required this.bookingId,
    this.userId = '',
    required this.type,
    required this.status,
    this.fare,
    this.estimatedFare,
    this.estimatedCost,
    this.pickupLocation,
    this.dropLocation,
    this.driver,
    this.packageDetails,
    this.vehicleType,
    this.scheduledTime,
    this.date,
    this.segments = const [],
    this.rawJson = const {},
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      LocationData? pickup;
      LocationData? drop;
      if (json['locations'] is List && (json['locations'] as List).isNotEmpty) {
        final locs = json['locations'] as List;
        final pLoc = locs.firstWhere((e) => e['type'] == 'pickup' || e['type'] == 'origin', orElse: () => locs[0]);
        final dLoc = locs.firstWhere((e) => e['type'] == 'dropoff' || e['type'] == 'destination', orElse: () => locs.length > 1 ? locs[1] : null);
        if (pLoc != null) {
          pickup = LocationData(
            lat: (pLoc['latitude'] ?? pLoc['lat'] ?? 0.0).toDouble(),
            lng: (pLoc['longitude'] ?? pLoc['lng'] ?? 0.0).toDouble(),
          );
        }
        if (dLoc != null) {
          drop = LocationData(
            lat: (dLoc['latitude'] ?? dLoc['lat'] ?? 0.0).toDouble(),
            lng: (dLoc['longitude'] ?? dLoc['lng'] ?? 0.0).toDouble(),
          );
        }
      } else {
        pickup = json['pickupLocation'] != null
            ? LocationData.fromJson(json['pickupLocation'])
            : null;
        drop = json['dropLocation'] != null
            ? LocationData.fromJson(json['dropLocation'])
            : null;
      }

      String resolveType() {
        final display = json['displayType']?.toString();
        if (display != null && display.isNotEmpty) return display.toLowerCase();
        final cat = (json['bookingCategory'] ?? json['type'] ?? '').toString().toLowerCase();
        if (cat == 'cab' || json['rideMode'] != null && json['locations'] is List) {
          return 'cab';
        }
        if (cat.isNotEmpty) return cat;
        if (json['items'] is List && (json['items'] as List).isNotEmpty) return 'logistics';
        return json['rideMode'] != null ? 'cab' : 'logistics';
      }

      return BookingModel(
        bookingId: json['bookingId'] ?? json['_id'] ?? '',
        userId: json['userId']?.toString() ?? '',
        type: resolveType(),
        status: json['status'] ?? '',
        fare: (json['fare'] ?? json['totalFare'] ?? json['totalPrice'])?.toDouble(),
        estimatedFare: json['estimatedFare']?.toDouble(),
        estimatedCost: json['estimatedCost']?.toDouble(),
        pickupLocation: pickup,
        dropLocation: drop,
        driver: json['driver'] != null
            ? DriverData.fromJson(Map<String, dynamic>.from(json['driver'] as Map))
            : (json['driverSnapshot'] != null
                ? DriverData.fromJson(Map<String, dynamic>.from(json['driverSnapshot'] as Map))
                : (json['driver_snapshot'] != null
                    ? DriverData.fromJson(Map<String, dynamic>.from(json['driver_snapshot'] as Map))
                    : null)),
        packageDetails: json['packageDetails'] != null
            ? PackageDetails.fromJson(json['packageDetails'])
            : null,
        vehicleType: json['vehicleType'] ?? json['rideMode'],
        scheduledTime: json['scheduledTime'] != null
            ? DateTime.tryParse(json['scheduledTime'])
            : null,
        date: json['date'],
        segments: (json['segments'] as List?)
                ?.map((s) => LogisticsSegment.fromJson(s))
                .toList() ??
            [],
        rawJson: json,
      );
    } catch (e, stack) {
      print("ERROR PARSING BOOKING MODEL: $e");
      print("STACK: $stack");
      rethrow;
    }
  }
}

class LocationData {
  final double lat;
  final double lng;

  LocationData({required this.lat, required this.lng});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class DriverData {
  final String name;
  final String? vehicle;
  final String? phone;
  final String? photo;

  DriverData({required this.name, this.vehicle, this.phone, this.photo});

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      name: json['name']?.toString() ?? '',
      vehicle: json['vehicle']?.toString() ??
          json['vehicleName']?.toString() ??
          json['vehicle_name']?.toString() ??
          '',
      phone: json['phone']?.toString() ?? json['mobileNumber']?.toString() ?? '',
      photo: json['photo']?.toString() ?? json['image']?.toString() ?? '',
    );
  }
}

class PackageDetails {
  final double weight;
  final String description;

  PackageDetails({required this.weight, required this.description});

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      weight: (json['weight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'description': description,
      };
}
