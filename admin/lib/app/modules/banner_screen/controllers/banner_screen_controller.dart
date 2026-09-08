// ignore_for_file: depend_on_referenced_packages
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'dart:convert';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/banner_model.dart';
import 'package:admin/app/utils/toast.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BannerScreenController extends GetxController {
  RxString title = "Banner".tr.obs;

  Rx<TextEditingController> bannerNameController = TextEditingController().obs;
  Rx<TextEditingController> bannerDescriptionController = TextEditingController().obs;
  Rx<TextEditingController> bannerImageNameController = TextEditingController().obs;
  Rx<File> imageFile = File('').obs;
  Rx<Uint8List> imagePickedFileBytes = Uint8List(0).obs;
  RxString mimeType = 'image/png'.obs;
  RxBool isLoading = false.obs;
  RxList<BannerModel> bannerList = <BannerModel>[].obs;
  Rx<BannerModel> bannerModel = BannerModel().obs;

  RxBool isEditing = false.obs;
  RxBool isImageUpdated = false.obs;
  RxString imageURL = "".obs;
  RxString editingId = "".obs;

  RxString selectedBannerType = 'banner'.obs; // 'banner' or 'featured_banner'
  Rx<TextEditingController> offerTextController = TextEditingController().obs;
  RxBool isOfferBanner = false.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  @override
  void onClose() {
    bannerNameController.value.dispose();
    bannerDescriptionController.value.dispose();
    bannerImageNameController.value.dispose();
    offerTextController.value.dispose();
    super.onClose();
  }

  Future<void> getData() async {
    isLoading.value = true;
    bannerList.clear();
    try {
      String token = await AppSharedPreference.getString('adminToken');
      // Fetch normal banners
      final responseBanner = await http.get(
        Uri.parse("${ApiConstant.adminCms}?type=banner"),
        headers: ApiConstant.headers(token: token),
      );
      // Fetch featured banners
      final responseFeaturedBanner = await http.get(
        Uri.parse("${ApiConstant.adminCms}?type=featured_banner"),
        headers: ApiConstant.headers(token: token),
      );

      List<BannerModel> fetchedBanners = [];

      if (responseBanner.statusCode == 200) {
        final data = jsonDecode(responseBanner.body);
        if (data['contents'] != null) {
          List list = data['contents'];
          fetchedBanners.addAll(list.map((e) {
            final model = BannerModel.fromJson(e['value']);
            model.cmsId = e['_id'];
            model.cmsKey = e['key'];
            model.bannerType = 'banner';
            return model;
          }));
        }
      }

      if (responseFeaturedBanner.statusCode == 200) {
        final data = jsonDecode(responseFeaturedBanner.body);
        if (data['contents'] != null) {
          List list = data['contents'];
          fetchedBanners.addAll(list.map((e) {
            final model = BannerModel.fromJson(e['value']);
            model.cmsId = e['_id'];
            model.cmsKey = e['key'];
            model.bannerType = 'featured_banner';
            return model;
          }));
        }
      }

      bannerList.assignAll(fetchedBanners);
    } catch (e, stack) {
      log('Error fetching banners: $e\n$stack');
      ShowToast.errorToast('Failed to load banners');
    } finally {
      isLoading.value = false;
    }
  }

  void setDefaultData() {
    bannerNameController.value.text = "";
    bannerDescriptionController.value.text = "";
    bannerImageNameController.value.text = "";
    isEditing.value = false;
    bannerNameController.value.clear();
    bannerDescriptionController.value.clear();
    bannerImageNameController.value.clear();
    imageFile.value = File('');
    imagePickedFileBytes.value = Uint8List(0);
    mimeType.value = 'image/png';
    editingId.value = '';
    isEditing.value = false;
    isImageUpdated.value = false;
    imageURL.value = '';
    offerTextController.value.text = '';
    isOfferBanner.value = false;
    selectedBannerType.value = 'banner';
  }

  Future<String?> uploadImageToBackend() async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstant.adminUpload),
      );
      request.headers.addAll(ApiConstant.headers(token: token));
      
      if (GetPlatform.isWeb) {
        if (imagePickedFileBytes.value.isEmpty) return null;
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imagePickedFileBytes.value,
          filename: bannerImageNameController.value.text,
        ));
      } else {
        if (imageFile.value.path.isEmpty) return null;
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.value.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['url'];
        }
      }
      return null;
    } catch (e) {
      log("Error uploading image: $e");
      return null;
    }
  }

  Future<void> updateBanner(BuildContext context) async {
    try {
      isLoading.value = true;
      String? imageUrl = bannerModel.value.image;
      if (imageFile.value.path.isNotEmpty || imagePickedFileBytes.value.isNotEmpty) {
        String? url = await uploadImageToBackend();
        if (url != null) {
          log('image url in update  $url');
          imageUrl = url;
        }
      }
      bannerModel.value.bannerName = bannerNameController.value.text;
      bannerModel.value.bannerDescription = bannerDescriptionController.value.text;
      bannerModel.value.isOfferBanner = isOfferBanner.value;
      bannerModel.value.offerText = offerTextController.value.text;
      bannerModel.value.image = imageUrl;
      bannerModel.value.bannerType = selectedBannerType.value;

      final body = {
        "key": bannerModel.value.cmsKey,
        "type": selectedBannerType.value,
        "value": bannerModel.value.toJson(),
      };

      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminCms),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setDefaultData();
        await getData();
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to update banner".tr);
      }
    } catch (e, stack) {
      log('Error updating banner: $e\n$stack');
      ShowToastDialog.toast("Failed to update banner".tr);
    } finally {
      isLoading.value = false;
      isEditing.value = false;
    }
  }

  Future<void> addBanner(BuildContext context) async {
    if (imageFile.value.path.isNotEmpty || imagePickedFileBytes.value.isNotEmpty) {
      try {
        isLoading.value = true;
        String? url = await uploadImageToBackend();
        if (url == null) {
          isLoading.value = false;
          ShowToastDialog.toast("Failed to upload image".tr);
          return;
        }
        log('image url in addBanner  $url');
        
        final uniqueKey = "${selectedBannerType.value}_${DateTime.now().millisecondsSinceEpoch}";
        final newBanner = BannerModel(
          id: uniqueKey,
          bannerName: bannerNameController.value.text,
          bannerDescription: bannerDescriptionController.value.text,
          image: url,
          isOfferBanner: isOfferBanner.value,
          offerText: offerTextController.value.text,
          isEnable: true,
          cmsKey: uniqueKey,
          bannerType: selectedBannerType.value,
        );

        final body = {
          "key": uniqueKey,
          "type": selectedBannerType.value,
          "value": newBanner.toJson(),
        };

        String token = await AppSharedPreference.getString('adminToken');
        final response = await http.post(
          Uri.parse(ApiConstant.adminCms),
          headers: ApiConstant.headers(token: token),
          body: jsonEncode(body),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          setDefaultData();
          await getData();
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          ShowToastDialog.toast(data['message'] ?? "Failed to add banner".tr);
        }
      } catch (e, stack) {
        log('Error adding banner: $e\n$stack');
        ShowToastDialog.toast("Failed to add banner".tr);
      } finally {
        isLoading.value = false;
      }
    } else {
      isLoading.value = false;
      ShowToastDialog.toast("Please select a valid banner image".tr);
    }
  }

  Future<void> removeBanner(BannerModel bannerModel) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.delete(
        Uri.parse("${ApiConstant.adminCms}/${bannerModel.cmsId}"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        ShowToastDialog.toast("Banner deleted...!".tr);
        await getData();
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

  Future<void> toggleBanner(BannerModel bannerModel, bool value) async {
    try {
      isLoading.value = true;
      bannerModel.isEnable = value;

      final body = {
        "key": bannerModel.cmsKey,
        "type": "banner",
        "value": bannerModel.toJson(),
      };

      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminCms),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await getData();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to toggle status".tr);
      }
    } catch (e) {
      log('Error toggling banner: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
