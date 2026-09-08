import 'package:equatable/equatable.dart';

class UpdateDriverStatusRequest extends Equatable {
  final bool isOnline;

  const UpdateDriverStatusRequest({required this.isOnline});

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
    };
  }

  @override
  List<Object?> get props => [isOnline];
}
