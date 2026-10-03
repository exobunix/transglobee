import 'package:flutter/foundation.dart';

class ApiConstant {
  // Centralized Base URL for backend API: auto-switches between localhost and live
  static String get baseUrl {
    if (kIsWeb) {
      try {
        final host = Uri.base.host;
        if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
          return 'http://localhost:8082/api';
        }
      } catch (_) {}
    }
    return 'https://api.transgloble.com/api';
  }

  // Admin Authentication Endpoints
  static String get adminLogin => "$baseUrl/auth/admin/login";
  static String get adminRegister => "$baseUrl/auth/admin/register";
  static String get adminProfile => "$baseUrl/auth/admin/profile";
  static String get adminLogout => "$baseUrl/auth/admin/logout";

  // Admin Booking Endpoints
  static String get adminBookings => "$baseUrl/admin/bookings";
  static String get adminDashboard => "$baseUrl/admin/dashboard";
  static String get adminUsers => "$baseUrl/admin/users";
  static String get adminUsersCreate => "$baseUrl/admin/users/create";
  static String get adminDrivers => "$baseUrl/admin/drivers";
  static String get adminDriverCreate => "$baseUrl/driver/register";

  // Admin Banner, Coupon, CMS & Upload Endpoints
  static String get adminCms => "$baseUrl/admin/cms";
  static String get adminUpload => "$baseUrl/admin/upload";

  // Admin Wallet Requests
  static String get adminWalletRequests => "$baseUrl/admin/wallet-requests";

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
