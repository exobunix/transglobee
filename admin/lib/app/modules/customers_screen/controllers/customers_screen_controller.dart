// ignore_for_file: deprecated_member_use, depend_on_referenced_packages, use_build_context_synchronously, unused_local_variable
import 'dart:io';
import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/collection_name.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/models/wallet_transaction_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/app/utils/toast.dart';
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

class CustomersScreenController extends GetxController {
  RxString title = "Customers".tr.obs;
  RxBool isLoading = true.obs;
  RxInt selectedGender = 1.obs;
  RxBool isSearchEnable = true.obs;

  var currentPage = 1.obs;
  var startIndex = 1.obs;
  var endIndex = 1.obs;
  var totalPage = 1.obs;
  RxList<UserModel> allUserList = <UserModel>[].obs;
  RxList<UserModel> currentPageUser = <UserModel>[].obs;
  Rx<TextEditingController> dateFiledController = TextEditingController().obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;

  RxString selectedSearchType = "Name".obs;
  RxString selectedSearchTypeForData = "slug".obs;
  List<String> searchType = [
    "Name",
    "Phone",
    "Email",
  ];

  RxString selectedDateOption = "All".obs;
  List<String> dateOption = ["All", "Last Month", "Last 6 Months", "Last Year", "Custom"];
  RxBool isCustomVisible = false.obs;
  RxBool isHistoryDownload = false.obs;

  @override
  void onInit() {
    totalItemPerPage.value = Constant.numOfPageIemList.first;
    getUser();
    fetchAllRoutes();
    dateFiledController.value.text = "${DateFormat('yyyy-MM-dd').format(selectedDate.value.start)} to ${DateFormat('yyyy-MM-dd').format(selectedDate.value.end)}";
    super.onInit();
  }

  Future<void> getSearchType() async {
    isLoading.value = true;
    if (selectedSearchType.value == "Phone") {
      selectedSearchTypeForData.value = "phoneNumber";
    } else if (selectedSearchType.value == "Email") {
      selectedSearchTypeForData.value = "email";
    } else {
      selectedSearchTypeForData.value = "slug";
    }
    isLoading.value = false;
  }

