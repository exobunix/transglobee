class RideModel {
  final String id;
  final String userId;
  final String? driverId;
  final LocationPoint pickupLocation;
  final LocationPoint dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final String serviceType;
  final String status;
  final double? fareEstimation;
  final double? actualFare;
  final double? distance;
  final double? duration;
  final String? otp;
  final String? delayReason;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final DateTime? createdAt;

  RideModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.serviceType,
    this.status = 'pending',
    this.fareEstimation,
    this.actualFare,
    this.distance,
    this.duration,
    this.otp,
    this.delayReason,
    this.isScheduled = false,
    this.scheduledTime,
    this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return RideModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      driverId: json['driverId'],
      pickupLocation: LocationPoint.fromJson(json['pickupLocation'] ?? {}),
      dropoffLocation: LocationPoint.fromJson(json['dropoffLocation'] ?? {}),
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',
      serviceType: json['serviceType'] ?? 'cab',
      status: json['status'] ?? 'pending',
      fareEstimation: parseDouble(json['fareEstimation']),
      actualFare: parseDouble(json['actualFare']),
      distance: parseDouble(json['distance']),
      duration: parseDouble(json['duration']),
      otp: json['otp'],
      delayReason: json['delayReason'],
      isScheduled: json['isScheduled'] ?? false,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'driverId': driverId,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'serviceType': serviceType,
      'status': status,
      'fareEstimation': fareEstimation,
      'actualFare': actualFare,
      'distance': distance,
      'duration': duration,
      'otp': otp,
      'delayReason': delayReason,
      'isScheduled': isScheduled,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Searching for driver...';
      case 'accepted':
        return 'Driver assigned';
      case 'on_the_way':
        return 'Driver is on the way';
      case 'started':
        return 'Ride in progress';
      case 'completed':
        return 'Ride completed';
      case 'cancelled':
        return 'Ride cancelled';
      case 'delayed':
        return 'Delayed: ${delayReason ?? 'Unknown reason'}';
      default:
        return status;
    }
  }
}

class LocationPoint {
  final String type;
  final List<double> coordinates;

  LocationPoint({this.type = 'Point', required this.coordinates});

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      type: json['type'] ?? 'Point',
      coordinates:
          (json['coordinates'] as List<dynamic>?)
              ?.map((e) {
                if (e is num) return e.toDouble();
                if (e is String) return double.tryParse(e) ?? 0.0;
                return 0.0;
              })
              .toList() ??
          [0, 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}
