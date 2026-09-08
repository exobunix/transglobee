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
    return DriverWalletResponseModel(
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
      pendingPayout: (json['pendingPayout'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [balance, currency, lastUpdated, pendingPayout];
}