  Future<void> removePassengers(UserModel userModel) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.delete(
        Uri.parse("${ApiConstant.adminUsers}/${userModel.id}"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        ShowToastDialog.toast("Passengers deleted...!".tr);
        getUser();
      } else {
        ShowToastDialog.toast("Something went wrong".tr);
      }
    } catch (e) {
      ShowToastDialog.toast("Something went wrong".tr);
    }
    isLoading.value = false;
  }

  Future<void> updateUserStatus(UserModel userModel, bool isActive) async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.put(
        Uri.parse("${ApiConstant.adminUsers}/${userModel.id}/status"),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({"status": isActive ? "active" : "inactive"}),
      );
      if (response.statusCode == 200) {
        ShowToastDialog.toast("Status updated successfully".tr);
        getUser();
      } else {
        ShowToastDialog.toast("Something went wrong".tr);
      }
    } catch (e) {
      log('Error updating status: $e');
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String company,
  }) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.post(
        Uri.parse(ApiConstant.adminUsersCreate),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          "name": name,
          "email": email,
          "mobileNumber": phone,
          "password": password,
          // "companyName": company,
          "status": "active"
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201 || responseData['success'] == true) {
        ShowToastDialog.toast("User created successfully!".tr);
        getUser();
      } else {
        ShowToastDialog.toast(responseData['message'] ?? "Something went wrong".tr);
      }
    } catch (e) {
      log('Error creating user: $e');
      ShowToastDialog.toast("Something went wrong".tr);
    }
    isLoading.value = false;
  }

  Future<bool> updateProfile({required String name, required String email, required String phone, required String gender}) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.put(
        Uri.parse("${ApiConstant.adminUsers}/${editingId.value}/profile"),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          "name": name,
          "email": email,
          "mobileNumber": phone,
          "gender": gender,
        }),
      );
      if (response.statusCode == 200) {
        getUser();
        isLoading.value = false;
        return true;
      }
    } catch (e) {
      log('Error updating profile: $e');
    }
    isLoading.value = false;
    return false;
  }

  void showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New User".tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: "Full Name *".tr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: "Email Address *".tr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: "Phone Number".tr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Password *".tr),
                ),
                // const SizedBox(height: 10),
                // TextField(
                //   controller: companyCtrl,
                //   decoration: InputDecoration(labelText: "Company Name".tr),
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text("Cancel".tr),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                  ShowToastDialog.toast("Please fill all required fields".tr);
                  return;
                }
                Get.back();
                await createUser(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  company: companyCtrl.text.trim(),
                );
              },
              child: Text("Submit".tr),
            ),
          ],
        );
      },
    );
  }

  Future<void> getUser() async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse(ApiConstant.adminUsers),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          List list = data['users'];
          allUserList.value = list.map((e) => UserModel.fromJson(e)).toList();
          Constant.usersLength = allUserList.length;
        }
      }
    } catch (e) {
      log('Error fetching users: $e');
    }
    setPagination(totalItemPerPage.value);
    isLoading.value = false;
  }

  Rx<DateTimeRange> selectedDate = DateTimeRange(
          start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0),
          end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0))
      .obs;

  Future<void> setPagination(String page) async {
    isLoading.value = true;
    totalItemPerPage.value = page;
    int itemPerPage = pageValue(page);

    // Apply search filter locally
    String query = searchController.value.text.trim().toLowerCase();
    List<UserModel> filteredUsers = allUserList.where((user) {
      if (query.isEmpty) return true;
      if (selectedSearchTypeForData.value == "phoneNumber") {
        return (user.phoneNumber ?? '').toLowerCase().contains(query);
      } else if (selectedSearchTypeForData.value == "email") {
        return (user.email ?? '').toLowerCase().contains(query);
      } else {
        return (user.fullName ?? '').toLowerCase().contains(query);
      }
    }).toList();

    int filteredLength = filteredUsers.length;
    totalPage.value = (filteredLength / itemPerPage).ceil();
    if (totalPage.value < 1) totalPage.value = 1;

    startIndex.value = (currentPage.value - 1) * itemPerPage;
    endIndex.value = (currentPage.value * itemPerPage) > filteredLength ? filteredLength : (currentPage.value * itemPerPage);

    if (endIndex.value < startIndex.value) {
      currentPage.value = 1;
      setPagination(page);
    } else {
      currentPageUser.value = filteredUsers.sublist(startIndex.value, endIndex.value);
    }
    update();
    isLoading.value = false;
  }

  // setPagination(String page) {
  //   totalItemPerPage.value = page;
  //   int itemPerPage = pageValue(page);
  //   totalPage.value = (userList.length / itemPerPage).ceil();
  //   startIndex.value = (currentPage.value - 1) * itemPerPage;
  //   endIndex.value = (currentPage.value * itemPerPage) > userList.length ? userList.length : (currentPage.value * itemPerPage);
  //   if (endIndex.value < startIndex.value) {
  //     currentPage.value = 1;
  //     setPagination(page);
  //   } else {
  //     currentPageUser.value = userList.sublist(startIndex.value, endIndex.value);
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  RxString totalItemPerPage = '0'.obs;

  int pageValue(String data) {
    if (data == 'All') {
      return Constant.usersLength!;
    } else {
      return int.parse(data);
    }
  }

  Rx<TextEditingController> userNameController = TextEditingController().obs;
  Rx<TextEditingController> walletAmountController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> imageController = TextEditingController().obs;
  RxString editingId = ''.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<File> imagePath = File('').obs;
  RxString mimeType = 'image/png'.obs;
  Rx<Uint8List> imagePickedFileBytes = Uint8List(0).obs;
  RxBool uploading = false.obs;

  RxList<AdminRouteModel> allRoutes = <AdminRouteModel>[].obs;
  RxList<String> selectedRouteIds = <String>[].obs;

  void getArgument(UserModel usersModel) {
    userModel.value = usersModel;
    userNameController.value.text = userModel.value.fullName!;
    walletAmountController.value.text = userModel.value.walletAmount!;
    phoneNumberController.value.text = Constant.maskMobileNumber(mobileNumber: userModel.value.phoneNumber, countryCode: userModel.value.countryCode);
    emailController.value.text = Constant.maskEmail(email: userModel.value.email!);
    userModel.value.gender == "Male" ? selectedGender.value = 1 : selectedGender.value = 2;
    // addressController.value.text = userModel.value.address!;
    imageController.value.text = userModel.value.profilePic!;
    editingId.value = userModel.value.id!;
    selectedRouteIds.value = usersModel.assignedRoutes?.map((e) => e.id ?? "").where((id) => id.isNotEmpty).toList() ?? [];
  }

  Future<void> walletTopUp() async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: walletAmountController.value.text,
        createdDate: Timestamp.now(),
        paymentType: 'admin',
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userModel.value.id,
        isCredit: true,
        type: "customer",
        note: "Admin Top Up");

    await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
      if (value == true) {
        ShowToast.successToast("Amount added to your wallet".tr);
        await FireStoreUtils.updateUserWallet(amount: walletAmountController.value.text, userId: userModel.value.id.toString()).then((value) async {
          await FireStoreUtils.getUserByUserID(userModel.value.id.toString()).then((value) {
            if (value != null) {
              userModel.value = value;
            }
          });
        });
      }
    });
  }

  Future<void> pickPhoto() async {
    try {
      uploading.value = true;
      ImagePicker picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      File imageFile = File(img!.path);

      imageController.value.text = img.name;
      imagePath.value = imageFile;
      imagePickedFileBytes.value = await img.readAsBytes();
      mimeType.value = "${img.mimeType}";
      uploading.value = false;
    } catch (e) {
      uploading.value = false;
    }
  }

  Rx<TextEditingController> dateRangeController = TextEditingController().obs;
  DateTime? startDateForPdf;
  DateTime? endDateForPdf;
  Rx<DateTimeRange> selectedDateRangeForPdf =
      (DateTimeRange(start: DateTime(DateTime.now().year, DateTime.january, 1), end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0))).obs;
  List<UserModel> pdfCustomerList = [];

  Future<void> downloadCustomerDataPdf(BuildContext context) async {
    isHistoryDownload(true);
    pdfCustomerList = await FireStoreUtils.dataForCustomerPdf(selectedDateRangeForPdf.value);
    log("Pdf Data :: ${pdfCustomerList.length}");
    await generateCustomerDataPdf(pdfCustomerList, selectedDateRangeForPdf.value);
    Navigator.pop(context);
    isHistoryDownload(false);
  }

  Future<void> generateCustomerDataPdf(List<UserModel> customerList, DateTimeRange selectedRange) async {
    String formattedStartDate = "${selectedRange.start.day}-${selectedRange.start.month}-${selectedRange.start.year}";
    String formattedEndDate = "${selectedRange.end.day}-${selectedRange.end.month}-${selectedRange.end.year}";

    var excel = Excel.createExcel();
    Sheet sheet = excel['Customer_History_'];
    excel.setDefaultSheet('Customer_History_');

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
      TextCellValue(" Id "),
      TextCellValue(" FullName "),
      TextCellValue(" Email "),
      TextCellValue(" Country Code "),
      TextCellValue(" PhoneNumber "),
      TextCellValue(" WalletAmount "),
      TextCellValue(" Gender "),
      TextCellValue(" Create Time "),
    ];

    sheet.appendRow(headers);

    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Auto-fit columns and set default row height
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }
    sheet.setDefaultRowHeight(28);

    // Add a blank row for spacing
    sheet.appendRow(List<CellValue?>.filled(headers.length, null));

    // Write customer data rows
    for (final customer in customerList) {
      List<CellValue?> data = [
        TextCellValue(" ${customer.id?.substring(0, 4) ?? "N/A"} "),
        TextCellValue(" ${customer.fullName ?? "N/A"} "),
        TextCellValue(" ${customer.email ?? "N/A"} "),
        TextCellValue(" ${customer.countryCode ?? "N/A"} "),
        TextCellValue(" ${customer.phoneNumber ?? "N/A"} "),
        TextCellValue(" ${customer.walletAmount ?? "0"} "),
        TextCellValue(" ${customer.gender ?? "N/A"} "),
        TextCellValue(
          " ${customer.createdAt != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(customer.createdAt!.toDate()) : "N/A"} ",
        ),
      ];

      sheet.appendRow(data);
    }

    // Export to file if data exists
    final fileBytes = excel.encode();
    if (fileBytes != null && fileBytes.isNotEmpty) {
      downloadFile(fileBytes, 'Customer_History_${formattedStartDate}_to_$formattedEndDate.xlsx');
    }
  }

  Future<void> fetchAllRoutes() async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.baseUrl}/admin/routes"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          allRoutes.value = data.map((e) => AdminRouteModel.fromJson(e)).toList();
        } else if (data['routes'] != null) {
          List list = data['routes'];
          allRoutes.value = list.map((e) => AdminRouteModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log('Error fetching routes: $e');
    }
  }

  Future<bool> assignRoutes(String userId, List<String> routeIds) async {
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.put(
        Uri.parse("${ApiConstant.baseUrl}/admin/users/$userId/assign-routes"),
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          "assignedRoutes": routeIds,
        }),
      );
      if (response.statusCode == 200) {
        getUser();
        return true;
      }
    } catch (e) {
      log('Error assigning routes: $e');
    }
    return false;
  }
}

class AdminRouteModel {
  String? id;
  String? name;
  String? source;
  String? destination;

  AdminRouteModel({this.id, this.name, this.source, this.destination});

  AdminRouteModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? json['id'] ?? "";
    name = json['name'] ?? "";
    source = json['source'] ?? "";
    destination = json['destination'] ?? "";
  }
}
