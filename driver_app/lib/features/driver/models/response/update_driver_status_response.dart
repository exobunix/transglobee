import 'package:equatable/equatable.dart';

class UpdateDriverStatusResponse extends Equatable {
  final bool isOnline;
  final String updatedAt;

  const UpdateDriverStatusResponse({
    required this.isOnline,
    required this.updatedAt,
  });

  factory UpdateDriverStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateDriverStatusResponse(
      isOnline: json['isOnline'] ?? false,
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [isOnline, updatedAt];
}
