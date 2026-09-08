import 'dart:convert';

import 'package:admin/app/models/admin_commission_model.dart';
import 'package:admin/app/models/location_lat_lng.dart';
import 'package:admin/app/models/positions.dart';
import 'package:admin/app/models/subscription_model.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverUserModel {
  String? fullName;
  String? slug;
  String? id;
  String? email;
  String? loginType;
  String? profilePic;
  String? dateOfBirth;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  String? walletAmount;
  String? gender;
  bool? isActive;
  bool? isVerified;
  bool? isOnline;
  Timestamp? createdAt;
  DriverVehicleDetails? driverVehicleDetails;
  LocationLatLng? location;
  Positions? position;
  double? rotation;
  String? reviewsCount;
  String? reviewsSum;
  AdminCommission? adminCommission;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  String? subscriptionTotalBookings;
  SubscriptionModel? subscriptionPlan;
  String? status;
  String? bookingId;
  String? aadharCard;
  String? drivingLicense;
  String? aadharCardNumber;
  String? drivingLicenseNumber;
  String? panCardNumber;
  String? vehicleNumberPlate;
  String? vehicleModel;
  String? signature;
  String? vehicleYear;
  bool? panVerified;
  bool? aadharVerified;
  bool? drivingLicenseVerified;
  String? panCardImage;
  String? rcBook;
  String? insurance;

  DriverUserModel({
    this.fullName,
    this.slug,
    this.driverVehicleDetails,
    this.location,
    this.position,
    this.id,
    this.isActive,
    this.isVerified,
    this.isOnline,
    this.dateOfBirth,
    this.email,
    this.loginType,
    this.profilePic,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.walletAmount,
    this.createdAt,
    this.rotation,
    this.gender,
    this.reviewsCount,
    this.reviewsSum,
    this.adminCommission,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionTotalBookings,
    this.subscriptionPlan,
    this.status,
    this.bookingId,
    this.aadharCard,
    this.drivingLicense,
    this.aadharCardNumber,
    this.drivingLicenseNumber,
    this.panCardNumber,
    this.vehicleNumberPlate,
    this.vehicleModel,
    this.signature,
    this.vehicleYear,
    this.panVerified,
    this.aadharVerified,
    this.drivingLicenseVerified,
    this.panCardImage,
    this.rcBook,
    this.insurance,
  });

  DriverUserModel.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'] ?? json['name'];
    slug = json['slug'];
    id = json['id'] ?? json['_id'];
    email = json['email'];
    loginType = json['loginType'];
    profilePic = json['profilePic'] ?? json['photo'];
    fcmToken = json['fcmToken'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'] ?? json['mobileNumber'] ?? "";
    walletAmount = (json['walletAmount'] ?? json['walletBalance'] ?? "0").toString();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        try {
          createdAt = Timestamp.fromDate(DateTime.parse(json['createdAt']));
        } catch (_) {}
      } else if (json['createdAt'] is Timestamp) {
        createdAt = json['createdAt'];
      } else if (json['createdAt'] is Map) {
        createdAt = Timestamp(json['createdAt']['_seconds'] ?? 0, json['createdAt']['_nanoseconds'] ?? 0);
      }
    }
    gender = json['gender'];
    dateOfBirth = json['dateOfBirth'] ?? json['dob']?.toString() ?? '';
    isActive = json['isActive'];
    isOnline = json['isOnline'];
    driverVehicleDetails = json['driverVehicleDetails'] != null ? DriverVehicleDetails.fromJson(json["driverVehicleDetails"]) : null;
    isVerified = json['isVerified'] ?? json['isApproved'];
    location = json['location'] != null ? LocationLatLng.fromJson(json['location']) : LocationLatLng();
    position = json['position'] != null ? Positions.fromJson(json['position']) : Positions();
    rotation = json['rotation'] != null ? double.tryParse(json['rotation'].toString()) : null;
    reviewsCount = json['reviewsCount'];
    reviewsSum = json['reviewsSum'];
    adminCommission = json['adminCommission'] != null ? AdminCommission.fromJson(json['adminCommission']) : AdminCommission();
    subscriptionPlanId = json['subscriptionPlanId'];
    if (json['subscriptionExpiryDate'] != null) {
      if (json['subscriptionExpiryDate'] is String) {
        try {
          subscriptionExpiryDate = Timestamp.fromDate(DateTime.parse(json['subscriptionExpiryDate']));
        } catch (_) {}
      } else if (json['subscriptionExpiryDate'] is Timestamp) {
        subscriptionExpiryDate = json['subscriptionExpiryDate'];
      } else if (json['subscriptionExpiryDate'] is Map) {
        subscriptionExpiryDate = Timestamp(json['subscriptionExpiryDate']['_seconds'] ?? 0, json['subscriptionExpiryDate']['_nanoseconds'] ?? 0);
      }
    }
    subscriptionTotalBookings = json['subscriptionTotalBookings'];
    subscriptionPlan = json['subscriptionPlan'] != null ? SubscriptionModel.fromJson(json['subscriptionPlan']) : SubscriptionModel();
    status = json['status'];
    bookingId = json['bookingId'];
    
    // Mapped backend fields
    aadharCard = json['aadharCard'];
    drivingLicense = json['drivingLicense'];
    aadharCardNumber = json['aadharCardNumber'];
    drivingLicenseNumber = json['drivingLicenseNumber'];
    panCardNumber = json['panCardNumber'];
    vehicleNumberPlate = json['vehicleNumberPlate'];
    vehicleModel = json['vehicleModel'];
    signature = json['signature'];
    vehicleYear = json['vehicleYear'];
    panVerified = json['panVerified'];
    aadharVerified = json['aadharVerified'];
    drivingLicenseVerified = json['drivingLicenseVerified'];
    panCardImage = json['panCardImage'];
    rcBook = json['rcBook'];
    insurance = json['insurance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fullName'] = fullName;
    data['slug'] = slug;
    data['id'] = id;
    data['email'] = email;
    data['loginType'] = loginType;
    data['profilePic'] = profilePic;
    data['fcmToken'] = fcmToken;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['walletAmount'] = walletAmount;
    data['createdAt'] = createdAt;
    data['gender'] = gender;
    data['dateOfBirth'] = dateOfBirth;
    data['isActive'] = isActive;
    data['isOnline'] = isOnline;
    data['isVerified'] = isVerified;
    data["driverVehicleDetails"] = driverVehicleDetails == null ? DriverVehicleDetails().toJson() : driverVehicleDetails!.toJson();
    if (location != null) {
      data['location'] = location!.toJson();
    }
    if (position != null) {
      data['position'] = position!.toJson();
    }
    data['rotation'] = rotation;
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscriptionTotalBookings'] = subscriptionTotalBookings;
    if (subscriptionPlan != null) {
      data['subscriptionPlan'] = subscriptionPlan!.toJson();
    }
    data['status'] = status;
    data['bookingId'] = bookingId;
    
    data['aadharCard'] = aadharCard;
    data['drivingLicense'] = drivingLicense;
    data['aadharCardNumber'] = aadharCardNumber;
    data['drivingLicenseNumber'] = drivingLicenseNumber;
    data['panCardNumber'] = panCardNumber;
    data['vehicleNumberPlate'] = vehicleNumberPlate;
    data['vehicleModel'] = vehicleModel;
    data['signature'] = signature;
    data['vehicleYear'] = vehicleYear;
    data['panVerified'] = panVerified;
    data['aadharVerified'] = aadharVerified;
    data['drivingLicenseVerified'] = drivingLicenseVerified;
    data['panCardImage'] = panCardImage;
    data['rcBook'] = rcBook;
    data['insurance'] = insurance;
    return data;
  }
}

