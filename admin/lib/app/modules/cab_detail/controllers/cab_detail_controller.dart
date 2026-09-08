import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:developer';

import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/driver_user_model.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../cab_bookings_screen/controllers/cab_booking_controller.dart';


class CabDetailController extends GetxController {
  RxString title = "Cab Detail".tr.obs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  RxBool isLoading = true.obs;
  RxBool isSavingRoadmap = false.obs;
  RxBool isApprovingRoadmap = false.obs;
  RxBool isAcceptingBooking = false.obs;
  RxBool isRoadmapSaved = false.obs;
  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Rx<UserModel> userModel = UserModel().obs;

  // Edit Goods Details
  RxString transportMode = "Train".obs;
  RxInt helperCount = 0.obs;

  // Booking Overview derived fields
  RxString pickupText = ''.obs;
  RxString dropText = ''.obs;
  RxString customerText = ''.obs;
  RxInt itemsCount = 0.obs;
  RxString roadmapStatusText = 'DRAFT'.obs;

  // Pricing Override inputs
  final vehiclePriceController = TextEditingController();
  final helperCostController = TextEditingController();
  final tollChargesController = TextEditingController();
  final nightChargesController = TextEditingController();
  final handlingChargesController = TextEditingController();
  final discountController = TextEditingController();
  RxDouble totalPrice = 0.0.obs;

  // Roadmap Segments
  RxList<RoadmapSegment> segments = <RoadmapSegment>[].obs;

  void addSegment() {
    isRoadmapSaved.value = false;
    segments.add(RoadmapSegment(
      fromController: TextEditingController(),
      toController: TextEditingController(),
      dateController: TextEditingController(),
      timeController: TextEditingController(),
      priceController: TextEditingController(text: '0'),
      mode: 'Road'.obs,
    ));
  }

  void removeSegment(int index) {
    if (index >= 0 && index < segments.length) {
      isRoadmapSaved.value = false;
      final seg = segments[index];
      seg.fromController.dispose();
      seg.toController.dispose();
      seg.dateController.dispose();
      seg.timeController.dispose();
      seg.priceController.dispose();
      segments.removeAt(index);
    }
  }

