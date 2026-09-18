import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/core/network/api_client.dart';
import 'package:firebase_database/firebase_database.dart'; // Keep for location streaming if needed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import '../core/config.dart';

final databaseServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DatabaseService(apiClient);
});

class DatabaseService {
  final ApiClient _apiClient;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  DatabaseService(this._apiClient);

  Map<String, String> _getHeaders(String? token,
      {String? uid, String? email, bool isMultipart = false}) {
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    // Auto-detect local for bypass
    final bool isLocal =
        AppConfig.apiBaseUrl.toLowerCase().contains('localhost') ||
            AppConfig.apiBaseUrl.toLowerCase().contains('127.0.0.1');
    final String finalToken =
        isLocal ? 'dev-token-bypass' : (token ?? 'dev-token-bypass');

    headers['Authorization'] = 'Bearer $finalToken';
    if (uid != null && uid.isNotEmpty) {
      headers['x-dev-uid'] = uid;
    }
    if (email != null && email.isNotEmpty) {
      headers['x-dev-email'] = email;
    }
    return headers;
  }

  Future<bool> saveDriverToBackend(dynamic user, [String? token]) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/sync');
      final response = await http.post(
        url,
        headers: _getHeaders(token, uid: user.uid, email: user.email),
        body: json.encode({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'Driver',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return (data['hasDocs'] == true);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to save driver');
      }
    } catch (e) {
      print('Error saving driver to backend: $e');
      return true; // Soft fail to avoid breaking UX
    }
  }

  // Get active driver status
  Future<Map<String, dynamic>?> getDriverStatus(String token) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/status');
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting driver status: $e');
      return null;
    }
  }

  // Update driver online status
  Future<void> updateDriverOnlineStatus({
    required String token,
    required bool isOnline,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/status');
      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: json.encode({'isOnline': isOnline}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  // Save driver profile to Backend
  Future<void> saveDriverProfile(DriverModel driver, [String? token]) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/sync');

      final response = await http.post(
        url,
        headers: _getHeaders(token, uid: driver.firebaseId, email: driver.email),
        body: json.encode({
          'uid': driver.firebaseId,
          'name': driver.name,
          'email': driver.email,
          'mobileNumber': driver.phoneNumber,
          'aadharCardNumber': driver.aadharCardNumber,
          'drivingLicenseNumber': driver.drivingLicenseNumber,
          'panCardNumber': driver.panCardNumber,
          'dob': driver.dob,
          'vehicleId': driver.vehicleId,
          'vehicleModel': driver.vehicleModel,
          'vehicleYear': driver.vehicleYear,
          'vehicleNumberPlate': driver.vehicleNumberPlate,
          'vehicleType': driver.vehicleType,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save profile: ${response.body}');
      }
    } catch (e) {
      print('Error saving driver profile: $e');
      rethrow;
    }
  }

  // Update driver profile in Backend
  Future<void> updateDriverProfile({
    required String token,
    required Map<String, dynamic> updateData,
    String? uid,
    String? email,
  }) async {
    try {
      final url =
          Uri.parse('${AppConfig.apiBaseUrl}/driver/profile/update');
      final response = await http.put(
        url,
        headers: _getHeaders(token, uid: uid, email: email),
        body: json.encode(updateData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating driver profile: $e');
      rethrow;
    }
  }

  // Upload driver documents to ImageKit via Backend
  Future<Map<String, dynamic>> uploadDriverDocuments({
    required String token,
    XFile? photoFile,
    XFile? aadharFile,
    XFile? licenseFile,
    XFile? signatureFile,
    XFile? panFile,
    XFile? rcBookFile,
    XFile? insuranceFile,
    String? uid,
    String? email,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/upload');
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll(_getHeaders(token, uid: uid, email: email, isMultipart: true));

      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: photoFile.name,
        ));
      }
      if (aadharFile != null) {
        final bytes = await aadharFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'aadharCard',
          bytes,
          filename: aadharFile.name,
        ));
      }
      if (licenseFile != null) {
        final bytes = await licenseFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'drivingLicense',
          bytes,
          filename: licenseFile.name,
        ));
      }
      if (signatureFile != null) {
        final bytes = await signatureFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'signature',
          bytes,
          filename: signatureFile.name,
        ));
      }
      if (panFile != null) {
        final bytes = await panFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('panCard', bytes,
            filename: panFile.name));
      }
      if (rcBookFile != null) {
        final bytes = await rcBookFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('rcBook', bytes,
            filename: rcBookFile.name));
      }
      if (insuranceFile != null) {
        final bytes = await insuranceFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('insurance', bytes,
            filename: insuranceFile.name));
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to upload documents: ${response.body}');
      }

      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': true};
      }
    } catch (e) {
      print('Error uploading documents: $e');
      rethrow;
    }
  }

  // Get driver profile from backend
  Future<DriverModel?> getDriverProfile(String uid, String token) async {
    try {
      final response = await _apiClient.get('/driver/profile');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) return null;

        final dynamic driverData = data['driver'] ?? data['data'] ?? data;
        if (driverData is Map<String, dynamic>) {
          return DriverModel.fromJson(driverData);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete(String uid, String token) async {
    try {
      final response = await _apiClient.get('/driver/status');
      if (response.statusCode == 200) {
        final data = response.data;
        // If they are in the DB (isRegistered), we consider initial registration "complete"
        // so we don't show the multi-step registration flow again.
        return (data['isRegistered'] == true || data['hasDocs'] == true);
      }
      return true;
    } catch (e) {
      print('Error checking onboarding: $e');
      return true;
    }
  }

  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/otp/send');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send OTP');
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error sending OTP: $e');
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otp, String token) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/otp/verify');
      final response = await http
          .post(
            url,
            headers: _getHeaders(token),
            body: json.encode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'aadharCard': aadharCard,
          'panCard': panCard,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'driver': data['driver']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/driver/check-email',
      ).replace(queryParameters: {'email': email.trim()});
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}
