import 'package:equatable/equatable.dart';

class DriverWalletResponseModel extends Equatable {
  final double balance;
  final String currency;
  final String lastUpdated;
  final double pendingPayout;

  const DriverWalletResponseModel({
    required this.balance,
    required this.currency,
    required this.lastUpdated,
    required this.pendingPayout,
  });

  factory DriverWalletResponseModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'] ?? json['walletBalance'] ?? json['currentBalance'] ?? 0.0;
    final rawPending = json['pendingPayout'] ?? json['pending'] ?? 0.0;
    return DriverWalletResponseModel(
      balance: (rawBalance is num) ? rawBalance.toDouble() : (double.tryParse(rawBalance.toString()) ?? 0.0),
      currency: json['currency']?.toString() ?? 'INR',
      lastUpdated: json['lastUpdated']?.toString() ?? '',
      pendingPayout: (rawPending is num) ? rawPending.toDouble() : (double.tryParse(rawPending.toString()) ?? 0.0),
    );
  }

  @override
  List<Object?> get props => [balance, currency, lastUpdated, pendingPayout];
}
