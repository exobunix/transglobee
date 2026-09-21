
class BookingModel {
  final String id;
  final String userName;
  final String userPhone;
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final double distanceKm;
  final int etaMinutes;
  final String vehicleType;
  final String subType;
  /// CAB | LOGISTICS | SHUTTLE — from socket / API `type` or `bookingCategory`
  final String dispatchType;
  final String status; // pending, accepted, on_the_way, arrived, started, completed, cancelled
  final DateTime createdAt;
  final String? otp;
  final double? userRating;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? userId;
  final double? actualFare;
  final String paymentStatus; // unpaid, paid
  final String? railwayStation;
  final Map<String, dynamic>? pickupDetails;
  final Map<String, dynamic>? dropDetails;
  final List<dynamic>? items;
  final double? vehiclePrice;
  final double? helperCost;
  final double? discountAmount;
  final String? transportName;
  final String? transportNumber;
  final String? estimatedTime;
  final String? estimatedDate;
  final List<BookingSegment> segments;

  const BookingModel({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fare,
    required this.distanceKm,
    required this.etaMinutes,
    required this.vehicleType,
    required this.subType,
    this.dispatchType = 'CAB',
    required this.status,
    required this.createdAt,
    this.otp,
    this.userRating,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.actualFare,
    this.userId,
    this.paymentStatus = 'unpaid',
    this.railwayStation,
    this.pickupDetails,
    this.dropDetails,
    this.items,
    this.vehiclePrice,
    this.helperCost,
    this.discountAmount,
    this.transportName,
    this.transportNumber,
    this.estimatedTime,
    this.estimatedDate,
    this.segments = const [],
  });

  BookingModel copyWith({
    String? status,
    double? actualFare,
    String? userId,
    double? fare,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? otp,
    String? paymentStatus,
    String? railwayStation,
    List<dynamic>? items,
    double? vehiclePrice,
    double? helperCost,
    double? discountAmount,
    String? estimatedTime,
    String? estimatedDate,
  }) =>
      BookingModel(
        id: id,
        userName: userName,
        userPhone: userPhone,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        fare: fare ?? this.fare,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
        vehicleType: vehicleType,
        subType: subType,
        status: status ?? this.status,
        createdAt: createdAt,
        otp: otp ?? this.otp,
        userRating: userRating,
        pickupLat: pickupLat ?? this.pickupLat,
        pickupLng: pickupLng ?? this.pickupLng,
        dropLat: dropLat ?? this.dropLat,
        dropLng: dropLng ?? this.dropLng,
        actualFare: actualFare ?? this.actualFare,
        userId: userId ?? this.userId,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        railwayStation: railwayStation ?? this.railwayStation,
        items: items ?? this.items,
        vehiclePrice: vehiclePrice ?? this.vehiclePrice,
        helperCost: helperCost ?? this.helperCost,
        discountAmount: discountAmount ?? this.discountAmount,
        estimatedTime: estimatedTime ?? this.estimatedTime,
        estimatedDate: estimatedDate ?? this.estimatedDate,
        segments: segments,
      );

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    double? parseOptionalDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    final mode = json['rideMode']?.toString() ??
        json['modeOfTravel']?.toString() ??
        json['vehicleType']?.toString();

    String resolveDispatchType() {
      final raw = (json['type'] ?? json['bookingCategory'] ?? json['displayType'] ?? '')
          .toString()
          .toUpperCase();
      if (raw == 'CAB' || raw == 'RETAIL' || raw == 'RIDE') return 'CAB';
      if (raw == 'SHUTTLE' || raw.contains('BUS')) return 'SHUTTLE';
      if (raw == 'LOGISTICS' || raw.contains('LOGISTIC')) return 'LOGISTICS';
      if (json['locations'] is List && json['rideMode'] != null) return 'CAB';
      if (json['items'] is List && (json['items'] as List).isNotEmpty) {
        final m = mode?.toLowerCase() ?? '';
        final isBus = ['mini_bus', 'standard', 'luxury', 'sleeper', 'bus', 'shuttle'].contains(m);
        return isBus ? 'SHUTTLE' : 'LOGISTICS';
      }
      return 'CAB';
    }

    final dispatchType = resolveDispatchType();

