import 'package:equatable/equatable.dart';

class LogoutRequestModel extends Equatable {
  final String deviceToken;

  const LogoutRequestModel({required this.deviceToken});

  Map<String, dynamic> toJson() {
    return {
      'deviceToken': deviceToken,
    };
  }

  @override
  List<Object?> get props => [deviceToken];
}
