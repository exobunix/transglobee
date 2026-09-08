import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import '../../../constant/api_constant.dart';
import '../../../constant/show_toast.dart';
import '../../../models/admin_vehicle_model.dart';
import '../../../models/driver_user_model.dart';
import '../../../services/shared_preferences/app_preference.dart';

class VehicleScreenController extends GetxController {
  RxList<AdminVehicleModel> vehicleList = <AdminVehicleModel>[].obs;
  RxList<AdminVehicleModel> filteredVehicleList = <AdminVehicleModel>[].obs;
  RxList<DriverUserModel> driverList = <DriverUserModel>[].obs;
  RxList<AdminVehicleRoute> dbRoutesList = <AdminVehicleRoute>[].obs;
  RxList<String> selectedRouteIds = <String>[].obs;
  RxBool isLoading = false.obs;
  RxString selectedTab = 'All'.obs;

  // Controllers for Add/Edit Form
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final numberPlateController = TextEditingController();
  final passengerCapacityController = TextEditingController();
  final luggageCapacityController = TextEditingController();
  final truckLoadCapacityController = TextEditingController();
  final imageController = TextEditingController();

  RxString selectedVehicleType = 'car'.obs;
  RxString selectedStatus = 'active'.obs;
  RxString selectedDriverId = ''.obs;

  RxBool isEditing = false.obs;
  String? editingVehicleId;

  Rx<File?> selectedImageFile = Rx<File?>(null);
  RxList<int> imageBytes = <int>[].obs;
  RxString selectedImageName = ''.obs;
  RxBool isUploadingImage = false.obs;

  // Pagination fields
  var currentPage = 1.obs;
  var startIndex = 1.obs;
  var endIndex = 1.obs;
  var totalPage = 1.obs;
  RxString totalItemPerPage = '10'.obs;
  RxList<AdminVehicleModel> currentPageVehicles = <AdminVehicleModel>[].obs;

  @override
  void onInit() {
    getVehicles();
    getDriversList();
    getRoutesList();
    super.onInit();
  }

  void clearForm() {
    nameController.clear();
    brandController.clear();
    modelController.clear();
    yearController.clear();
    numberPlateController.clear();
    passengerCapacityController.clear();
    luggageCapacityController.clear();
    truckLoadCapacityController.clear();
    imageController.clear();
    selectedVehicleType.value = 'car';
    selectedStatus.value = 'active';
    selectedDriverId.value = '';
    isEditing.value = false;
    editingVehicleId = null;
    selectedImageFile.value = null;
    imageBytes.clear();
    selectedImageName.value = '';
    selectedRouteIds.clear();
  }

  void fillForm(AdminVehicleModel vehicle) {
    nameController.text = vehicle.vehicleName ?? '';
    brandController.text = vehicle.brand ?? '';
    modelController.text = vehicle.model ?? '';
    yearController.text = vehicle.year ?? '';
    numberPlateController.text = vehicle.numberPlate ?? '';
    passengerCapacityController.text = vehicle.passengerCapacity?.toString() ?? '0';
    luggageCapacityController.text = vehicle.luggageCapacity?.toString() ?? '0';
    truckLoadCapacityController.text = vehicle.truckLoadCapacity?.toString() ?? '0';
    imageController.text = vehicle.vehicleImage ?? '';
    selectedVehicleType.value = vehicle.vehicleType ?? 'car';
    selectedStatus.value = vehicle.status ?? 'active';
    selectedDriverId.value = vehicle.driverId ?? '';
    isEditing.value = true;
    editingVehicleId = vehicle.id;
    selectedImageFile.value = null;
    imageBytes.clear();
    selectedImageName.value = '';
    selectedRouteIds.value = vehicle.routes?.map((r) => r.id ?? '').where((id) => id.isNotEmpty).toList() ?? [];
  }

