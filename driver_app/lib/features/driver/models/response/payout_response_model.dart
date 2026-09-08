import 'package:equatable/equatable.dart';

class PayoutResponseModel extends Equatable {
  final String payoutId;
  final double amount;
  final String status;
  final String requestedAt;

  const PayoutResponseModel({
    required this.payoutId,
    required this.amount,
    required this.status,
    required this.requestedAt,
  });

  factory PayoutResponseModel.fromJson(Map<String, dynamic> json) {
    return PayoutResponseModel(
      payoutId: json['payoutId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [payoutId, amount, status, requestedAt];
}
