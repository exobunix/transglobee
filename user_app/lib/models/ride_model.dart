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
  final String? vehicleType;
  final String? typeOfGood;
  final DateTime? createdAt;
  final List<LogisticsSegment> segments;

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
    this.vehicleType,
    this.typeOfGood,
    this.createdAt,
    this.segments = const [],
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    double? parseDistance(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return cleaned.isEmpty ? null : double.tryParse(cleaned);
      }
      return null;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    String extractAddress(dynamic value, Map<String, dynamic> fallback) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      final map = asMap(value);
      final candidates = [
        map['address'],
        map['fullAddress'],
        map['label'],
        map['name'],
        map['title'],
        fallback['address'],
        fallback['fullAddress'],
        fallback['label'],
        fallback['name'],
        fallback['title'],
      ];
      for (final candidate in candidates) {
        final text = candidate?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    dynamic pickupRaw = json['pickupLocation'] ?? json['pickup'];
    dynamic dropoffRaw = json['dropoffLocation'] ?? json['dropoff'] ?? json['receivedAddress'];

    if (pickupRaw == null && json['locations'] is List && (json['locations'] as List).isNotEmpty) {
      pickupRaw = (json['locations'] as List).first;
    }

    if (dropoffRaw == null && json['locations'] is List && (json['locations'] as List).length > 1) {
      dropoffRaw = (json['locations'] as List)[1];
    }

    final pickupMap = asMap(pickupRaw);
    final dropoffMap = asMap(dropoffRaw);
    final rideMode = json['rideMode']?.toString() ?? json['vehicleType']?.toString() ?? json['serviceType']?.toString();
    final fareValue = json['fareEstimation'] ?? json['fare'] ?? json['totalPrice'] ?? json['vehiclePrice'];
    final distanceValue = json['distanceKm'] ?? json['distance'];

    return RideModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      driverId: json['driverId']?.toString(),
      pickupLocation: LocationPoint.fromJson(pickupMap),
      dropoffLocation: LocationPoint.fromJson(dropoffMap),
      pickupAddress: extractAddress(json['pickupAddress'], pickupMap),
      dropoffAddress: extractAddress(json['dropoffAddress'] ?? json['receivedAddress'], dropoffMap),
      serviceType: rideMode ?? 'cab',
      status: json['status'] ?? 'pending',
      fareEstimation: parseDouble(fareValue),
      actualFare: parseDouble(json['actualFare'] ?? fareValue),
      distance: parseDistance(distanceValue),
      duration: parseDouble(json['duration']),
      otp: json['otp'],
      delayReason: json['delayReason'],
      isScheduled: json['isScheduled'] ?? false,
      scheduledTime: parseDate(json['scheduledTime']),
      vehicleType: json['vehicleType']?.toString() ?? rideMode,
      typeOfGood: json['typeOfGood'],
      createdAt: parseDate(json['createdAt']),
      segments: (json['segments'] as List?)?.map((s) => LogisticsSegment.fromJson(s)).toList() ?? [],
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
      'vehicleType': vehicleType,
      'typeOfGood': typeOfGood,
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
      case 'ongoing':
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
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final coordinates = json['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      return LocationPoint(
        type: json['type'] ?? 'Point',
        coordinates: coordinates
            .map((e) {
              if (e is num) return e.toDouble();
              if (e is String) return double.tryParse(e) ?? 0.0;
              return 0.0;
            })
            .toList(),
      );
    }

    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    if (lat != null && lng != null) {
      return LocationPoint(
        type: json['type'] ?? 'Point',
        coordinates: [parseDouble(lng), parseDouble(lat)],
      );
    }

    return LocationPoint(
      type: json['type'] ?? 'Point',
      coordinates: [0, 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}

class LogisticsSegment {
  final String id;
  final String mode;
  final String status;
  final String? transportName;
  final String? transportNumber;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;
  final String? otp;
  final double? price;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehicleNumber;
  final String? vehicleModel;

  LogisticsSegment({
    required this.id,
    required this.mode,
    required this.status,
    this.transportName,
    this.transportNumber,
    required this.start,
    required this.end,
    this.otp,
    this.price,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehicleNumber,
    this.vehicleModel,
  });

  factory LogisticsSegment.fromJson(Map<String, dynamic> json) {
    final driverData = json['driverId'];
    String? name;
    String? phone;
    String? photo;
    String? vNum;
    String? vModel;
    if (driverData is Map) {
      name = driverData['name']?.toString();
      phone = driverData['mobileNumber']?.toString();
      photo = driverData['photo']?.toString();
      vNum = driverData['vehicleNumberPlate']?.toString();
      vModel = driverData['vehicleModel']?.toString();
    }
    return LogisticsSegment(
      id: json['_id'] ?? json['id'] ?? '',
      mode: json['mode'] ?? 'Road',
      status: json['status'] ?? 'pending',
      transportName: json['transportName'],
      transportNumber: json['transportNumber'],
      start: json['start'] ?? {},
      end: json['end'] ?? {},
      otp: json['otp']?.toString(),
      price: json['price'] != null ? (double.tryParse(json['price'].toString()) ?? 0.0) : null,
      driverName: name,
      driverPhone: phone,
      driverPhoto: photo,
      vehicleNumber: vNum,
      vehicleModel: vModel,
    );
  }
}


