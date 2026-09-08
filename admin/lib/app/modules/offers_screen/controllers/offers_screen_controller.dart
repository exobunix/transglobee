// ignore_for_file: depend_on_referenced_packages
import 'package:admin/app/models/coupon_model.dart';
import 'dart:convert';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/utils/toast.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class OffersScreenController extends GetxController {
  RxString title = "Offers".tr.obs;
  RxList<CouponModel> couponList = <CouponModel>[].obs;
  Rx<TextEditingController> couponTitleController = TextEditingController().obs;
  Rx<TextEditingController> couponCodeController = TextEditingController().obs;
  Rx<TextEditingController> couponAmountController = TextEditingController().obs;
  Rx<TextEditingController> couponMinAmountController = TextEditingController().obs;
  Rx<TextEditingController> expireDateController = TextEditingController().obs;
  DateTime selectedDate = DateTime.now();

  RxBool isEditing = false.obs;
  RxBool isLoading = false.obs;
  RxBool isActive = false.obs;
  Rx<String> editingId = "".obs;

  RxString selectedAdminCommissionType = "Fix".obs;
  final List<String> adminCommissionType = ["Fix", "Percentage"];

  RxString couponPrivacyType = "Public".obs;
  final List<String> couponType = ["Private", "Public"];

  @override
  void onInit() {
    super.onInit();
    fetchCoupons();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2050));
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      expireDateController.value.text = selectedDate.toString();
    }
  }

  Future<void> fetchCoupons() async {
    isLoading.value = true;
    try {
      couponList.clear();
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.adminCms}?type=coupon"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['contents'] != null) {
          List list = data['contents'];
          couponList.addAll(list.map((e) {
            final model = CouponModel.fromJson(e['value']);
            model.cmsId = e['_id'];
            model.cmsKey = e['key'];
            model.id = e['key'];
            return model;
          }).toList());
        }
      }
    } catch (e) {
      ShowToast.errorToast('Failed to load coupons');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCoupon(BuildContext context) async {
    isLoading.value = true;
    try {
      final uniqueKey = "coupon_${DateTime.now().millisecondsSinceEpoch}";
      final coupon = CouponModel(
        id: uniqueKey,
        active: isActive.value,
        minAmount: couponMinAmountController.value.text,
        title: couponTitleController.value.text,
        code: couponCodeController.value.text,
        amount: couponAmountController.value.text,
        isFix: selectedAdminCommissionType.value == "Fix" ? true : false,
        isPrivate: couponPrivacyType.value == "Public" ? false : true,
        expireAt: Timestamp.fromDate(selectedDate),
        cmsKey: uniqueKey,
      );

      final valJson = coupon.toJson();
      valJson['expireAt'] = selectedDate.toIso8601String();

      final body = {
        "key": uniqueKey,
        "type": "coupon",
        "value": valJson,
      };

      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminCms),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setDefaultData();
        await fetchCoupons();
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to add coupon".tr);
      }
    } catch (e) {
      ShowToastDialog.toast("Failed to add coupon".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCoupon() async {
    isLoading.value = true;
    try {
      final coupon = CouponModel(
        id: editingId.value,
        active: isActive.value,
        minAmount: couponMinAmountController.value.text,
        title: couponTitleController.value.text,
        code: couponCodeController.value.text,
        amount: couponAmountController.value.text,
        isFix: selectedAdminCommissionType.value == "Fix" ? true : false,
        isPrivate: couponPrivacyType.value == "Public" ? false : true,
        expireAt: Timestamp.fromDate(selectedDate),
        cmsKey: editingId.value,
      );

      final valJson = coupon.toJson();
      valJson['expireAt'] = selectedDate.toIso8601String();

      final body = {
        "key": editingId.value,
        "type": "coupon",
        "value": valJson,
      };

      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminCms),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setDefaultData();
        await fetchCoupons();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to update coupon".tr);
      }
    } catch (e) {
      ShowToastDialog.toast("Failed to update coupon".tr);
    } finally {
      isLoading.value = false;
      isEditing.value = false;
    }
  }

  Future<void> removeCoupon(CouponModel couponModel) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.delete(
        Uri.parse("${ApiConstant.adminCms}/${couponModel.cmsId}"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        ShowToastDialog.toast("Coupon deleted...!".tr);
        await fetchCoupons();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Something went wrong".tr);
      }
    } catch (e) {
      ShowToastDialog.toast("Something went wrong".tr);
    } finally {
      isLoading.value = false;
    }
  }

  void setDefaultData() {
    couponTitleController.value.clear();
    couponCodeController.value.clear();
    couponAmountController.value.clear();
    couponMinAmountController.value.clear();
    expireDateController.value.clear();
    isEditing.value = false;
    isActive.value = false;
    editingId.value = "";
    selectedAdminCommissionType.value = "Fix";
    couponPrivacyType.value = "Public";
    selectedDate = DateTime.now();
  }

  @override
  void onClose() {
    couponTitleController.value.dispose();
    couponCodeController.value.dispose();
    couponAmountController.value.dispose();
    couponMinAmountController.value.dispose();
    expireDateController.value.dispose();
    super.onClose();
  }

  Future<void> toggleCoupon(CouponModel couponModel, bool value) async {
    try {
      isLoading.value = true;
      couponModel.active = value;

      final valJson = couponModel.toJson();
      if (couponModel.expireAt != null) {
        valJson['expireAt'] = couponModel.expireAt!.toDate().toIso8601String();
      }

      final body = {
        "key": couponModel.cmsKey,
        "type": "coupon",
        "value": valJson,
      };

      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminCms),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCoupons();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to toggle status".tr);
      }
    } catch (e) {
      log('Error toggling coupon: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