  Future<void> getVehicles() async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.baseUrl}/admin/vehicles/list"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          List list = data['data'];
          vehicleList.value = list.map((e) => AdminVehicleModel.fromJson(e)).toList();
          filterVehicles();
        }
      } else {
        ShowToastDialog.toast("Failed to fetch vehicles list");
      }
    } catch (e) {
      log("Error fetching vehicles: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void filterVehicles() {
    if (selectedTab.value == 'All') {
      filteredVehicleList.value = vehicleList;
    } else if (selectedTab.value == 'Cars') {
      filteredVehicleList.value = vehicleList.where((e) => e.vehicleType == 'car').toList();
    } else if (selectedTab.value == 'Trucks') {
      filteredVehicleList.value = vehicleList.where((e) => e.vehicleType == 'truck').toList();
    } else if (selectedTab.value == 'Buses') {
      filteredVehicleList.value = vehicleList.where((e) => e.vehicleType == 'bus').toList();
    }
    setPagination(totalItemPerPage.value);
  }

  Future<void> getDriversList() async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse(ApiConstant.adminDrivers),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['drivers'] != null) {
          List list = data['drivers'];
          driverList.value = list.map((e) => DriverUserModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log("Error fetching drivers for vehicle assignment: $e");
    }
  }

  Future<void> getRoutesList() async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.baseUrl}/admin/routes"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null) {
          List list = data['routes'];
          dbRoutesList.value = list.map((e) => AdminVehicleRoute.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log("Error fetching routes list: $e");
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        selectedImageFile.value = File(img.path);
        imageBytes.value = await img.readAsBytes();
        selectedImageName.value = img.name;
        imageController.text = img.name;
      }
    } catch (e) {
      log("Error picking image: $e");
    }
  }

  Future<String?> uploadImageToBackend() async {
    isUploadingImage.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstant.baseUrl}/admin/upload"),
      );
      request.headers.addAll(ApiConstant.headers(token: token));
      
      if (GetPlatform.isWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: selectedImageName.value,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedImageFile.value!.path,
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
      ShowToastDialog.toast("Image upload failed");
      return null;
    } catch (e) {
      log("Error uploading image: $e");
      ShowToastDialog.toast("Error uploading image");
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> addVehicle() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      String? imageUrl;
      if (selectedImageFile.value != null) {
        imageUrl = await uploadImageToBackend();
        if (imageUrl == null) {
          isLoading.value = false;
          return;
        }
      } else {
        imageUrl = imageController.text.trim();
      }

      String token = await AppSharedPreference.getString('adminToken');
      final body = {
        "vehicleType": selectedVehicleType.value,
        "vehicleName": nameController.text.trim(),
        "brand": brandController.text.trim(),
        "model": modelController.text.trim(),
        "year": yearController.text.trim(),
        "numberPlate": numberPlateController.text.trim(),
        "passengerCapacity": int.tryParse(passengerCapacityController.text.trim()) ?? 0,
        "luggageCapacity": int.tryParse(luggageCapacityController.text.trim()) ?? 0,
        "truckLoadCapacity": double.tryParse(truckLoadCapacityController.text.trim()) ?? 0.0,
        "driverId": selectedDriverId.value.isNotEmpty ? selectedDriverId.value : null,
        "status": selectedStatus.value,
        "vehicleImage": imageUrl,
        "routes": selectedRouteIds.toList(),
      };

      final response = await http.post(
        Uri.parse("${ApiConstant.baseUrl}/admin/vehicles/add"),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201 || (data is Map && data['success'] == true)) {
        ShowToastDialog.toast("Vehicle added successfully");
        Get.back();
        await getVehicles();
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to add vehicle");
      }
    } catch (e) {
      log("Error adding vehicle: $e");
      ShowToastDialog.toast("Error adding vehicle");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editVehicle() async {
    if (editingVehicleId == null) return;
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      String? imageUrl;
      if (selectedImageFile.value != null) {
        imageUrl = await uploadImageToBackend();
        if (imageUrl == null) {
          isLoading.value = false;
          return;
        }
      } else {
        imageUrl = imageController.text.trim();
      }

      String token = await AppSharedPreference.getString('adminToken');
      final body = {
        "vehicleType": selectedVehicleType.value,
        "vehicleName": nameController.text.trim(),
        "brand": brandController.text.trim(),
        "model": modelController.text.trim(),
        "year": yearController.text.trim(),
        "numberPlate": numberPlateController.text.trim(),
        "passengerCapacity": int.tryParse(passengerCapacityController.text.trim()) ?? 0,
        "luggageCapacity": int.tryParse(luggageCapacityController.text.trim()) ?? 0,
        "truckLoadCapacity": double.tryParse(truckLoadCapacityController.text.trim()) ?? 0.0,
        "driverId": selectedDriverId.value.isNotEmpty ? selectedDriverId.value : null,
        "status": selectedStatus.value,
        "vehicleImage": imageUrl,
        "routes": selectedRouteIds.toList(),
      };

      final response = await http.put(
        Uri.parse("${ApiConstant.baseUrl}/admin/vehicles/$editingVehicleId"),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || (data is Map && data['success'] == true)) {
        ShowToastDialog.toast("Vehicle updated successfully");
        Get.back();
        await getVehicles();
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to update vehicle");
      }
    } catch (e) {
      log("Error editing vehicle: $e");
      ShowToastDialog.toast("Error editing vehicle");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.delete(
        Uri.parse("${ApiConstant.baseUrl}/admin/vehicles/$vehicleId"),
        headers: ApiConstant.headers(token: token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || (data is Map && data['success'] == true)) {
        ShowToastDialog.toast("Vehicle deleted successfully");
        await getVehicles();
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to delete vehicle");
      }
    } catch (e) {
      log("Error deleting vehicle: $e");
      ShowToastDialog.toast("Error deleting vehicle");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleVehicleStatus(String vehicleId, bool currentStatus) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.put(
        Uri.parse("${ApiConstant.baseUrl}/admin/vehicles/$vehicleId/toggle"),
        headers: ApiConstant.headers(token: token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || (data is Map && data['success'] == true)) {
        ShowToastDialog.toast("Vehicle status toggled");
        await getVehicles();
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to toggle status");
      }
    } catch (e) {
      log("Error toggling vehicle status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void setPagination(String page) {
    totalItemPerPage.value = page;
    int itemPerPage = pageValue(page);
    totalPage.value = (filteredVehicleList.length / itemPerPage).ceil();
    startIndex.value = (currentPage.value - 1) * itemPerPage;
    endIndex.value = (currentPage.value * itemPerPage) > filteredVehicleList.length ? filteredVehicleList.length : (currentPage.value * itemPerPage);
    if (endIndex.value < startIndex.value) {
      currentPage.value = 1;
      setPagination(page);
    } else {
      currentPageVehicles.value = filteredVehicleList.sublist(startIndex.value, endIndex.value);
    }
    isLoading.value = false;
    update();
  }

  int pageValue(String data) {
    if (data == 'All') {
      return filteredVehicleList.length;
    } else {
      return int.parse(data);
    }
  }
}
