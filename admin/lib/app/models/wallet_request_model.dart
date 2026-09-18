class WalletRequestModel {
  String? id;
  String? userType; // 'user' or 'driver'
  String? userId;
  String? driverId;
  String? userName;
  String? userPhone;
  String? userEmail;
  double? amount;
  String? paymentMethod;
  String? status; // 'pending', 'approved', 'rejected'
  String? transactionId;
  String? adminNote;
  String? profilePicture;
  DateTime? createdAt;
  DateTime? actionAt;

  WalletRequestModel({
    this.id,
    this.userType,
    this.userId,
    this.driverId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.amount,
    this.paymentMethod,
    this.status,
    this.transactionId,
    this.adminNote,
    this.profilePicture,
    this.createdAt,
    this.actionAt,
  });

  factory WalletRequestModel.fromJson(Map<String, dynamic> json) {
    String? resolvedProfilePic;
    if (json['userId'] is Map) {
      resolvedProfilePic = json['userId']['profilePicture'];
    } else if (json['driverId'] is Map) {
      resolvedProfilePic = json['driverId']['profilePicture'];
    }

    String? parseId(dynamic val) {
      if (val == null) return null;
      if (val is Map) return (val['_id'] ?? val['id'])?.toString();
      return val.toString();
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return WalletRequestModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      userType: json['userType']?.toString() ?? 'user',
      userId: parseId(json['userId']),
      driverId: parseId(json['driverId']),
      userName: json['userName']?.toString() ?? 'Unknown',
      userPhone: json['userPhone']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'upi',
      status: json['status']?.toString() ?? 'pending',
      transactionId: parseId(json['transactionId']),
      adminNote: json['adminNote']?.toString() ?? '',
      profilePicture: resolvedProfilePic,
      createdAt: parseDate(json['createdAt']),
      actionAt: parseDate(json['actionAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userType': userType,
      'userId': userId,
      'driverId': driverId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionId': transactionId,
      'adminNote': adminNote,
      'createdAt': createdAt?.toIso8601String(),
      'actionAt': actionAt?.toIso8601String(),
    };
  }
}

class WalletRequestStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final double pendingAmount;
  final double approvedAmount;

  WalletRequestStats({
    this.total = 0,
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.pendingAmount = 0.0,
    this.approvedAmount = 0.0,
  });

  factory WalletRequestStats.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return WalletRequestStats(
      total: toInt(json['total']),
      pending: toInt(json['pending']),
      approved: toInt(json['approved']),
      rejected: toInt(json['rejected']),
      pendingAmount: toDouble(json['pendingAmount']),
      approvedAmount: toDouble(json['approvedAmount']),
    );
  }
}
