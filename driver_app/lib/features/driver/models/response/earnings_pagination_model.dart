import 'package:equatable/equatable.dart';

double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? defaultVal;
  }
  return defaultVal;
}

int _toInt(dynamic val, [int defaultVal = 0]) {
  if (val == null) return defaultVal;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? defaultVal;
  }
  return defaultVal;
}

class EarningsRecordModel extends Equatable {
  final String bookingId;
  final double amount;
  final String date;
  final double tripDistance;
  final String status;
  final String userName;
  final String vehicleType;

  const EarningsRecordModel({
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.tripDistance,
    required this.status,
    this.userName = 'Customer',
    this.vehicleType = 'Ride',
  });

  factory EarningsRecordModel.fromJson(Map<String, dynamic> json) {
    return EarningsRecordModel(
      bookingId: json['bookingId']?.toString() ?? json['id']?.toString() ?? '',
      amount: _toDouble(json['amount'] ?? json['driverEarnings'] ?? json['fare']),
      date: json['date']?.toString() ?? json['completedAt']?.toString() ?? json['createdAt']?.toString() ?? '',
      tripDistance: _toDouble(json['tripDistance'] ?? json['distance']),
      status: json['status']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Customer',
      vehicleType: json['vehicleType']?.toString() ?? json['rideMode'] ?? 'Ride',
    );
  }

  @override
  List<Object?> get props =>
      [bookingId, amount, date, tripDistance, status, userName, vehicleType];
}

class DailyEarningModel extends Equatable {
  final String label;
  final double earnings;

  const DailyEarningModel({required this.label, required this.earnings});

  factory DailyEarningModel.fromJson(Map<String, dynamic> json) {
    return DailyEarningModel(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      earnings: _toDouble(json['earnings'] ?? json['totalIncome'] ?? json['amount']),
    );
  }

  @override
  List<Object?> get props => [label, earnings];
}

class EarningsPaginationModel extends Equatable {
  final double totalEarnings;
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int page;
  final int limit;
  final List<EarningsRecordModel> records;
  final List<DailyEarningModel> dailyBreakdown;
  final int weeklyCompletedRides;
  final int bonusTarget;
  final double bonusAmount;

  const EarningsPaginationModel({
    required this.totalEarnings,
    this.todayEarnings = 0,
    this.weeklyEarnings = 0,
    this.monthlyEarnings = 0,
    required this.page,
    required this.limit,
    required this.records,
    this.dailyBreakdown = const [],
    this.weeklyCompletedRides = 0,
    this.bonusTarget = 15,
    this.bonusAmount = 1000,
  });

  factory EarningsPaginationModel.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] ??
        json['recentTrips'] ??
        json['recentTransactions'] ??
        json['completedBookings'] ??
        json['bookings'] ??
        [];
    final list = rawRecords is List ? rawRecords : [];
    final recordsList = list
        .whereType<Map>()
        .map((i) => EarningsRecordModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    final rawDaily = json['dailyBreakdown'] as List? ?? [];
    final dailyList = rawDaily
        .whereType<Map>()
        .map((i) => DailyEarningModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    return EarningsPaginationModel(
      totalEarnings: _toDouble(json['totalEarnings']),
      todayEarnings: _toDouble(json['todayEarnings']),
      weeklyEarnings: _toDouble(json['weeklyEarnings']),
      monthlyEarnings: _toDouble(json['monthlyEarnings']),
      page: _toInt(json['page'], 1),
      limit: _toInt(json['limit'], 20),
      records: recordsList,
      dailyBreakdown: dailyList,
      weeklyCompletedRides: _toInt(json['weeklyCompletedRides']),
      bonusTarget: _toInt(json['bonusTarget'], 15),
      bonusAmount: _toDouble(json['bonusAmount'], 1000),
    );
  }

  double earningsForPeriod(String period) {
    switch (period) {
      case 'Today':
        return todayEarnings;
      case 'Week':
        return weeklyEarnings;
      case 'Month':
        return monthlyEarnings;
      default:
        return todayEarnings;
    }
  }

  @override
  List<Object?> get props => [
        totalEarnings,
        todayEarnings,
        weeklyEarnings,
        monthlyEarnings,
        page,
        limit,
        records,
        dailyBreakdown,
        weeklyCompletedRides,
        bonusTarget,
        bonusAmount,
      ];
}
