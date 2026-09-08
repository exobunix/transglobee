import 'package:flutter/foundation.dart';

@immutable
class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String date;
  final String type; // 'credit' or 'debit'
  final String? description;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['description'] ?? 'Transaction',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      type: json['type'] ?? 'debit',
      description: json['description'],
    );
  }
}

@immutable
class UserWalletState {
  final double balance;
  final String currency;
  final List<WalletTransaction> transactions;
  final bool isLoading;

  const UserWalletState({
    required this.balance,
    this.currency = 'INR',
    required this.transactions,
    this.isLoading = false,
  });

  UserWalletState copyWith({
    double? balance,
    String? currency,
    List<WalletTransaction>? transactions,
    bool? isLoading,
  }) {
    return UserWalletState(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory UserWalletState.fromBalanceJson(Map<String, dynamic> json) {
    return UserWalletState(
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      transactions: [],
    );
  }
}

