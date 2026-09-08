import 'package:equatable/equatable.dart';

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
      bookingId: json['bookingId']?.toString() ?? '',
      amount: (json['amount'] ?? json['driverEarnings'] ?? 0.0).toDouble(),
      date: json['date']?.toString() ?? '',
      tripDistance: (json['tripDistance'] ?? 0.0).toDouble(),
      status: json['status']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Customer',
      vehicleType: json['vehicleType']?.toString() ?? 'Ride',
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
      label: json['label']?.toString() ?? '',
      earnings: (json['earnings'] ?? 0.0).toDouble(),
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
        [];
    final list = rawRecords is List ? rawRecords : [];
    final recordsList =
        list.map((i) => EarningsRecordModel.fromJson(Map<String, dynamic>.from(i as Map))).toList();

    final rawDaily = json['dailyBreakdown'] as List? ?? [];
    final dailyList = rawDaily
        .map((i) => DailyEarningModel.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    return EarningsPaginationModel(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      todayEarnings: (json['todayEarnings'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weeklyEarnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      records: recordsList,
      dailyBreakdown: dailyList,
      weeklyCompletedRides: json['weeklyCompletedRides'] ?? 0,
      bonusTarget: json['bonusTarget'] ?? 15,
      bonusAmount: (json['bonusAmount'] ?? 1000).toDouble(),
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