    String deriveVehicleType(String? rideMode, String dispatchType) {
      if (rideMode == null) {
        if (dispatchType == 'LOGISTICS') return 'truck';
        if (dispatchType == 'SHUTTLE') return 'bus';
        return 'cab';
      }
      final m = rideMode.toLowerCase();
      if (['pickup', 'mini_truck', 'container', 'flatbed', 'ace', 'pickup8ft', '3wheeler', 'truck', 'train', 'flight', 'ship', 'cargo', 'logistics', 'sea', 'sea cargo'].contains(m)) {
        return 'truck';
      }
      if (['mini_bus', 'standard', 'luxury', 'sleeper', 'bus', 'shuttle'].contains(m)) {
        return 'bus';
      }
      if (dispatchType == 'LOGISTICS') return 'truck';
      if (dispatchType == 'SHUTTLE') return 'bus';
      return 'cab';
    }

    String mapStatus(String? s) {
      if (s == null) return 'pending';
      switch (s.toLowerCase()) {
        case 'confirmed': return 'accepted';
        case 'pending_for_driver': return 'pending_for_driver'; // keep as-is for filter
        case 'processing': return 'pending';
        case 'in_transit': return 'ongoing';
        case 'delivered': return 'completed';
        default: return s;
      }
    }

    // Support both nested {address,latitude,longitude} objects (from DB)
    // and flat strings (from socket events)
    String resolveAddress(dynamic nested, String flatFallback) {
      if (nested is Map) return nested['address']?.toString() ?? '';
      if (nested is String) return nested;
      return json[flatFallback]?.toString() ?? '';
    }
    double? resolveLatFromObj(dynamic nested, String flatKey) {
      if (nested is Map) return parseOptionalDouble(nested['latitude'] ?? nested['lat']);
      return parseOptionalDouble(json[flatKey]);
    }
    double? resolveLngFromObj(dynamic nested, String flatKey) {
      if (nested is Map) return parseOptionalDouble(nested['longitude'] ?? nested['lng']);
      return parseOptionalDouble(json[flatKey]);
    }

    final pickupRaw = json['pickup'] ??
        json['pickupAddress'] ??
        json['pickupLocation'] ??
        (json['locations'] is List && (json['locations'] as List).isNotEmpty ? json['locations'][0] : null);
    final dropRaw = json['dropoff'] ??
        json['dropAddress'] ??
        json['dropLocation'] ??
        json['receivedAddress'] ??
        (json['locations'] is List && (json['locations'] as List).length > 1 ? json['locations'][1] : null);

    final String resolvedUserName = json['userName']?.toString() ??
        json['name']?.toString() ??
        (json['user'] is Map ? json['user']['name']?.toString() : null) ??
        (json['userId'] is Map ? json['userId']['name']?.toString() : null) ??
        'Guest User';

    final String resolvedUserPhone = json['userPhone']?.toString() ??
        json['phone']?.toString() ??
        json['mobileNumber']?.toString() ??
        (json['user'] is Map ? (json['user']['mobileNumber'] ?? json['user']['phone'])?.toString() : null) ??
        (json['userId'] is Map ? (json['userId']['mobileNumber'] ?? json['userId']['phone'])?.toString() : null) ??
        '';

