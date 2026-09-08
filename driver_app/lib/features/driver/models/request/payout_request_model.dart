import 'package:equatable/equatable.dart';

class PayoutRequestModel extends Equatable {
  final double amount;
  final String method;

  const PayoutRequestModel({required this.amount, required this.method});

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
    };
  }

  @override
  List<Object?> get props => [amount, method];
}
