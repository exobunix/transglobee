// ignore_for_file: body_might_complete_normally_catch_error, depend_on_referenced_packages, use_build_context_synchronously, unused_local_variable

import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/collection_name.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/driver_user_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

class CabBookingController extends GetxController {
  RxString title = "Cab Bookings".obs;
  RxBool isLoading = true.obs;
  RxBool isHistoryDownload = false.obs;
  RxBool isDatePickerEnable = true.obs;
  var currentPage = 1.obs;
  var startIndex = 1.obs;
  var endIndex = 1.obs;
  var totalPage = 1.obs;
  RxList<BookingModel> currentPageBooking = <BookingModel>[].obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;
  DateTime? startDate;
  DateTime? endDate;
  RxString selectedBookingStatus = "All".obs;
  RxString selectedBookingStatusForData = "All".obs;
  RxString selectedFilterBookingCabStatus = "All".obs;
  RxString selectedFilterBookingStatus = "All".obs;

  List<String> bookingStatus = [
    "All",
    "Placed",
    "Approved & Assigned",
    "Completed",
    "Rejected",
    "Cancelled",
    "Accepted",
    "OnGoing",
  ];

  DateTime? startDateForPdf;
  DateTime? endDateForPdf;
  Rx<TextEditingController> dateRangeController = TextEditingController().obs;
  Rx<DateTimeRange> selectedDateRange =
      (DateTimeRange(start: DateTime(DateTime.now().year, DateTime.january, 1), end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0))).obs;
  Rx<DateTimeRange> selectedDateRangeForPdf =
      (DateTimeRange(start: DateTime(DateTime.now().year, DateTime.january, 1), end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0))).obs;

  RxString selectedDateOption = "All".obs;
  List<String> dateOption = ["All", "Last Month", "Last 6 Months", "Last Year", "Custom"];
  RxBool isCustomVisible = false.obs;
  RxList<DriverUserModel> allDriverList = <DriverUserModel>[].obs;
  Rx<DriverUserModel?> selectedDriver = Rx<DriverUserModel?>(DriverUserModel(id: 'All'));
  RxString driverId = "".obs;

  RxString selectedBookingType = "cab".obs; // 'cab', 'truck', 'bus'
  List<BookingModel> allFetchedBookings = [];

  @override
  void onInit() {
    totalItemPerPage.value = Constant.numOfPageIemList.first;
    getBookings();
    getAllDriver();
    super.onInit();
  }

  List<BookingModel> pdfCabBookingList = [];

  Future<void> downloadCabBookingPdf(BuildContext context) async {
    if (selectedFilterBookingStatus.value == "Rejected") {
      selectedFilterBookingCabStatus.value = "booking_rejected";
    } else if (selectedFilterBookingStatus.value == "Placed") {
      selectedFilterBookingCabStatus.value = "booking_placed";
    } else if (selectedFilterBookingStatus.value == "Completed") {
      selectedFilterBookingCabStatus.value = "booking_completed";
    } else if (selectedFilterBookingStatus.value == "Cancelled") {
      selectedFilterBookingCabStatus.value = 'booking_cancelled';
    } else if (selectedFilterBookingStatus.value == "Accepted") {
      selectedFilterBookingCabStatus.value = 'booking_accepted';
    } else if (selectedFilterBookingStatus.value == "OnGoing") {
      selectedFilterBookingCabStatus.value = 'booking_ongoing';
    } else {
      selectedFilterBookingCabStatus.value = "All";
    }

    isHistoryDownload(true);
    pdfCabBookingList =
        await FireStoreUtils.getDataForPdfCab(selectedDateRangeForPdf.value, selectedDriver.value!.id.toString(), selectedFilterBookingCabStatus.value, selectedDateOption.value);
    log("Pdf Data :: ${pdfCabBookingList.length}");
    // for(var booking in pdfCabBookingList){
    //   log("Id : ${booking.id}, Pickup : ${booking.pickUpLocationAddress}, DropLocation : ${booking.dropLocationAddress}");
    // }
    await generateCabAndDownloadPdfWeb(pdfCabBookingList, selectedDateRangeForPdf.value);
    isHistoryDownload(false);
    Navigator.pop(context);
  }

  Future<void> getAllDriver() async {
    allDriverList.assignAll([DriverUserModel(id: "All", fullName: 'All Driver')]);
  }

  Future<void> getBookingDataByBookingStatus() async {
    isLoading.value = true;
    if (selectedBookingStatus.value == "Rejected") {
      selectedBookingStatusForData.value = "booking_rejected";
    } else if (selectedBookingStatus.value == "Placed") {
      selectedBookingStatusForData.value = "booking_placed";
    } else if (selectedBookingStatus.value == "Approved & Assigned") {
      selectedBookingStatusForData.value = "approved_assigned";
    } else if (selectedBookingStatus.value == "Completed") {
      selectedBookingStatusForData.value = "booking_completed";
    } else if (selectedBookingStatus.value == "Cancelled") {
      selectedBookingStatusForData.value = 'booking_cancelled';
    } else if (selectedBookingStatus.value == "Accepted") {
      selectedBookingStatusForData.value = 'booking_accepted';
    } else if (selectedBookingStatus.value == "OnGoing") {
      selectedBookingStatusForData.value = 'booking_ongoing';
    } else {
      selectedBookingStatusForData.value = "All";
    }

    await setPagination(totalItemPerPage.value);
    isLoading.value = false;
  }

  Future<void> removeBooking(BookingModel bookingModel) async {
    isLoading = true.obs;
    await FirebaseFirestore.instance.collection(CollectionName.bookings).doc(bookingModel.id).delete().then((value) {
      ShowToastDialog.toast("Booking deleted...!".tr);
    }).catchError((error) {
      ShowToastDialog.toast("Something went wrong".tr);
    });
    isLoading = false.obs;
  }

  Future<void> getBookings() async {
    isLoading.value = true;
    try {
      String apiType = 'ride';
      if (selectedBookingType.value == 'truck') {
        apiType = 'logistics';
      } else if (selectedBookingType.value == 'bus') {
        apiType = 'shuttle';
      }

      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.adminBookings}?type=$apiType");
      final response = await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookings'] != null) {
          List list = data['bookings'];
          allFetchedBookings = list.map((e) => BookingModel.fromJson(e)).toList();
        } else {
          allFetchedBookings = [];
        }
      } else {
        // Fallback or firestore if needed
        allFetchedBookings = [];
      }
    } catch (e) {
      log("Error fetching bookings from API: $e");
      allFetchedBookings = [];
    }

    Constant.bookingLength = allFetchedBookings.length;
    await setPagination(totalItemPerPage.value);
    isLoading.value = false;
  }

  Future<void> changeBookingType(String type) async {
    selectedBookingType.value = type;
    if (type == 'truck') {
      title.value = 'Logistics Bookings';
      selectedBookingStatus.value = 'Placed';
      selectedBookingStatusForData.value = 'booking_placed';
    } else if (type == 'bus') {
      title.value = 'Shuttle Bookings';
      selectedBookingStatus.value = 'Placed';
      selectedBookingStatusForData.value = 'booking_placed';
    } else {
      title.value = 'Cab Bookings';
      selectedBookingStatus.value = 'All';
      selectedBookingStatusForData.value = 'All';
    }
    currentPage.value = 1;
    await getBookings();
  }

  Future<void> setPagination(String page) async {
    isLoading.value = true;
    totalItemPerPage.value = page;
    int itemPerPage = pageValue(page);

    // Apply status filter and driver filter locally on fetched bookings
    List<BookingModel> filtered = allFetchedBookings.where((b) {
      bool statusMatch = true;
      if (selectedBookingStatusForData.value != "All" && selectedBookingStatusForData.value.isNotEmpty) {
        String currentStatus = (b.bookingStatus ?? '').toLowerCase();
        String roadmap = (b.roadmapStatus ?? '').toLowerCase();
        bool isCancelled = currentStatus.contains('cancel') || currentStatus.contains('reject') || roadmap == 'rejected';
        bool hasSegments = (b.segments != null && b.segments!.isNotEmpty) || (b.driverId != null && b.driverId!.isNotEmpty);

        if (selectedBookingStatusForData.value == "approved_assigned") {
          // Approved & Assigned tab: MUST have segments or driver assigned, and not cancelled
          statusMatch = !isCancelled && hasSegments;
        } else if (selectedBookingStatusForData.value == "booking_accepted") {
          // Accepted tab: Accepted/Approved/Confirmed by admin, but NOT assigned with segments/driver yet, and not cancelled
          bool isApprovedOrAccepted = currentStatus == 'accepted' || currentStatus == 'confirmed' || roadmap == 'approved' || currentStatus == 'approved';
          statusMatch = !isCancelled && isApprovedOrAccepted && !hasSegments;
        } else if (selectedBookingStatusForData.value == "booking_placed") {
          // Placed tab: New booking waiting for admin action (not accepted/approved, not assigned, not cancelled)
          bool isPlaced = currentStatus.contains('placed') || currentStatus.contains('pending');
          bool isApprovedOrAccepted = currentStatus == 'accepted' || roadmap == 'approved' || currentStatus == 'approved';
          statusMatch = !isCancelled && isPlaced && !isApprovedOrAccepted && !hasSegments;
        } else if (selectedBookingStatusForData.value == "booking_cancelled") {
          statusMatch = isCancelled;
        } else {
          String targetStatus = selectedBookingStatusForData.value.toLowerCase().replaceAll('booking_', '');
          statusMatch = currentStatus.contains(targetStatus);
        }
      }
      bool driverMatch = true;
      if (driverId.value.isNotEmpty && driverId.value != "All") {
        driverMatch = (b.driverId == driverId.value);
      }
      return statusMatch && driverMatch;
    }).toList();

    int totalCount = filtered.length;
    totalPage.value = (totalCount / (itemPerPage > 0 ? itemPerPage : 1)).ceil();
    if (totalPage.value == 0) totalPage.value = 1;

    startIndex.value = (currentPage.value - 1) * itemPerPage + 1;
    if (startIndex.value > totalCount) startIndex.value = totalCount > 0 ? 1 : 0;

    endIndex.value = currentPage.value * itemPerPage;
    if (endIndex.value > totalCount) endIndex.value = totalCount;

    int from = (currentPage.value - 1) * itemPerPage;
    if (from < 0) from = 0;
    if (from >= filtered.length) {
      currentPageBooking.value = [];
    } else {
      int to = from + itemPerPage;
      if (to > filtered.length) to = filtered.length;
      currentPageBooking.value = filtered.sublist(from, to);
    }

    update();
    isLoading.value = false;
  }

  RxString totalItemPerPage = '0'.obs;

  int pageValue(String data) {
    if (data == 'All') return Constant.bookingLength!;
    return int.tryParse(data) ?? 0;
  }

  Future<void> generateCabAndDownloadPdfWeb(List<BookingModel> bookingList, DateTimeRange selectedRange) async {
    final formattedStartDate = "${selectedRange.start.day}-${selectedRange.start.month}-${selectedRange.start.year}";
    final formattedEndDate = "${selectedRange.end.day}-${selectedRange.end.month}-${selectedRange.end.year}";

    final excel = Excel.createExcel();
    final Sheet sheet = excel['CabBooking_History'];
    excel.setDefaultSheet('CabBooking_History');

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
      TextCellValue(" PickUpLocationAddress "),
      TextCellValue(" DropLocationAddress "),
      TextCellValue(" Distance "),
      TextCellValue(" Total "),
      TextCellValue(" Payment Type "),
      TextCellValue(" Status "),
      TextCellValue(" Pickup Time "),
      TextCellValue(" Drop Time "),
      TextCellValue(" Create Time "),
    ];
    sheet.appendRow(headers);

    String getReadableBookingStatus(String? status) {
      switch (status) {
        case "booking_placed":
          return "Placed";
        case "booking_accepted":
          return "Accepted";
        case "booking_ongoing":
          return "Ongoing";
        case "booking_cancelled":
          return "Cancelled";
        case "booking_completed":
          return "Completed";
        case "booking_rejected":
          return "Rejected";
        default:
          return "-";
      }
    }

    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    sheet.setDefaultRowHeight(28);

    sheet.appendRow(List<CellValue?>.filled(headers.length, null));

    for (var history in bookingList) {
      List<CellValue?> data = [
        TextCellValue(" ${history.id?.substring(0, 4) ?? " "} "),
        TextCellValue(" ${history.pickUpLocationAddress ?? " "} "),
        TextCellValue(" ${history.dropLocationAddress ?? " "} "),
        TextCellValue(" ${history.distance!.distance?.toString() ?? " "} "),
        TextCellValue(" ${history.subTotal?.toString() ?? " "} "),
        TextCellValue(" ${history.paymentType ?? " "} "),
        TextCellValue(" ${getReadableBookingStatus(history.bookingStatus)} "),
        TextCellValue(" ${history.pickupTime != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(history.pickupTime!.toDate()) : "N/A"} "),
        TextCellValue(" ${history.dropTime != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(history.dropTime!.toDate()) : "N/A"} "),
        TextCellValue(" ${history.createAt != null ? DateFormat('dd MMM, yyyy  hh:mm a').format(history.createAt!.toDate()) : "N/A"} "),
      ];
      sheet.appendRow(data);
    }

    // Convert the file to bytes
    List<int>? fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([Uint8List.fromList(fileBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "CabBooking_History_${formattedStartDate}_to_$formattedEndDate.xlsx")
        ..click();

      html.Url.revokeObjectUrl(url);
    }
  }
}
