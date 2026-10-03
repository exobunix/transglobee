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

      await http.put(
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

      ShowToastDialog.closeLoader();
      ShowToast.successToast("Profile updated successfully.".tr);
    } catch (e) {
      log("Error updating profile: $e");
      ShowToastDialog.closeLoader();
      ShowToast.errorToast("Failed to update profile: $e".tr);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> setAdminPassword() async {
    String email = passwordResetController.value.text.trim();
    try {
      Constant.waitingLoader();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.back();
      ShowToast.successToast("Password reset link has been sent to $email.");
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'Failed to send password reset email.';
      }
      ShowToast.errorToast(errorMessage);
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Error in setAdminPassword: $e");
      ShowToast.errorToast("Failed to send password reset link".tr);
    }
  }
}
