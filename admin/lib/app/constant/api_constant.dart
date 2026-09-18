class ApiConstant {
  // Centralized Base URL for backend API
  static const String baseUrl = 
  // 'https://api.buildora.cloud/api';
  "http://localhost:8082/api";

  // Admin Authentication Endpoints
  static const String adminLogin = "$baseUrl/auth/admin/login";
  static const String adminRegister = "$baseUrl/auth/admin/register";
  static const String adminProfile = "$baseUrl/auth/admin/profile";
  static const String adminLogout = "$baseUrl/auth/admin/logout";

  // Admin Booking Endpoints
  static const String adminBookings = "$baseUrl/admin/bookings";
  static const String adminDashboard = "$baseUrl/admin/dashboard";
  static const String adminUsers = "$baseUrl/admin/users";
  static const String adminUsersCreate = "$baseUrl/admin/users/create";
  static const String adminDrivers = "$baseUrl/admin/drivers";
  static const String adminDriverCreate = "$baseUrl/driver/register";

  // Admin Banner, Coupon, CMS & Upload Endpoints
  static const String adminCms = "$baseUrl/admin/cms";
  static const String adminUpload = "$baseUrl/admin/upload";

  // Admin Wallet Requests
  static const String adminWalletRequests = "$baseUrl/admin/wallet-requests";

  // Common Headers
  static Map<String, String> headers({String? token}) {
    final Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headerMap['Authorization'] = 'Bearer $token';
    }
    return headerMap;
  }
}