    return BookingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userName: resolvedUserName,
      userPhone: resolvedUserPhone,
      pickupAddress: resolveAddress(pickupRaw, 'pick'),
      dropAddress:   resolveAddress(dropRaw, 'drop'),
      fare: parseDouble(json['totalPrice'] ?? json['fare'] ?? json['vehiclePrice'] ?? 0),
      distanceKm: (json['distanceKm'] != null)
          ? parseDouble(json['distanceKm'])
          : parseDouble(json['distance']?.toString().replaceAll(' km', '')),
      etaMinutes: parseInt(json['etaMinutes'], 10),
      vehicleType: deriveVehicleType(mode, dispatchType),
      subType: mode?.toUpperCase() ?? dispatchType,
      dispatchType: dispatchType,
      status: mapStatus(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      otp: json['otp']?.toString(),
      actualFare: parseOptionalDouble(json['actualFare']),
      pickupLat: resolveLatFromObj(pickupRaw, 'pickupLat'),
      pickupLng: resolveLngFromObj(pickupRaw, 'pickupLng'),
      dropLat: resolveLatFromObj(dropRaw, 'dropLat'),
      dropLng: resolveLngFromObj(dropRaw, 'dropLng'),
      userId: json['userId']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      railwayStation: json['railwayStation']?.toString() ?? json['transitPoint']?.toString(),
      pickupDetails: pickupRaw is Map ? Map<String, dynamic>.from(pickupRaw) : null,
      dropDetails:   dropRaw is Map   ? Map<String, dynamic>.from(dropRaw)   : null,
      items: json['items'] is List ? List<dynamic>.from(json['items']) : null,
      vehiclePrice: parseOptionalDouble(json['vehiclePrice'] ?? json['baseFare']),
      helperCost: parseOptionalDouble(json['helperCost']),
      discountAmount: parseOptionalDouble(json['discountAmount']),
      transportName: json['transportName']?.toString(),
      transportNumber: json['transportNumber']?.toString(),
      estimatedTime: json['estimatedTime']?.toString(),
      estimatedDate: json['estimatedDate']?.toString(),
      segments: (json['segments'] as List?)?.map((s) => BookingSegment.fromJson(s)).toList() ?? [],
    );
  }

  /// Map for live ride-request popup (socket + polling).
  Map<String, dynamic> toRideRequestMap() {
    return {
      'id': id,
      'userName': userName,
      'phone': userPhone,
      'pick': pickupAddress,
      'drop': dropAddress,
      'fare': fare,
      'distance': distanceKm > 0 ? '${distanceKm.toStringAsFixed(1)} km' : '—',
      'rideMode': subType,
      'vehicleType': vehicleType,
      'type': dispatchType,
      'bookingCategory': dispatchType.toLowerCase(),
      'status': status,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'userId': userId,
      'otp': otp,
      'transportName': transportName,
      'transportNumber': transportNumber,
      'estimatedTime': estimatedTime,
      'estimatedDate': estimatedDate,
    };
  }

  /// Returns driver-specific fare for LOGISTICS if driver is assigned to a segment
  double getFareForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return segment.price;
        }
      }
    }
    return fare;
  }

  /// Returns driver-specific pickup address for LOGISTICS if driver is assigned to a segment
  String getPickupAddressForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return segment.start['address'] ?? segment.start['name'] ?? pickupAddress;
        }
      }
    }
    return pickupAddress;
  }

  /// Returns driver-specific drop address for LOGISTICS if driver is assigned to a segment
  String getDropAddressForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return segment.end['address'] ?? segment.end['name'] ?? dropAddress;
        }
      }
    }
    return dropAddress;
  }

  /// Returns driver-specific distance for LOGISTICS if driver is assigned to a segment
  double getDistanceForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return segment.distanceKm;
        }
      }
    }
    return distanceKm;
  }

  /// Returns driver-specific pickup lat for LOGISTICS
  double? getPickupLatForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return (segment.start['lat'] ?? segment.start['latitude'])?.toDouble() ?? pickupLat;
        }
      }
    }
    return pickupLat;
  }

  /// Returns driver-specific pickup lng for LOGISTICS
  double? getPickupLngForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return (segment.start['lng'] ?? segment.start['longitude'])?.toDouble() ?? pickupLng;
        }
      }
    }
    return pickupLng;
  }

  /// Returns driver-specific drop lat for LOGISTICS
  double? getDropLatForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return (segment.end['lat'] ?? segment.end['latitude'])?.toDouble() ?? dropLat;
        }
      }
    }
    return dropLat;
  }

  /// Returns driver-specific drop lng for LOGISTICS
  double? getDropLngForDriver(String? driverId, [String? altDriverId]) {
    if (dispatchType == 'LOGISTICS' && (driverId != null || altDriverId != null) && segments.isNotEmpty) {
      for (final segment in segments) {
        if (segment.driverId == driverId || (altDriverId != null && segment.driverId == altDriverId)) {
          return (segment.end['lng'] ?? segment.end['longitude'])?.toDouble() ?? dropLng;
        }
      }
    }
    return dropLng;
  }
}

class BookingSegment {
  final String id;
  final String mode;
  final String status;
  final String? transportName;
  final String? transportNumber;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;
  final String? driverId;
  final String? otp;
  final double price;
  final double distanceKm;

  BookingSegment({
    required this.id,
    required this.mode,
    required this.status,
    this.transportName,
    this.transportNumber,
    required this.start,
    required this.end,
    this.driverId,
    this.otp,
    required this.price,
    required this.distanceKm,
  });

  factory BookingSegment.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return BookingSegment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'Road',
      status: json['status']?.toString() ?? 'pending',
      transportName: json['transportName']?.toString(),
      transportNumber: json['transportNumber']?.toString(),
      start: json['start'] ?? {},
      end: json['end'] ?? {},
      driverId: json['driverId'] is Map 
          ? (json['driverId']['_id']?.toString() ?? json['driverId']['id']?.toString()) 
          : json['driverId']?.toString(),
      otp: json['otp']?.toString(),
      price: parseDouble(json['price']),
      distanceKm: parseDouble(json['distanceKm']),
    );
  }
}
