import 'dart:convert';

// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:admin/app/models/admin_commission_model.dart';
import 'package:admin/app/models/coupon_model.dart';
import 'package:admin/app/models/distance_model.dart';
import 'package:admin/app/models/location_lat_lng.dart';
import 'package:admin/app/models/positions.dart';
import 'package:admin/app/models/vehicle_type_model.dart';
import 'tax_model.dart';

class BookingModel {
  String? id;
  Timestamp? createAt;
  Timestamp? updateAt;
  Timestamp? assignedAt;
  String? driverId;
  LocationLatLng? pickUpLocation;
  LocationLatLng? dropLocation;
  String? pickUpLocationAddress;
  String? dropLocationAddress;
  String? bookingStatus;
  String? customerId;
  String? customerName;
  String? paymentType;
  bool? paymentStatus;
  String? cancelledBy;
  String? discount;
  String? subTotal;
  String? taxTotal;
  Timestamp? bookingTime;
  Timestamp? pickupTime;
  Timestamp? dropTime;
  VehicleTypeModel? vehicleType;
  List<dynamic>? rejectedDriverId;
  String? otp;
  Positions? position;
  CouponModel? coupon;
  List<TaxModel>? taxList;
  AdminCommission? adminCommission;
  DistanceModel? distance;
  String? cancelledReason;
  String? type;
  String? roadmapStatus;
  List<dynamic>? segments;

  BookingModel({this.createAt,
    this.updateAt,
    this.assignedAt,
    this.driverId,
    this.bookingStatus,
    this.id,
    this.dropLocation,
    this.pickUpLocation,
    this.dropLocationAddress,
    this.pickUpLocationAddress,
    this.customerId,
    this.customerName,
    this.paymentType,
    this.paymentStatus,
    this.cancelledBy,
    this.discount,
    this.subTotal,
    this.taxTotal,
    this.bookingTime,
    this.pickupTime,
    this.dropTime,
    this.vehicleType,
    this.rejectedDriverId,
    this.otp,
    this.position,
    this.adminCommission,
    this.coupon,
    this.taxList,
    this.distance,
    this.cancelledReason,
    this.type,
    this.roadmapStatus,
    this.segments});

  @override
  String toString() {
    return 'BookingModel{id: $id, createAt: $createAt, updateAt: $updateAt,cancelledReason:$cancelledReason, driverId: $driverId, pickUpLocation: $pickUpLocation, dropLocation: $dropLocation, pickUpLocationAddress: $pickUpLocationAddress, dropLocationAddress: $dropLocationAddress, bookingStatus: $bookingStatus, customerId: $customerId, paymentType: $paymentType, paymentStatus: $paymentStatus, cancelledBy: $cancelledBy, discount: $discount, subTotal: $subTotal, taxTotal: $taxTotal, bookingTime: $bookingTime, pickupTime: $pickupTime, dropTime: $dropTime, vehicleType: $vehicleType, rejectedDriverId: $rejectedDriverId, otp: $otp, position: $position, coupon: $coupon, taxList: $taxList, adminCommission: $adminCommission, distance: $distance}';
  }

