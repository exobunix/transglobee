class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    // If the response itself is the data (no 'success' wrapper)
    final bool hasSuccessKey = json.containsKey('success');
    final bool successValue = hasSuccessKey ? (json['success'] == true) : true;
    
    // Handle cases where data is wrapped in 'data', 'driver', 'user', or is the body itself
    dynamic rawData = json['data'] ?? json['driver'] ?? json['user'] ?? json['bookings'] ?? json['transactions'] ?? json['stats'];
    
    // If no specific data wrapper found, use the whole json as data
    if (rawData == null && fromJsonT != null) {
      rawData = json;
    }

    return ApiResponse<T>(
      success: successValue,
      message: json['message']?.toString(),
      data: (rawData != null && fromJsonT != null) ? fromJsonT(rawData) : null,
    );
  }
}