  Future<void> saveRoadmap() async {
    if (segments.isEmpty) {
      Get.snackbar("Error", "Please add at least one segment.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isSavingRoadmap.value = true;
    try {
      String? bookingId = bookingModel.value.id;
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/supervisor/bookings/$bookingId/roadmap");

      final segmentsJson = segments.map((s) => {
        "from": s.fromController.text,
        "to": s.toController.text,
        "mode": s.mode.value,
        "estimatedDate": s.dateController.text,
        "estimatedTime": s.timeController.text,
        "segmentPrice": double.tryParse(s.priceController.text) ?? 0.0,
        "assignedDriverId": s.assignedDriverId.value,
      }).toList();

      final body = jsonEncode({"segments": segmentsJson});
      final response = await http.patch(uri, headers: ApiConstant.headers(token: token), body: body);
      if (response.statusCode == 200) {
        isRoadmapSaved.value = true;
        Get.snackbar("Saved", "Roadmap saved successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        await getArgument(showLoading: false);
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar("Error", err['message'] ?? "Failed to save roadmap.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSavingRoadmap.value = false;
    }
  }

  Future<void> approveRoadmap() async {
    isApprovingRoadmap.value = true;
    try {
      String? bookingId = bookingModel.value.id;
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/bookings/logistics-bookings/$bookingId/roadmap/approve");
      final body = jsonEncode({});
      final response = await http.post(uri, headers: ApiConstant.headers(token: token), body: body);
      if (response.statusCode == 200) {
        Get.snackbar("Approved", "Roadmap approved and sent to drivers.", backgroundColor: Colors.green, colorText: Colors.white);
        await getArgument(showLoading: false);
        if (Get.isRegistered<CabBookingController>()) {
          Get.find<CabBookingController>().getBookings();
        }
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar("Error", err['message'] ?? "Failed to approve roadmap.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isApprovingRoadmap.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    getArgument();
  }

  Future<void> getArgument({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    try {
      String? bookingId = Get.parameters['bookingId']!;
      log("==============> Booking ID: $bookingId");

      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse(ApiConstant.adminBookings);
      final response = await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        if (responseJson['success'] == true && responseJson['bookings'] != null) {
          final bookings = responseJson['bookings'];
          Map<String, dynamic>? foundBookingMap;

          if (bookings is Map) {
            final rides = bookings['rides'];
            final logistics = bookings['logistics'];
            final shuttles = bookings['shuttles'];

            if (rides is List) {
              for (var b in rides) {
                if (b['_id'] == bookingId || b['id'] == bookingId) {
                  foundBookingMap = b;
                  break;
                }
              }
            }
            if (foundBookingMap == null && logistics is List) {
              for (var b in logistics) {
                if (b['_id'] == bookingId || b['id'] == bookingId) {
                  foundBookingMap = b;
                  break;
                }
              }
            }
            if (foundBookingMap == null && shuttles is List) {
              for (var b in shuttles) {
                if (b['_id'] == bookingId || b['id'] == bookingId) {
                  foundBookingMap = b;
                  break;
                }
              }
            }
          } else if (bookings is List) {
            for (var b in bookings) {
              if (b['_id'] == bookingId || b['id'] == bookingId) {
                foundBookingMap = b;
                break;
              }
            }
          }

          if (foundBookingMap != null) {
            bookingModel.value = BookingModel.fromJson(foundBookingMap);

            // Populate fields if type is logistics or shuttle
            final bType = bookingModel.value.type;
            if (bType == 'logistics' || bType == 'shuttle') {
              transportMode.value = foundBookingMap['vehicleType']?.toString() ?? foundBookingMap['rideMode']?.toString() ?? 'Train';
              helperCount.value = foundBookingMap['helperCount'] is int ? foundBookingMap['helperCount'] : int.tryParse(foundBookingMap['helperCount']?.toString() ?? '0') ?? 0;

              vehiclePriceController.text = (foundBookingMap['vehiclePrice'] ?? foundBookingMap['fare'] ?? '0').toString();
              helperCostController.text = (foundBookingMap['helperCost'] ?? '0').toString();
              tollChargesController.text = (foundBookingMap['tollCharges'] ?? '0').toString();
              nightChargesController.text = (foundBookingMap['nightCharges'] ?? '0').toString();
              handlingChargesController.text = (foundBookingMap['handlingCharges'] ?? '0').toString();
              discountController.text = (foundBookingMap['discountAmount'] ?? foundBookingMap['discount'] ?? '0').toString();

              totalPrice.value = double.tryParse((foundBookingMap['totalPrice'] ?? '0').toString()) ?? 0.0;

              // --- Parse pickup address ---
              final pickupRaw = foundBookingMap['pickup'];
              if (pickupRaw is Map) {
                pickupText.value = pickupRaw['address']?.toString() ?? pickupRaw['name']?.toString() ?? '';
              } else {
                pickupText.value = pickupRaw?.toString() ?? bookingModel.value.pickUpLocationAddress ?? '';
              }

              // --- Parse dropoff address ---
              final dropRaw = foundBookingMap['dropoff'];
              if (dropRaw is Map) {
                dropText.value = dropRaw['address']?.toString() ?? dropRaw['name']?.toString() ?? '';
              } else {
                dropText.value = dropRaw?.toString() ?? bookingModel.value.dropLocationAddress ?? '';
              }

              // --- Customer name + phone ---
              final uName = foundBookingMap['userName']?.toString() ?? '';
              final uPhone = foundBookingMap['userPhone']?.toString() ?? '';
              customerText.value = uName.isNotEmpty
                  ? (uPhone.isNotEmpty ? '$uName • $uPhone' : uName)
                  : (uPhone.isNotEmpty ? uPhone : '-');

              // --- Items count ---
              final itemsList = foundBookingMap['items'];
              itemsCount.value = itemsList is List ? itemsList.length : 0;

              // --- Roadmap status ---
              final rmStatus = foundBookingMap['roadmapStatus']?.toString() ?? 'draft';
              roadmapStatusText.value = rmStatus.toUpperCase();

              // --- Populate existing Roadmap Segments ---
              segments.clear();
              final segList = foundBookingMap['segments'];
              if (segList is List && segList.isNotEmpty) {
                isRoadmapSaved.value = true;
                for (var s in segList) {
                  if (s is Map) {
                    final fromStr = s['start'] is Map ? (s['start']['address'] ?? s['start']['name'] ?? '') : (s['start']?.toString() ?? '');
                    final toStr = s['end'] is Map ? (s['end']['address'] ?? s['end']['name'] ?? '') : (s['end']?.toString() ?? '');
                    final modeStr = s['mode']?.toString() ?? 'Road';
                    final dateStr = s['estimatedDate']?.toString() ?? '';
                    final timeStr = s['estimatedTime']?.toString() ?? '';
                    final priceStr = (s['price'] ?? s['segmentPrice'] ?? 0).toString();

                    String driverIdStr = '';
                    String driverNameStr = '';
                    if (s['driverId'] is Map) {
                      driverIdStr = s['driverId']['_id']?.toString() ?? s['driverId']['id']?.toString() ?? '';
                      driverNameStr = s['driverId']['fullName']?.toString() ?? s['driverId']['name']?.toString() ?? '';
                    } else if (s['driverId'] != null) {
                      driverIdStr = s['driverId'].toString();
                    }

                    final seg = RoadmapSegment(
                      fromController: TextEditingController(text: fromStr),
                      toController: TextEditingController(text: toStr),
                      dateController: TextEditingController(text: dateStr),
                      timeController: TextEditingController(text: timeStr),
                      priceController: TextEditingController(text: priceStr),
                      mode: modeStr.obs,
                    );
                    if (driverIdStr.isNotEmpty) {
                      seg.assignedDriverId.value = driverIdStr;
                      seg.assignedDriverName.value = driverNameStr.isNotEmpty ? driverNameStr : 'Driver Assigned';
                    }
                    segments.add(seg);
                  }
                }
              }
            }

            if (foundBookingMap['userId'] is Map) {
              userModel.value = UserModel.fromJson(foundBookingMap['userId']);
            } else if (bookingModel.value.customerId != null && bookingModel.value.customerId!.isNotEmpty) {
              final userUri = Uri.parse("${ApiConstant.adminUsers}/${bookingModel.value.customerId}");
              final userResponse = await http.get(userUri, headers: ApiConstant.headers(token: token));
              if (userResponse.statusCode == 200) {
                final userJson = jsonDecode(userResponse.body);
                if (userJson['success'] == true && userJson['user'] != null) {
                  userModel.value = UserModel.fromJson(userJson['user']);
                }
              }
            }

            if (foundBookingMap['driverId'] is Map) {
              driverModel.value = DriverUserModel.fromJson(foundBookingMap['driverId']);
            } else if (bookingModel.value.driverId != null && bookingModel.value.driverId!.isNotEmpty) {
              final driverUri = Uri.parse("${ApiConstant.adminDrivers}/${bookingModel.value.driverId}");
              final driverResponse = await http.get(driverUri, headers: ApiConstant.headers(token: token));
              if (driverResponse.statusCode == 200) {
                final driverJson = jsonDecode(driverResponse.body);
                if (driverJson['success'] == true && driverJson['driver'] != null) {
                  driverModel.value = DriverUserModel.fromJson(driverJson['driver']);
                }
              }
            }
          }
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      developer.log("Error in getArgument: $e");
    }
  }

  void recalculateTotal() {
    double vPrice = double.tryParse(vehiclePriceController.text) ?? 0.0;
    double hCost = double.tryParse(helperCostController.text) ?? 0.0;
    double toll = double.tryParse(tollChargesController.text) ?? 0.0;
    double night = double.tryParse(nightChargesController.text) ?? 0.0;
    double handling = double.tryParse(handlingChargesController.text) ?? 0.0;
    double disc = double.tryParse(discountController.text) ?? 0.0;

    totalPrice.value = vPrice + hCost + toll + night + handling - disc;
  }

  Future<void> saveGoodsDetails() async {
    isLoading.value = true;
    try {
      String? bookingId = bookingModel.value.id;
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/supervisor/bookings/$bookingId/goods");

      final body = jsonEncode({
        "vehicleType": transportMode.value,
        "helperCount": helperCount.value,
      });

      final response = await http.patch(uri, headers: ApiConstant.headers(token: token), body: body);
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Goods details updated successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        await getArgument(); // Reload
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar("Error", err['message'] ?? "Failed to update goods details.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePricingOverride() async {
    isLoading.value = true;
    try {
      String? bookingId = bookingModel.value.id;
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/supervisor/bookings/$bookingId/pricing-override");

      final body = jsonEncode({
        "vehiclePrice": double.tryParse(vehiclePriceController.text) ?? 0.0,
        "helperCost": double.tryParse(helperCostController.text) ?? 0.0,
        "tollCharges": double.tryParse(tollChargesController.text) ?? 0.0,
        "nightCharges": double.tryParse(nightChargesController.text) ?? 0.0,
        "handlingCharges": double.tryParse(handlingChargesController.text) ?? 0.0,
        "discountAmount": double.tryParse(discountController.text) ?? 0.0,
        "totalPrice": totalPrice.value,
      });

      final response = await http.patch(uri, headers: ApiConstant.headers(token: token), body: body);
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Pricing overridden successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        await getArgument(); // Reload
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar("Error", err['message'] ?? "Failed to override pricing.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBooking() async {
    isAcceptingBooking.value = true;
    try {
      String? bookingId = bookingModel.value.id;
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.baseUrl}/admin/supervisor/bookings/$bookingId/approve");

      final body = jsonEncode({
        "estimatedTime": "12:00 PM",
        "estimatedDate": "Today",
      });

      final response = await http.patch(uri, headers: ApiConstant.headers(token: token), body: body);
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Booking approved successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        await getArgument(showLoading: false); // Reload detail view without full spinner
        if (Get.isRegistered<CabBookingController>()) {
          Get.find<CabBookingController>().getBookings();
        }
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar("Error", err['message'] ?? "Failed to approve booking.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isAcceptingBooking.value = false;
    }
  }

  // Safe Getters for view
  String get bookingIdText {
    final id = bookingModel.value.id ?? '';
    return id.length >= 8 ? id.substring(0, 8) : id;
  }

  Timestamp get createAtTime {
    return bookingModel.value.createAt ?? Timestamp.now();
  }

  Timestamp get bookingTimeVal {
    return bookingModel.value.bookingTime ?? Timestamp.now();
  }

  String get vehicleImage {
    return bookingModel.value.vehicleType?.image ?? '';
  }

  String get vehicleTitle {
    return bookingModel.value.vehicleType?.title ?? '';
  }

  String get vehiclePersons {
    return bookingModel.value.vehicleType?.persons.toString() ?? '0';
  }

  String get distanceText {
    return bookingModel.value.distance?.distance ?? '0';
  }

  String get distanceUnit {
    return bookingModel.value.distance?.distanceType ?? 'km';
  }

  int get taxListLength {
    return bookingModel.value.taxList?.length ?? 0;
  }
}

class RoadmapSegment {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController priceController;
  final RxString mode;
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final RxString assignedDriverId = ''.obs;
  final RxString assignedDriverName = ''.obs;

  RoadmapSegment({
    required this.fromController,
    required this.toController,
    required this.dateController,
    required this.timeController,
    required this.priceController,
    required this.mode,
  });
}
