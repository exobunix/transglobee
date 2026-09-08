class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Pagination? pagination;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final bool success = json.containsKey('success') ? (json['success'] ?? false) : true;
    final dynamic rawData = json.containsKey('data') ? json['data'] : json;

    return ApiResponse<T>(
      success: success,
      message: json['message'],
      data: rawData != null ? fromJsonT(rawData) : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
