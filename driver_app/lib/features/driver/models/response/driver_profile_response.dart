import 'package:equatable/equatable.dart';

class DriverProfileResponseModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String drivingLicenseNumber;
  final String licenseUrl;
  final bool drivingLicenseVerified;
  final String aadharCardNumber;
  final String aadhaarUrl;
  final bool aadharVerified;
  final String panCardNumber;
  final String panUrl;
  final bool panVerified;
  final String signatureUrl;
  final String profilePic;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleNumberPlate;
  final String vehicleModel;
  final String vehicleYear;
  final double rating;
  final int totalRides;
  final bool onboardingComplete;
  final bool isEmailVerified;
  final bool isApproved;
  final String rcUrl;
  final String insuranceUrl;
  final String status;
  final String dob;
  final bool rcVerified;
  final bool insuranceVerified;
  final bool signatureVerified;

  const DriverProfileResponseModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.drivingLicenseNumber,
    required this.licenseUrl,
    required this.drivingLicenseVerified,
    required this.aadharCardNumber,
    required this.aadhaarUrl,
    required this.aadharVerified,
    required this.panCardNumber,
    required this.panUrl,
    required this.panVerified,
    required this.signatureUrl,
    required this.profilePic,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleNumberPlate,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.rating,
    required this.totalRides,
    required this.onboardingComplete,
    required this.isEmailVerified,
    required this.isApproved,
    this.rcUrl = '',
    this.insuranceUrl = '',
    this.status = 'pending',
    this.dob = '',
    this.rcVerified = false,
    this.insuranceVerified = false,
    this.signatureVerified = false,
  });

  factory DriverProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileResponseModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['mobileNumber'] ?? json['phone'] ?? json['phoneNumber'] ?? '',
      drivingLicenseNumber: json['drivingLicenseNumber'] ?? json['licenseNumber'] ?? '',
      licenseUrl: json['drivingLicense'] ?? json['licenseUrl'] ?? '',
      drivingLicenseVerified: json['drivingLicenseVerified'] ?? false,
      aadharCardNumber: json['aadharCardNumber'] ?? '',
      aadhaarUrl: json['aadharCard'] ?? json['aadhaarUrl'] ?? '',
      aadharVerified: json['aadharVerified'] ?? false,
      panCardNumber: json['panCardNumber'] ?? '',
      panUrl: json['panCardImage'] ?? json['panUrl'] ?? '',
      panVerified: json['panVerified'] ?? false,
      signatureUrl: json['signature'] ?? json['signatureUrl'] ?? '',
      profilePic: json['photo'] ?? json['profilePhoto'] ?? json['profilePic'] ?? '',
      vehicleType: json['vehicleType'] ?? 'cab',
      vehicleNumber: json['vehicleNumberPlate'] ?? json['vehicleNumber'] ?? '',
      vehicleNumberPlate: json['vehicleNumberPlate'] ?? json['vehicleNumber'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleYear: json['vehicleYear']?.toString() ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['totalTrips'] ?? json['totalRides'] ?? 0,
      onboardingComplete: json['onboardingComplete'] ?? json['isApproved'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isApproved: json['isApproved'] ?? false,
      rcUrl: json['rcBook'] ?? json['rcbook'] ?? json['rcUrl'] ?? '',
      insuranceUrl: json['insurance'] ?? json['insuranceUrl'] ?? '',
      status: json['status'] ?? 'pending',
      dob: json['dob'] != null ? json['dob'].toString() : '',
      rcVerified: json['rcVerified'] ?? false,
      insuranceVerified: json['insuranceVerified'] ?? false,
      signatureVerified: json['signatureVerified'] ?? false,
    );
  }

  factory DriverProfileResponseModel.fromModel(dynamic model) {
    // Assuming model is a DriverModel or Map
    return DriverProfileResponseModel(
      id: model.id ?? '',
      name: model.name ?? '',
      email: model.email ?? '',
      phoneNumber: model.phoneNumber ?? '',
      drivingLicenseNumber: model.drivingLicenseNumber ?? '',
      licenseUrl: model.licenseUrl ?? '',
      drivingLicenseVerified: model.drivingLicenseVerified ?? false,
      aadharCardNumber: model.aadharCardNumber ?? '',
      aadhaarUrl: model.aadhaarUrl ?? '',
      aadharVerified: model.aadharVerified ?? false,
      panCardNumber: model.panCardNumber ?? '',
      panUrl: model.panUrl ?? '',
      panVerified: model.panVerified ?? false,
      signatureUrl: model.signatureUrl ?? '',
      profilePic: model.profilePic ?? '',
      vehicleType: model.vehicleType ?? '',
      vehicleNumber: model.vehicleId ?? '',
      vehicleNumberPlate: model.vehicleNumberPlate ?? '',
      vehicleModel: model.vehicleModel ?? '',
      vehicleYear: model.vehicleYear ?? '',
      rating: (model.rating ?? 0.0).toDouble(),
      totalRides: model.totalRides ?? 0,
      onboardingComplete: model.onboardingComplete ?? false,
      isEmailVerified: model.isEmailVerified ?? false,
      isApproved: model.isApproved ?? false,
      rcUrl: model.rcUrl ?? '',
      insuranceUrl: model.insuranceUrl ?? '',
      dob: model.dob ?? '',
      rcVerified: model.rcVerified ?? false,
      insuranceVerified: model.insuranceVerified ?? false,
      signatureVerified: model.signatureVerified ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'phoneNumber': phoneNumber,
      'licenseNumber': drivingLicenseNumber,
      'drivingLicenseNumber': drivingLicenseNumber,
      'licenseUrl': licenseUrl,
      'drivingLicenseVerified': drivingLicenseVerified,
      'aadharCardNumber': aadharCardNumber,
      'aadhaarUrl': aadhaarUrl,
      'aadharVerified': aadharVerified,
      'panCardNumber': panCardNumber,
      'panUrl': panUrl,
      'panVerified': panVerified,
      'signatureUrl': signatureUrl,
      'profilePhoto': profilePic,
      'profilePic': profilePic,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehicleNumberPlate': vehicleNumberPlate,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'rating': rating,
      'totalTrips': totalRides,
      'totalRides': totalRides,
      'onboardingComplete': onboardingComplete,
      'isEmailVerified': isEmailVerified,
      'isApproved': isApproved,
      'rcBook': rcUrl,
      'insurance': insuranceUrl,
      'status': status,
      'dob': dob,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        drivingLicenseNumber,
        licenseUrl,
        drivingLicenseVerified,
        aadharCardNumber,
        aadhaarUrl,
        aadharVerified,
        panCardNumber,
        panUrl,
        panVerified,
        signatureUrl,
        profilePic,
        vehicleType,
        vehicleNumber,
        vehicleNumberPlate,
        vehicleModel,
        vehicleYear,
        rating,
        totalRides,
        onboardingComplete,
        isEmailVerified,
        isApproved,
        rcUrl,
        insuranceUrl,
        status,
        dob,
        rcVerified,
        insuranceVerified,
        signatureVerified,
      ];
}
