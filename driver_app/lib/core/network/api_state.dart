import 'package:equatable/equatable.dart';

enum ApiStatus { initial, loading, success, error, empty }

class ApiState<T> extends Equatable {
  final ApiStatus status;
  final T? data;
  final String? message;

  const ApiState({
    this.status = ApiStatus.initial,
    this.data,
    this.message,
  });

  ApiState<T> copyWith({
    ApiStatus? status,
    T? data,
    String? message,
  }) {
    return ApiState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, data, message];
}
