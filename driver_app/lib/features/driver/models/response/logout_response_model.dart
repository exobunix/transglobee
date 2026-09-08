import 'package:equatable/equatable.dart';

class LogoutResponseModel extends Equatable {
  final bool success;
  final String message;

  const LogoutResponseModel({required this.success, required this.message});

  factory LogoutResponseModel.fromJson(Map<String, dynamic> json) {
    return LogoutResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message];
}
