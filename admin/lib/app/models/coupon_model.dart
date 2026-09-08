// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  String? title;
  String? amount;
  String? code;
  bool? active;
  String? id;
  String? minAmount;
  Timestamp? expireAt;
  bool? isFix;
  bool? isPrivate;
  String? cmsId;
  String? cmsKey;

  CouponModel({this.title, this.amount, this.code, this.active, this.id, this.minAmount, this.expireAt, this.isFix, this.isPrivate, this.cmsId, this.cmsKey});

  CouponModel.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    amount = json['amount'] ?? '0.0';
    code = json['code'];
    active = json['active'];
    minAmount = json['minAmount'];
    id = json['id'];
    isPrivate = json['isPrivate'];
    if (json['expireAt'] != null) {
      if (json['expireAt'] is Timestamp) {
        expireAt = json['expireAt'];
      } else if (json['expireAt'] is String) {
        expireAt = Timestamp.fromDate(DateTime.parse(json['expireAt']));
      } else if (json['expireAt'] is Map) {
        final seconds = json['expireAt']['_seconds'] ?? json['expireAt']['seconds'];
        final nanoseconds = json['expireAt']['_nanoseconds'] ?? json['expireAt']['nanoseconds'] ?? 0;
        if (seconds != null) {
          expireAt = Timestamp(seconds, nanoseconds);
        }
      }
    }
    isFix = json['isFix'];
    cmsId = json['cmsId'];
    cmsKey = json['cmsKey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['amount'] = amount;
    data['code'] = code;
    data['minAmount'] = minAmount;
    data['active'] = active;
    data['id'] = id;
    data['isPrivate'] = isPrivate;
    data['expireAt'] = expireAt;
    data['isFix'] = isFix;
    data['cmsId'] = cmsId;
    data['cmsKey'] = cmsKey;
    return data;
  }
}