  factory BookingModel.fromRawJson(String str) => BookingModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  static Timestamp? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val;
    if (val is String) {
      DateTime? dt = DateTime.tryParse(val);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    if (val is int) {
      return Timestamp.fromMillisecondsSinceEpoch(val);
    }
    if (val is Map && val.containsKey('_seconds')) {
      return Timestamp(val['_seconds'], val['_nanoseconds'] ?? 0);
    }
    return null;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      BookingModel(
        createAt: _parseTimestamp(json["createAt"] ?? json["createdAt"]),
        updateAt: _parseTimestamp(json["updateAt"] ?? json["updatedAt"]),
        assignedAt: _parseTimestamp(json["assignedAt"]),
        driverId: json["driverId"] is Map ? json["driverId"]["_id"]?.toString() : json["driverId"]?.toString(),
        bookingStatus: json["bookingStatus"] ?? json["status"] ?? '',
        dropLocation: json['dropLocation'] != null ? LocationLatLng.fromJson(json['dropLocation']) : null,
        pickUpLocation: json['pickUpLocation'] != null ? LocationLatLng.fromJson(json['pickUpLocation']) : null,
        dropLocationAddress: json['dropLocationAddress'] ?? json['drop'] ?? json['dropoff']?.toString() ?? '',
        pickUpLocationAddress: json['pickUpLocationAddress'] ?? json['pickup'] ?? '',
        id: json["id"] ?? json["_id"] ?? json["bookingId"] ?? '',
        customerId: json["customerId"] is Map
            ? json["customerId"]["_id"]?.toString()
            : (json["userId"] is Map
                ? json["userId"]["_id"]?.toString()
                : json["customerId"]?.toString() ?? json["userId"]?.toString()),
        customerName: json["customerId"] is Map
            ? json["customerId"]["fullName"]?.toString()
            : (json["userId"] is Map
                ? json["userId"]["fullName"]?.toString()
                : null),
        paymentType: json["paymentType"] ?? json["paymentMethod"] ?? '',
        paymentStatus: json["paymentStatus"] is bool ? json["paymentStatus"] : (json["paymentStatus"] == 'completed' || json["paymentStatus"] == 'paid'),
        cancelledBy: json["cancelledBy"] ?? '',
        cancelledReason: json["cancelledReason"] ?? '',
        discount: json["discount"]?.toString(),
        subTotal: json["subTotal"]?.toString() ?? json["fare"]?.toString() ?? json["totalPrice"]?.toString() ?? json["amount"]?.toString(),
        taxTotal: json["taxTotal"]?.toString(),
        bookingTime: _parseTimestamp(json["bookingTime"]),
        pickupTime: _parseTimestamp(json["pickupTime"] ?? json["scheduledAt"]),
        dropTime: _parseTimestamp(json["dropTime"]),
        otp: json["otp"] ?? '',
        vehicleType: json["vehicleType"] == null ? null : (json["vehicleType"] is Map ? VehicleTypeModel.fromJson(json["vehicleType"]) : null),
        rejectedDriverId: json["rejectedDriverId"] == null ? [] : List<dynamic>.from(json["rejectedDriverId"]!.map((x) => x)),
        taxList: json["taxList"] == null ? [] : List<TaxModel>.from(json["taxList"]!.map((x) => TaxModel.fromJson(x))),
        position: json["position"] == null ? null : Positions.fromJson(json["position"]),
        coupon: json["coupon"] == null ? null : CouponModel.fromJson(json["coupon"]),
        adminCommission: json["adminCommission"] == null ? null : AdminCommission.fromJson(json["adminCommission"]),
        distance: json["distance"] == null ? null : (json["distance"] is Map ? DistanceModel.fromJson(json["distance"]) : DistanceModel(distance: json["distance"]?.toString())),
        type: json["type"]?.toString(),
        roadmapStatus: json["roadmapStatus"]?.toString(),
        segments: json["segments"] is List ? json["segments"] : null,
      );

  Map<String, dynamic> toJson() =>
      {
        "id": id,
        "createAt": createAt,
        "updateAt": updateAt,
        "assignedAt": assignedAt,
        "driverId": driverId,
        "bookingStatus": bookingStatus,
        "dropLocation": dropLocation?.toJson(),
        "pickUpLocation": pickUpLocation?.toJson(),
        "dropLocationAddress": dropLocationAddress,
        "pickUpLocationAddress": pickUpLocationAddress,
        "customerId": customerId,
        "paymentType": paymentType,
        "paymentStatus": paymentStatus,
        "cancelledBy": cancelledBy,
        "cancelledReason": cancelledReason,
        "discount": discount,
        "subTotal": subTotal,
        "taxTotal": taxTotal,
        "bookingTime": bookingTime,
        "pickupTime": pickupTime,
        "dropTime": dropTime,
        "vehicleType": vehicleType?.toJson(),
        "rejectedDriverId": rejectedDriverId == null ? [] : List<dynamic>.from(rejectedDriverId!.map((x) => x)),
        "taxList": taxList == null ? [] : (taxList!.map((x) => x.toJson()).toList()),
        "position": position?.toJson(),
        "coupon": coupon?.toJson(),
        "adminCommission": adminCommission?.toJson(),
        "distance": distance?.toJson(),
        "type": type,
      };
}
