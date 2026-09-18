// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages, unused_local_variable
import 'dart:io';
import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/collection_name.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/driver_user_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/app/utils/web_download_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';

class DriverScreenController extends GetxController {
  RxString title = "All Drivers".tr.obs;

  RxBool isLoading = true.obs;
  RxBool isSearchEnable = true.obs;

  RxList<DriverUserModel> driverList = <DriverUserModel>[].obs;
  RxList<DriverUserModel> allDrivers = <DriverUserModel>[].obs;
  RxList<DriverUserModel> tempList = <DriverUserModel>[].obs;
  RxString selectedSearchType = "Name".obs;
  RxString selectedSearchTypeForData = "slug".obs;
  List<String> searchType = [
    "Name",
    "Phone",
    "Email",
  ];

  var currentPage = 1.obs;
  var startIndex = 1.obs;
  var endIndex = 1.obs;
  var totalPage = 1.obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;

  RxList<DriverUserModel> currentPageDriver = <DriverUserModel>[].obs;
  Rx<TextEditingController> userNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> imageController = TextEditingController().obs;
  Rx<TextEditingController> dateFiledController = TextEditingController().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Rx<File> imagePath = File('').obs;
  RxString mimeType = 'image/png'.obs;
  Rx<Uint8List> imagePickedFileBytes = Uint8List(0).obs;
  RxBool uploading = false.obs;
  RxString editingId = ''.obs;

  // Add Driver form controllers
  Rx<TextEditingController> addDriverNameController = TextEditingController().obs;
  Rx<TextEditingController> addDriverMobileController = TextEditingController().obs;
  Rx<TextEditingController> addDriverEmailController = TextEditingController().obs;
  Rx<TextEditingController> addDriverPasswordController = TextEditingController().obs;
  Rx<TextEditingController> addDriverLicenseController = TextEditingController().obs;
  RxBool addDriverLoading = false.obs;

