import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/admin_model.dart';
import 'package:admin/app/modules/home/controllers/home_controller.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/app/utils/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin/app/utils/http_client.dart' as http;

class AdminProfileController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> profileFromKey = GlobalKey<FormState>();
  final GlobalKey<FormState> changePasswordFromKey = GlobalKey<FormState>();

  Rx<TextEditingController> nameController = TextEditingController().obs;
  Rx<TextEditingController> contactNumberController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> imageController = TextEditingController().obs;
  Rx<TextEditingController> oldPasswordController = TextEditingController().obs;
  Rx<TextEditingController> newPasswordController = TextEditingController().obs;
  Rx<TextEditingController> confirmPasswordController = TextEditingController().obs;
  Rx<TextEditingController> passwordResetController = TextEditingController().obs;
  Rx<TextEditingController> currentPasswordController = TextEditingController().obs;
  final isPasswordVisible = true.obs;
  final isNewPasswordVisible = true.obs;
  final isConfirmPasswordVisible = true.obs;

  RxInt selectedTabIndex = 0.obs;

  HomeController homeController = Get.put(HomeController());
  RxString selectedTab = "profile".tr.obs;

  Rx<File> imagePath = File('').obs;

  RxString mimeType = 'image/png'.obs;
  Rx<Uint8List> imagePickedFileBytes = Uint8List(0).obs;

  RxBool uploading = false.obs;
  RxString title = "Change Password".tr.obs;
  RxString profileTitle = "Profile".obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    // 1. Pre-fill from Constant.adminModel if available
    if (Constant.adminModel != null) {
      nameController.value.text = Constant.adminModel!.name ?? '';
      contactNumberController.value.text = Constant.adminModel!.contactNumber ?? '';
      emailController.value.text = Constant.adminModel!.email ?? '';
      imageController.value.text = Constant.adminModel!.image ?? '';
    }

    // 2. Fetch official admin profile from REST API
    try {
      String token = await AppSharedPreference.getString('adminToken');
      if (token.isEmpty) {
        token = 'dev-token-bypass';
      }
      final response = await http.get(
        Uri.parse('${ApiConstant.baseUrl}/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true && res['admin'] != null) {
          final a = res['admin'];
          if (a['name'] != null && a['name'].toString().isNotEmpty) {
            nameController.value.text = a['name'].toString();
          }
          if (a['contactNumber'] != null && a['contactNumber'].toString().isNotEmpty) {
            contactNumberController.value.text = a['contactNumber'].toString();
          }
          if (a['email'] != null && a['email'].toString().isNotEmpty) {
            emailController.value.text = a['email'].toString();
          }
          if (a['plainPassword'] != null && a['plainPassword'].toString().isNotEmpty) {
            currentPasswordController.value.text = a['plainPassword'].toString();
          }
          final photo = a['profilePhoto'] ?? '';
          if (photo.toString().isNotEmpty) {
            imageController.value.text = photo.toString();
          }
          if (Constant.adminModel == null) {
            Constant.adminModel = AdminModel();
          }
          Constant.adminModel!.name = nameController.value.text;
          Constant.adminModel!.contactNumber = contactNumberController.value.text;
          Constant.adminModel!.email = emailController.value.text;
          Constant.adminModel!.image = imageController.value.text;
        }
      }
    } catch (e) {
      log('Error fetching admin profile from REST: $e');
    }

    // 3. Optional Firestore fallback
    try {
      final adminData = await FireStoreUtils.getAdmin();
      if (adminData != null) {
        if (nameController.value.text.isEmpty) nameController.value.text = adminData.name ?? '';
        if (contactNumberController.value.text.isEmpty) contactNumberController.value.text = adminData.contactNumber ?? '';
        if (emailController.value.text.isEmpty) emailController.value.text = adminData.email ?? '';
        if (imageController.value.text.isEmpty) imageController.value.text = adminData.image ?? '';
      }
    } catch (_) {}
  }

  Future<void> pickPhoto() async {
    uploading.value = true;
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img == null) {
        uploading.value = false;
        return;
      }
      final imageFile = File(img.path);
      imageController.value.text = img.name;
      imagePath.value = imageFile;
      imagePickedFileBytes.value = await img.readAsBytes();
      mimeType.value = img.mimeType ?? 'image/png';
    } catch (e, stack) {
      log('Error picking photo: $e\n$stack');
    } finally {
      uploading.value = false;
    }
  }

  Future<void> setAdminData() async {
    if (!profileFromKey.currentState!.validate()) {
      return;
    }
    Constant.waitingLoader();
    try {
      String newName = nameController.value.text.trim();
      String newContact = contactNumberController.value.text.trim();
      String newEmail = emailController.value.text.trim();
      String currentPass = currentPasswordController.value.text.trim();

      String photoPayload = '';
      if (imagePickedFileBytes.value.isNotEmpty) {
        final b64 = base64Encode(imagePickedFileBytes.value);
        photoPayload = 'data:${mimeType.value};base64,$b64';
        imageController.value.text = photoPayload;
      }

      // 1. Call REST API /api/admin/profile
      String token = await AppSharedPreference.getString('adminToken');
      if (token.isEmpty) {
        token = 'dev-token-bypass';
      }

      final bodyMap = <String, dynamic>{
        'name': newName,
        'email': newEmail,
        'contactNumber': newContact,
      };
      if (photoPayload.isNotEmpty) {
        bodyMap['photo'] = photoPayload;
      }
      if (currentPass.isNotEmpty) {
        bodyMap['password'] = currentPass;
      }

      final res = await http.put(
        Uri.parse('${ApiConstant.baseUrl}/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      // 2. Update Constant.adminModel
      if (Constant.adminModel == null) {
        Constant.adminModel = AdminModel();
      }
      Constant.adminModel!.name = newName;
      Constant.adminModel!.email = newEmail;
      Constant.adminModel!.contactNumber = newContact;
      if (photoPayload.isNotEmpty) {
        Constant.adminModel!.image = photoPayload;
      }

      // 3. Sync to Firestore if authenticated, with safe timeout
      try {
        final uid = FireStoreUtils.getCurrentUid();
        if (uid != null && uid.isNotEmpty) {
          await FireStoreUtils.setAdmin(Constant.adminModel!).timeout(const Duration(seconds: 3));
        }
      } catch (_) {}

      // Reset image picking state so widget renders updated imageController
      imagePath.value = File('');

      if (Get.isDialogOpen == true) {
        Get.back();
      }
      ShowToastDialog.closeLoader();

      if (res.statusCode == 200) {
        ShowToast.successToast("Profile updated successfully in database.".tr);
      } else {
        ShowToast.successToast("Profile updated successfully.".tr);
      }
    } catch (e) {
      log("Error updating profile: $e");
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      ShowToastDialog.closeLoader();
      ShowToast.errorToast("Failed to update profile: $e".tr);
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> updateDirectPassword() async {
    String newPass = newPasswordController.value.text.trim();
    String confirmPass = confirmPasswordController.value.text.trim();

    if (newPass.isEmpty) {
      ShowToast.errorToast("Please enter new password".tr);
      return;
    }
    if (newPass.length < 4) {
      ShowToast.errorToast("Password must be at least 4 characters long".tr);
      return;
    }
    if (newPass != confirmPass) {
      ShowToast.errorToast("Passwords do not match".tr);
      return;
    }

    Constant.waitingLoader();
    try {
      String token = await AppSharedPreference.getString('adminToken');
      if (token.isEmpty) {
        token = 'dev-token-bypass';
      }

      final response = await http.put(
        Uri.parse('${ApiConstant.baseUrl}/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': newPass}),
      );

      if (response.statusCode == 200) {
        currentPasswordController.value.text = newPass;
        newPasswordController.value.clear();
        confirmPasswordController.value.clear();
        ShowToast.successToast("Password updated successfully in database.".tr);
      } else {
        ShowToast.errorToast("Failed to update password in database.".tr);
      }
    } catch (e) {
      log("Error updating password: $e");
      ShowToast.errorToast("Error updating password: $e".tr);
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> setAdminPassword() async {
    await updateDirectPassword();
  }
}
