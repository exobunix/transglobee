// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/admin_model.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/toast.dart';
// Firestore/Firebase commented out as auth is handled via Node.js backend API
// import 'package:admin/app/constant/collection_name.dart';
// import 'package:admin/app/utils/fire_store_utils.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/show_toast.dart' show ShowToastDialog;

class LoginPageController extends GetxController {
  var isPasswordVisible = true.obs;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  RxString email = "".obs;
  RxString password = "".obs;

  @override
  void onInit() {
    getData();
    // emailController.text = "admin@transglobe.com";
    // passwordController.text = "admin123456";
    // Do NOT pre-fill credentials for security
    super.onInit();
  }

  /// REST API Admin Login using centralized ApiConstant
  Future<void> checkAndLoginOrCreateAdmin() async {
    ShowToastDialog.showLoader("Please wait...".tr);

    final String inputEmail = emailController.text.trim();
    final String inputPassword = passwordController.text.trim();

    if (inputEmail.isEmpty || inputPassword.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToast.errorToast("Please enter email and password.".tr);
      return;
    }

    try {
      // Calling Centralized Backend REST API Endpoint
      final response = await http.post(
        Uri.parse(ApiConstant.adminLogin),
        headers: ApiConstant.headers(),
        body: jsonEncode({
          'email': inputEmail,
          'password': inputPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = responseData['token'] ?? '';
        final adminJson = responseData['admin'] ?? {};

        // Save Auth Token & Session locally
        await AppSharedPreference.setString('adminToken', token);
        await AppSharedPreference.setString('adminEmail', inputEmail);
        Constant.isLogin = true;

        AdminModel adminModel = AdminModel(
          email: adminJson['email'] ?? inputEmail,
          name: adminJson['name'] ?? 'Admin',
          image: adminJson['profilePhoto'] ?? '',
          contactNumber: '',
          isDemo: false,
        );
        Constant.adminModel = adminModel;
        Constant.isDemoSet(adminModel);

        ShowToastDialog.closeLoader();
        ShowToast.successToast("Logged in successfully!".tr);
        Get.offAllNamed(Routes.DASHBOARD_SCREEN);
      } else {
        ShowToastDialog.closeLoader();
        String errorMsg = responseData['message'] ?? 'Invalid credentials.'.tr;
        ShowToast.errorToast(errorMsg);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToast.errorToast("Failed to connect to backend server: $e".tr);
      print("Backend Admin Login Error: $e");
    }

    /* 
    // =========================================================================
    // COMMENTED OUT: Old Firebase Auth & Firestore Login Logic
    // Firebase is now only used for Push Notifications.
    // =========================================================================
    // try {
    //   final adminSnapshot = await FirebaseFirestore.instance.collection(CollectionName.admin).get();
    //   if (adminSnapshot.docs.isEmpty) {
    //     UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    //       email: email,
    //       password: password,
    //     );
    //     AdminModel adminModel = AdminModel(
    //       email: email,
    //       name: "",
    //       image: "",
    //       contactNumber: "",
    //       isDemo: false,
    //     );
    //     Constant.isDemoSet(adminModel);
    //     await FirebaseFirestore.instance
    //         .collection(CollectionName.admin)
    //         .doc(userCredential.user!.uid)
    //         .set(adminModel.toJson());
    //     ShowToast.successToast("logged in successfully!".tr);
    //     ShowToastDialog.closeLoader();
    //     Get.offAllNamed(Routes.DASHBOARD_SCREEN);
    //   } else {
    //     await FirebaseAuth.instance
    //         .signInWithEmailAndPassword(email: email, password: password)
    //         .then((value) async {
    //       final AdminModel? adminData = await FireStoreUtils.getAdminProfile(value.user!.uid);
    //       if (adminData != null) {
    //         Constant.isLogin = await FireStoreUtils.isLogin();
    //         Constant.isDemoSet(adminData);
    //         ShowToastDialog.closeLoader();
    //         ShowToast.successToast("Logged in successfully!".tr);
    //         Get.offAllNamed(Routes.DASHBOARD_SCREEN);
    //       } else {
    //         await FirebaseAuth.instance.signOut();
    //         ShowToastDialog.closeLoader();
    //         ShowToast.errorToast("Admin not active or unauthorized.".tr);
    //       }
    //     });
    //   }
    // } catch (e) { ... }
    */
  }

  Future<void> getData() async {
    await Constant.getCurrencyData();
    await Constant.getLanguageData();
  }
}
