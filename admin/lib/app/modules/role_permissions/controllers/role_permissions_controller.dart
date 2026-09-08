import 'dart:convert';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubAdminModel {
  String? id;
  String? name;
  String? email;
  String? role;
  List<String>? allowedModules;
  String? plainPassword;

  SubAdminModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.allowedModules,
    this.plainPassword,
  });

  factory SubAdminModel.fromJson(Map<String, dynamic> json) {
    return SubAdminModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'supervisor',
      allowedModules: json['allowedModules'] != null
          ? List<String>.from(json['allowedModules'])
          : [],
      plainPassword: json['plainPassword'] ?? '',
    );
  }
}

class ImportableUser {
  String? name;
  String? email;
  String? mobileNumber;
  String? type; // 'user' or 'driver'

  ImportableUser({this.name, this.email, this.mobileNumber, this.type});

  factory ImportableUser.fromJson(Map<String, dynamic> json, String type) {
    return ImportableUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      type: type,
    );
  }
}

class RolePermissionsController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<SubAdminModel> subAdmins = <SubAdminModel>[].obs;
  RxList<ImportableUser> importableUsers = <ImportableUser>[].obs;

  // Available modules for permission toggling
  final List<Map<String, String>> availableModules = [
    {'id': 'dashboard', 'name': 'Dashboard'},
    {'id': 'cab_bookings', 'name': 'Cab Bookings'},
    {'id': 'shuttle_bookings', 'name': 'Shuttle Bookings'},
    {'id': 'logistics_bookings', 'name': 'Logistics Bookings'},
    {'id': 'users', 'name': 'Users Management'},
    {'id': 'drivers', 'name': 'Driver Management'},
    {'id': 'vehicles', 'name': 'Vehicle Management'},
    {'id': 'settings', 'name': 'Settings'},
  ];

  @override
  void onInit() {
    super.onInit();
    fetchSubAdmins();
    fetchImportableUsers();
  }

  Future<void> fetchImportableUsers() async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/sub-admins/importable");
      final response = await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<ImportableUser> list = [];
          if (data['users'] is List) {
            for (var u in data['users']) {
              list.add(ImportableUser.fromJson(u, 'User'));
            }
          }
          if (data['drivers'] is List) {
            for (var d in data['drivers']) {
              list.add(ImportableUser.fromJson(d, 'Driver'));
            }
          }
          importableUsers.assignAll(list);
        }
      }
    } catch (e) {
      // Ignore background fetch error
    }
  }

  Future<void> fetchSubAdmins() async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/sub-admins");
      final response = await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subAdmins'] != null) {
          final list = (data['subAdmins'] as List)
              .map((e) => SubAdminModel.fromJson(e))
              .toList();
          subAdmins.assignAll(list);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch sub-admins: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createSubAdmin({
    required String name,
    required String email,
    required String password,
    required String role,
    required List<String> allowedModules,
  }) async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/sub-admins");
      final body = jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": role,
        "allowedModules": allowedModules,
      });

      final response = await http.post(uri, headers: ApiConstant.headers(token: token), body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar("Success", "Account created successfully.",
            backgroundColor: Colors.green, colorText: Colors.white);
        await fetchSubAdmins();
        return true;
      } else {
        Get.snackbar("Error", data['message'] ?? "Failed to create account.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> updateSubAdmin({
    required String id,
    required String name,
    required String email,
    required String role,
    required List<String> allowedModules,
    String? password,
  }) async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/sub-admins/$id");
      final map = <String, dynamic>{
        "name": name,
        "email": email,
        "role": role,
        "allowedModules": allowedModules,
      };
      if (password != null && password.isNotEmpty) {
        map["password"] = password;
      }

      final response = await http.put(uri, headers: ApiConstant.headers(token: token), body: jsonEncode(map));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Account updated successfully.",
            backgroundColor: Colors.green, colorText: Colors.white);
        await fetchSubAdmins();
        return true;
      } else {
        Get.snackbar("Error", data['message'] ?? "Failed to update account.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<void> deleteSubAdmin(String id) async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/sub-admins/$id");
      final response = await http.delete(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Account deleted successfully.",
            backgroundColor: Colors.green, colorText: Colors.white);
        await fetchSubAdmins();
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar("Error", data['message'] ?? "Failed to delete account.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