  RxString totalItemPerPage = '0'.obs;
  Rx<DateTimeRange> selectedDate = DateTimeRange(
          start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0),
          end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0))
      .obs;

  @override
  void onInit() {
    super.onInit();
    getUser();
  }

  Future<void> getUser() async {
    isLoading.value = true;
    try {
      totalItemPerPage.value = Constant.numOfPageIemList.first;
      await fetchDrivers();
      dateFiledController.value.text = _formatDateRange(selectedDate.value);
    } catch (e, stack) {
      log('Error initializing driver screen: $e\n$stack');
      ShowToastDialog.toast('Failed to initialize driver data');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDateRange(DateTimeRange range) {
    return "${DateFormat('yyyy-MM-dd').format(range.start)} to ${DateFormat('yyyy-MM-dd').format(range.end)}";
  }

  Future<void> fetchDrivers() async {
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
          allDrivers.value = list.map((e) => DriverUserModel.fromJson(e)).toList();
          Constant.driverLength = allDrivers.length;
        }
      }
      await setPagination(totalItemPerPage.value);
    } catch (e, stack) {
      log('Error fetching drivers: $e\n$stack');
      ShowToastDialog.toast('Failed to fetch drivers');
    }
  }

  Future<void> setPagination(String page) async {
    isLoading.value = true;
    try {
      totalItemPerPage.value = page;
      int itemPerPage = pageValue(page);

      // Apply search filter locally
      String query = searchController.value.text.trim().toLowerCase();
      List<DriverUserModel> filteredDrivers = allDrivers.where((driver) {
        if (query.isEmpty) return true;
        if (selectedSearchTypeForData.value == "phoneNumber") {
          return (driver.phoneNumber ?? '').toLowerCase().contains(query);
        } else if (selectedSearchTypeForData.value == "email") {
          return (driver.email ?? '').toLowerCase().contains(query);
        } else {
          return (driver.fullName ?? '').toLowerCase().contains(query);
        }
      }).toList();

      int filteredLength = filteredDrivers.length;
      totalPage.value = (filteredLength / itemPerPage).ceil();
      if (totalPage.value < 1) totalPage.value = 1;

      startIndex.value = (currentPage.value - 1) * itemPerPage;
      endIndex.value = (currentPage.value * itemPerPage) > filteredLength ? filteredLength : (currentPage.value * itemPerPage);

      if (endIndex.value < startIndex.value) {
        currentPage.value = 1;
        await setPagination(page);
      } else {
        currentPageDriver.value = filteredDrivers.sublist(startIndex.value, endIndex.value);
      }
      update();
    } finally {
      isLoading.value = false;
    }
  }

  int pageValue(String data) {
    if (data == 'All') return Constant.driverLength!;
    return int.tryParse(data) ?? 0;
  }

  Future<void> removeDriver(DriverUserModel driverUserModel) async {
    isLoading.value = true;
    try {
      await FirebaseFirestore.instance.collection(CollectionName.drivers).doc(driverUserModel.id).delete();
      ShowToastDialog.toast("Driver deleted...!".tr);
      await FirebaseFirestore.instance.collection(CollectionName.verifyDriver).doc(driverUserModel.id).delete();
      log("Verify Driver Deleted...!");
    } catch (error) {
      log("Error deleting driver: $error");
      ShowToastDialog.toast("Something went wrong".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getSearchType() async {
    isLoading.value = true;
    try {
      switch (selectedSearchType.value) {
        case "Phone":
          selectedSearchTypeForData.value = "phoneNumber";
          break;
        case "Email":
          selectedSearchTypeForData.value = "email";
          break;
        default:
          selectedSearchTypeForData.value = "slug";
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPhoto() async {
    uploading.value = true;
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img == null) return;
      final imageFile = File(img.path);
      imageController.value.text = img.name;
      imagePath.value = imageFile;
      imagePickedFileBytes.value = await img.readAsBytes();
      mimeType.value = img.mimeType ?? 'image/png';
    } catch (e) {
      log('Error picking photo: $e');
    } finally {
      uploading.value = false;
    }
  }

  void getArgument(DriverUserModel driverUserModel) {
    driverModel.value = driverUserModel;
    userNameController.value.text = driverModel.value.fullName ?? '';
    phoneNumberController.value.text = Constant.maskMobileNumber(mobileNumber: driverModel.value.phoneNumber, countryCode: driverModel.value.countryCode);
    emailController.value.text = Constant.maskEmail(email: driverModel.value.email ?? '');
    imageController.value.text = driverModel.value.profilePic ?? '';
    editingId.value = driverModel.value.id ?? '';
  }

  /// Admin creates a new driver account via the backend REST API.
  Future<bool> addDriver() async {
    addDriverLoading.value = true;
    try {
      final name = addDriverNameController.value.text.trim();
      final mobile = addDriverMobileController.value.text.trim();
      final email = addDriverEmailController.value.text.trim();
      final password = addDriverPasswordController.value.text.trim();
      final license = addDriverLicenseController.value.text.trim();

      final response = await http.post(
        Uri.parse(ApiConstant.adminDriverCreate),
        headers: ApiConstant.headers(),
        body: jsonEncode({
          'name': name,
          'mobile': mobile,
          'email': email,
          'password': password,
          if (license.isNotEmpty) 'licenseNumber': license,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        ShowToastDialog.toast('Driver added successfully!');
        // Clear form fields
        addDriverNameController.value.clear();
        addDriverMobileController.value.clear();
        addDriverEmailController.value.clear();
        addDriverPasswordController.value.clear();
        addDriverLicenseController.value.clear();
        await fetchDrivers();
        return true;
      } else {
        ShowToastDialog.toast(data['message'] ?? 'Failed to add driver');
        return false;
      }
    } catch (e) {
      log('Error adding driver: $e');
      ShowToastDialog.toast('Error: $e');
      return false;
    } finally {
      addDriverLoading.value = false;
    }
  }

  Rx<TextEditingController> dateRangeController = TextEditingController().obs;
  DateTime? startDateForPdf;
  DateTime? endDateForPdf;
  Rx<DateTimeRange> selectedDateRangeForPdf =
      (DateTimeRange(start: DateTime(DateTime.now().year, DateTime.january, 1), end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0))).obs;
  List<DriverUserModel> pdfDriverList = [];

  Future<void> downloadDriverDataPdf() async {
    isLoading(true);
    pdfDriverList = await FireStoreUtils.dataForDriverPdf(selectedDateRangeForPdf.value);
    log("Pdf Data :: ${pdfDriverList.length}");
    await generateDriverDataPdf(pdfDriverList, selectedDateRangeForPdf.value);
    isLoading(false);
  }

  Future<void> generateDriverDataPdf(List<DriverUserModel> intercitybookingList, DateTimeRange selectedRange) async {
    String formattedStartDate = "${selectedRange.start.day}-${selectedRange.start.month}-${selectedRange.start.year}";
    String formattedEndDate = "${selectedRange.end.day}-${selectedRange.end.month}-${selectedRange.end.year}";

    var excel = Excel.createExcel();
    Sheet sheet = excel['Driver_History_'];
    excel.setDefaultSheet('Driver_History_');

    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle dataStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
      horizontalAlign: HorizontalAlign.Center,
    );

    List<CellValue?> headers = [
      TextCellValue("Id"),
      TextCellValue("FullName"),
      TextCellValue("Email"),
      TextCellValue("LoginType"),
      TextCellValue("DateOfBirth"),
      TextCellValue("CountryCode"),
      TextCellValue("PhoneNumber"),
      TextCellValue("WalletAmount"),
      TextCellValue("Gender"),
      TextCellValue("VehicleType"),
      TextCellValue("VehicleNumber"),
      TextCellValue("ModelName"),
      TextCellValue("SubscriptionExpiryDate"),
      TextCellValue("SubscriptionPlanTitle"),
      TextCellValue("SubscriptionPlanPrice"),
      TextCellValue("IsVerify"),
    ];

    sheet.appendRow(headers);

    for (var history in intercitybookingList) {
      List<CellValue?> data = [
        TextCellValue(" ${history.id?.substring(0, 4) ?? " "} "),
        TextCellValue(" ${history.fullName ?? " "} "),
        TextCellValue(" ${history.email ?? " "} "),
        TextCellValue(" ${history.loginType ?? " "} "),
        TextCellValue(" ${history.dateOfBirth ?? " "} "),
        TextCellValue(" ${history.countryCode ?? " "} "),
        TextCellValue(" ${history.phoneNumber ?? " "} "),
        TextCellValue(" ${history.walletAmount ?? " "} "),
        TextCellValue(" ${history.gender ?? " "} "),
        TextCellValue(" ${history.driverVehicleDetails!.vehicleTypeName ?? " "} "),
        TextCellValue(" ${history.driverVehicleDetails!.vehicleNumber ?? " "} "),
        TextCellValue(" ${history.driverVehicleDetails!.modelName ?? " "} "),
        TextCellValue(" ${history.subscriptionExpiryDate != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(history.subscriptionExpiryDate!.toDate()) : "N/A"} "),
        TextCellValue(" ${history.subscriptionPlan!.title ?? ""} "),
        TextCellValue(" ${history.subscriptionPlan!.price ?? ""} "),
        TextCellValue(" ${history.createdAt != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(history.createdAt!.toDate()) : "N/A"} "),
      ];

      sheet.appendRow(data);
    }

    List<int>? fileBytes = excel.encode();
    if (fileBytes != null) {
      downloadFile(fileBytes, 'Driver_History_${formattedStartDate}_to_$formattedEndDate.xlsx');
    }
  }
}