class DriverVehicleDetails {
  String? vehicleTypeName;
  String? vehicleTypeId;
  String? brandName;
  String? brandId;
  String? modelName;
  String? modelId;
  String? vehicleNumber;
  bool? isVerified;

  DriverVehicleDetails({
    this.vehicleTypeName,
    this.vehicleTypeId,
    this.brandName,
    this.brandId,
    this.modelName,
    this.modelId,
    this.vehicleNumber,
    this.isVerified,
  });

  factory DriverVehicleDetails.fromRawJson(String str) => DriverVehicleDetails.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DriverVehicleDetails.fromJson(Map<String, dynamic> json) => DriverVehicleDetails(
        vehicleTypeName: json["vehicleTypeName"],
        vehicleTypeId: json["vehicleTypeId"],
        brandName: json["brandName"],
        brandId: json["brandId"],
        modelName: json["modelName"],
        modelId: json["modelId"],
        vehicleNumber: json["vehicleNumber"],
        isVerified: json["isVerified"],
      );

  Map<String, dynamic> toJson() => {
        "vehicleTypeName": vehicleTypeName ?? '',
        "vehicleTypeId": vehicleTypeId ?? '',
        "brandName": brandName ?? '',
        "brandId": brandId ?? '',
        "modelName": modelName ?? '',
        "modelId": modelId ?? '',
        "vehicleNumber": vehicleNumber ?? '',
        "isVerified": isVerified ?? false,
      };
}
