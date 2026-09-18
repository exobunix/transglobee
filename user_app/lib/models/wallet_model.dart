import 'package:flutter/foundation.dart';

@immutable
class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String date;
  final String type; // 'credit' or 'debit'
  final String? description;
  final String status; // 'pending', 'completed', 'rejected'

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.status = 'completed',
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? json['description'] ?? 'Transaction',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? (json['createdAt'] != null ? json['createdAt'].toString().split('T').first : ''),
      type: json['type'] ?? 'debit',
      description: json['description'] ?? json['title'],
      status: json['status'] ?? 'completed',
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
    final rawBalance = json['balance'] ?? json['walletBalance'] ?? 0.0;
    return UserWalletState(
      balance: (rawBalance is num) ? rawBalance.toDouble() : (double.tryParse(rawBalance.toString()) ?? 0.0),
      currency: json['currency'] ?? 'INR',
      transactions: [],
    );
  }
}

