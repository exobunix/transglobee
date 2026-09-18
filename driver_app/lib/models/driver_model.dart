class DriverModel {
  final String id;
  final String firebaseId;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profilePic;
  final String vehicleId;
  final bool isOnline;
  final String status;
  final DriverLocation? location;
  final double rating;
  final int totalRides;
  final List<String> documents;
  final String? dob;
  final String? aadhaarUrl;
  final String? licenseUrl;
  final String? panUrl;
  final String? rcUrl;
  final String? signatureUrl;
  final String? insuranceUrl;
  final String? aadharCardNumber;
  final String? drivingLicenseNumber;
  final String? panCardNumber;
  final bool panVerified;
  final bool aadharVerified;
  final bool drivingLicenseVerified;
  final bool onboardingComplete;
  final bool isEmailVerified;
  final bool rcVerified;
  final bool insuranceVerified;
  final bool signatureVerified;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? vehicleNumberPlate;
  final String? vehicleType;
  final bool isApproved;

  DriverModel({
    required this.id,
    required this.firebaseId,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profilePic,
    required this.vehicleId,
    this.isOnline = false,
    this.status = 'offline',
    this.location,
    this.rating = 0,
    this.totalRides = 0,
    this.documents = const [],
    this.dob,
    this.aadhaarUrl,
    this.licenseUrl,
    this.panUrl,
    this.rcUrl,
    this.signatureUrl,
    this.insuranceUrl,
    this.aadharCardNumber,
    this.drivingLicenseNumber,
    this.panCardNumber,
    this.onboardingComplete = false,
    this.isEmailVerified = false,
    this.panVerified = false,
    this.aadharVerified = false,
    this.drivingLicenseVerified = false,
    this.rcVerified = false,
    this.insuranceVerified = false,
    this.signatureVerified = false,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleNumberPlate,
    this.vehicleType,
    this.isApproved = false,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final String normalizedStatus =
        (json['status']?.toString().trim().toLowerCase() ?? 'offline');
    final bool approvedFromStatus = {
      'active',
      'available',
      'approved',
      'verified',
      'online',
    }.contains(normalizedStatus);
    final bool approvedFromFlag = json['isApproved'] == true;

    return DriverModel(
      id: json['_id'] ?? '',
      firebaseId: json['uid'] ?? json['firebaseId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'],
      phoneNumber: json['mobileNumber'] ?? json['phonenumber'] ?? json['phoneNumber'],
      profilePic: json['photo'] ?? json['profilePic'],
      vehicleId: json['vehicleId'] ?? '',
      isOnline: json['isOnline'] ?? false,
      status: normalizedStatus,
      location: json['location'] != null
          ? DriverLocation.fromJson(json['location'])
          : null,
      rating: parseDouble(json['rating']),
      totalRides: json['totalRides'] ?? 0,
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dob: json['dob']?.toString(),
      aadhaarUrl: json['aadharCard'] ?? json['adharcard'] ?? json['aadhaarUrl'],
      licenseUrl: json['drivingLicense'] ?? json['drivinglicence'] ?? json['licenseUrl'],
      panUrl: json['panCardImage'] ?? json['panUrl'] ?? json['pancard'] ?? '',
      rcUrl: json['rcBook'] ?? json['rcUrl'] ?? json['rcbook'] ?? '',
      insuranceUrl: json['insurance'] ?? json['insuranceUrl'] ?? '',
      signatureUrl: json['signature'] ?? json['signatureUrl'],
      aadharCardNumber: json['aadharCardNumber'],
      drivingLicenseNumber: json['drivingLicenseNumber'],
      panCardNumber: json['panCardNumber'],
      onboardingComplete: json['onboardingComplete'] ??
          (approvedFromStatus ||
              (json['photo'] != null &&
                  json['aadharCard'] != null &&
                  json['drivingLicense'] != null)),
      isEmailVerified: json['isEmailVerified'] ?? false,
      panVerified: json['panVerified'] ?? false,
      aadharVerified: json['aadharVerified'] ?? false,
      drivingLicenseVerified: json['drivingLicenseVerified'] ?? false,
      rcVerified: json['rcVerified'] ?? false,
      insuranceVerified: json['insuranceVerified'] ?? false,
      signatureVerified: json['signatureVerified'] ?? false,
      vehicleModel: json['vehicleModel'],
      vehicleYear: json['vehicleYear'],
      vehicleNumberPlate: json['vehicleNumberPlate'] ?? json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? json['driverVehicleDetails']?['vehicleTypeName'],
      isApproved: approvedFromFlag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'uid': firebaseId,
      'firebaseId': firebaseId,
      'email': email,
      'name': name,
      'username': name,
      'mobileNumber': phoneNumber,
      'phonenumber': phoneNumber,
      'phoneNumber': phoneNumber,
      'photo': profilePic,
      'profilePic': profilePic,
      'vehicleId': vehicleId,
      'isOnline': isOnline,
      'status': status,
      'location': location?.toJson(),
      'rating': rating,
      'totalRides': totalRides,
      'documents': documents,
      'dob': dob,
      'aadharCard': aadhaarUrl,
      'adharcard': aadhaarUrl,
      'aadhaarUrl': aadhaarUrl,
      'drivingLicense': licenseUrl,
      'licenseUrl': licenseUrl,
      'panCardImage': panUrl,
      'panUrl': panUrl,
      'rcBook': rcUrl,
      'rcUrl': rcUrl,
      'signature': signatureUrl,
      'signatureUrl': signatureUrl,
      'insurance': insuranceUrl,
      'insuranceUrl': insuranceUrl,
      'aadharCardNumber': aadharCardNumber,
      'drivingLicenseNumber': drivingLicenseNumber,
      'panCardNumber': panCardNumber,
      'onboardingComplete': onboardingComplete,
      'isEmailVerified': isEmailVerified,
      'panVerified': panVerified,
      'aadharVerified': aadharVerified,
      'drivingLicenseVerified': drivingLicenseVerified,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleNumberPlate': vehicleNumberPlate,
      'vehicleType': vehicleType,
      'isApproved': isApproved,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'Online - Available';
      case 'busy':
        return 'On a Ride';
      case 'offline':
        return 'Offline';
      default:
        return status;
    }
  }
}

class DriverLocation {
  final String type;
  final List<double> coordinates;

  DriverLocation({this.type = 'Point', required this.coordinates});

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
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
