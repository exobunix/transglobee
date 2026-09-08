import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import '../../providers/logistics_vehicle_provider.dart';
import 'logistics_booking_screen.dart';
import '../../providers/logistics_booking_state.dart';
import '../../providers/logistics_booking_notifier.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';

mixin LogisticsBookingHandlers on ConsumerState<LogisticsBookingScreen> {
  // Access state and notifier
  LogisticsBookingState get state => ref.watch(logisticsBookingProvider);
  LogisticsBookingNotifier get notifier => ref.read(logisticsBookingProvider.notifier);

  // Getters/setters mapping to notifier
  UserRoute? get selectedRoute => state.selectedRoute;
  set selectedRoute(UserRoute? val) => notifier.selectRoute(val);

  String? get selectedVehicle => state.selectedVehicle;
  set selectedVehicle(String? val) => notifier.selectVehicle(val, selectedVehicleData);

  LogisticsVehicle? get selectedVehicleData => state.selectedVehicleData;
  set selectedVehicleData(LogisticsVehicle? val) => notifier.selectVehicle(selectedVehicle, val);

  double get helperCostPerPerson => notifier.helperCostPerPerson;
  int get helperCount => state.helperCount;
  set helperCount(int val) => notifier.setHelperCount(val);

  Map<String, dynamic>? get pickup => state.pickup;
  set pickup(Map<String, dynamic>? val) {
    if (val == null) return;
    notifier.selectSuggestion({
      'name': val['name'],
      'address': val['address'],
      'place_id': val['place_id'] ?? '',
      'lat': val['lat'],
      'lng': val['lng'],
    }, true);
  }

  Map<String, dynamic>? get dropoff => state.dropoff;
  set dropoff(Map<String, dynamic>? val) {
    if (val == null) return;
    notifier.selectSuggestion({
      'name': val['name'],
      'address': val['address'],
      'place_id': val['place_id'] ?? '',
      'lat': val['lat'],
      'lng': val['lng'],
    }, false);
  }

  List<LatLng> get routePoints => state.routePoints;
  double get distance => state.distance;

  String? get appliedCoupon => state.appliedCoupon;
  double get discountAmount => state.discountAmount;

  AddressEntry? get selectedPickupAddress => state.selectedPickupAddress;
  set selectedPickupAddress(AddressEntry? val) => notifier.selectPickupAddress(val);

  AddressEntry? get selectedDeliveryAddress => state.selectedDropoffAddress;
  set selectedDeliveryAddress(AddressEntry? val) => notifier.selectDropoffAddress(val);

  bool get isAddingItem => state.isAddingItem;
  bool get isSavingGood => state.isBooking;
  set isSavingGood(bool val) => notifier.setBooking(val);

  // In-page search state & controllers
  final pickupSearchController = TextEditingController();
  final dropoffSearchController = TextEditingController();
  final pickupFocusNode = FocusNode();
  final dropoffFocusNode = FocusNode();
  final goodTypeController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  Timer? debounce;
  bool showSuggestions = false;
  bool activeSearchingPickup = true;

  // Custom Local date/time to align with mockup
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:30 AM - 11:00 AM';

  void initHandlers() {
    pickupFocusNode.addListener(onFocusChanged);
    dropoffFocusNode.addListener(onFocusChanged);
  }

  void disposeHandlers() {
    debounce?.cancel();
    pickupSearchController.dispose();
    dropoffSearchController.dispose();
    pickupFocusNode.removeListener(onFocusChanged);
    dropoffFocusNode.removeListener(onFocusChanged);
    pickupFocusNode.dispose();
    dropoffFocusNode.dispose();
    goodTypeController.dispose();
  }

  void onFocusChanged() {
    if (!mounted) return;
    setState(() {
      if (pickupFocusNode.hasFocus) {
        activeSearchingPickup = true;
        showSuggestions = true;
      } else if (dropoffFocusNode.hasFocus) {
        activeSearchingPickup = false;
        showSuggestions = true;
      } else {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !pickupFocusNode.hasFocus && !dropoffFocusNode.hasFocus) {
            setState(() => showSuggestions = false);
          }
        });
      }
    });
  }

  Future<void> fetchSuggestions(String query) async {
    await notifier.fetchSuggestions(query);
    if (mounted) {
      setState(() {
        searchResults = state.suggestions.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> selectSuggestion(Map<String, dynamic> suggestion, bool isPickup) async {
    await notifier.selectSuggestion(suggestion, isPickup);
    if (mounted) {
      setState(() {
        showSuggestions = false;
        if (isPickup) {
          pickupSearchController.text = "${suggestion['name']}, ${suggestion['address']}";
          pickupFocusNode.unfocus();
        } else {
          dropoffSearchController.text = "${suggestion['name']}, ${suggestion['address']}";
          dropoffFocusNode.unfocus();
        }
        searchResults = [];
      });
    }
  }

  Future<void> fetchRoute() async {
    await notifier.fetchRoute();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String? validateBookingInputs() {
    if (selectedRoute == null) {
      return 'Please select an assigned route first';
    }
    if (selectedVehicleData == null) {
      return 'Please select a vehicle before booking';
    }
    if (pickup == null || dropoff == null) {
      return 'Please select both pickup and drop locations on the map';
    }
    if ((pickup?['address']?.toString().trim().toLowerCase() ?? '') ==
        (dropoff?['address']?.toString().trim().toLowerCase() ?? '')) {
      return 'Pickup and drop locations must be different';
    }
    if (state.addedItems.isEmpty) {
      return 'Please add at least one item with complete details';
    }

    final pLat = _parseDouble(pickup!['lat']);
    final pLng = _parseDouble(pickup!['lng']);
    final routeStartLat = selectedRoute!.startLat ?? 0.0;
    final routeStartLng = selectedRoute!.startLng ?? 0.0;

    final diffLat = (pLat - routeStartLat).abs();
    final diffLng = (pLng - routeStartLng).abs();
    if (diffLat > 0.01 || diffLng > 0.01) {
      return 'Pickup location must match the selected route start location: ${selectedRoute!.startLocation ?? selectedRoute!.name}';
    }

    if (selectedPickupAddress == null) {
      return 'Please select a Pickup Address from your address book (tap "Pickup Address" below)';
    }
    if (selectedPickupAddress!.type != 'pickup') {
      return 'The selected pickup address is not of type "Pickup". Please choose a valid pickup address';
    }
    if (selectedDeliveryAddress == null) {
      return 'Please select a Delivery Address from your address book (tap "Delivery Address" below)';
    }
    if (selectedDeliveryAddress!.type != 'received') {
      return 'The selected delivery address is not of type "Received". Please choose a valid delivery address';
    }
    return null;
  }

  Map<String, dynamic>? buildValidatedPickupAddressPayload() {
    if (selectedPickupAddress == null || pickup == null) return null;

    return {
      'type': 'pickup',
      'label': selectedPickupAddress!.label,
      'fullAddress': pickup!['address'],
      'houseNumber': selectedPickupAddress!.houseNumber,
      'floorNumber': selectedPickupAddress!.floorNumber,
      'landmark': selectedPickupAddress!.landmark,
      'city': selectedPickupAddress!.city,
      'pincode': selectedPickupAddress!.pincode,
      'phone': selectedPickupAddress!.phone,
      'email': selectedPickupAddress!.email,
    };
  }

  Map<String, dynamic>? buildValidatedReceivedAddressPayload() {
    if (selectedDeliveryAddress == null || dropoff == null) return null;

    return {
      'type': 'received',
      'label': selectedDeliveryAddress!.label,
      'fullAddress': dropoff!['address'],
      'houseNumber': selectedDeliveryAddress!.houseNumber,
      'floorNumber': selectedDeliveryAddress!.floorNumber,
      'landmark': selectedDeliveryAddress!.landmark,
      'city': selectedDeliveryAddress!.city,
      'pincode': selectedDeliveryAddress!.pincode,
      'phone': selectedDeliveryAddress!.phone,
      'email': selectedDeliveryAddress!.email,
    };
  }

  Future<String> saveLogisticsBooking({
    required String goodTypeName,
    Map<String, dynamic>? pickupAddress,
    Map<String, dynamic>? receivedAddress,
  }) async {
    await notifier.bookLogisticsRide();
    if (state.errorMessage != null) {
      throw Exception(state.errorMessage);
    }
    return state.bookingSuccessId ?? '';
  }

  String getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0F5A3B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectTime() async {
    final List<String> timeSlots = [
      '08:00 AM - 09:00 AM',
      '09:00 AM - 10:00 AM',
      '10:30 AM - 11:00 AM',
      '11:00 AM - 12:00 PM',
      '12:00 PM - 01:00 PM',
      '01:00 PM - 02:00 PM',
      '02:00 PM - 03:00 PM',
      '03:00 PM - 04:00 PM',
      '04:00 PM - 05:00 PM',
      '05:00 PM - 06:00 PM',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            'Select Pickup Time Slot',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          children: timeSlots.map((slot) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, slot),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(slot, style: TextStyle(fontSize: 14.sp)),
              ),
            );
          }).toList(),
        );
      },
    );
    if (selected != null) {
      setState(() {
        selectedTime = selected;
      });
    }
  }

  void showAssignedRoutesBottomSheet(List<UserRoute> assignedRoutes) {
    if (assignedRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assigned routes available.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Assigned Route',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assignedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = assignedRoutes[index];
                    final isSelected = selectedRoute?.id == route.id;
                    return ListTile(
                      leading: Icon(
                        Icons.route_outlined,
                        color: isSelected ? const Color(0xFF0F5A3B) : Colors.grey,
                      ),
                      title: Text(
                        route.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF0F5A3B) : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF0F5A3B))
                          : null,
                      onTap: () {
                        setState(() {
                          selectedRoute = route;
                          final pickupAddress =
                              route.startLocation ??
                              route.source ??
                              route.name.split(' to ')[0];
                          pickup = {
                            'name': route.source ?? route.name.split(' to ')[0],
                            'address': pickupAddress,
                            'lat': route.startLat ?? 0.0,
                            'lng': route.startLng ?? 0.0,
                          };
                          pickupSearchController.text = pickupAddress;

                          final dropoffAddress =
                              route.endLocation ??
                              route.destination ??
                              route.name.split(' to ').last;
                          dropoff = {
                            'name': route.destination ?? route.name.split(' to ').last,
                            'address': dropoffAddress,
                            'lat': route.endLat ?? 0.0,
                            'lng': route.endLng ?? 0.0,
                          };
                          dropoffSearchController.text = dropoffAddress;

                          selectedVehicle = null;
                          selectedVehicleData = null;
                        });
                        fetchRoute();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
