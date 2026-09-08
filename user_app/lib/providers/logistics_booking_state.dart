import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import 'logistics_vehicle_provider.dart';

class LogisticsItemEntry {
  String name;
  String type;
  double length;
  double height;
  double width;
  String unit;
  Uint8List? imageBytes;
  String? imageName;
  String? savedImageUrl; // After ImageKit upload

  LogisticsItemEntry({
    required this.name,
    required this.type,
    this.length = 0,
    this.height = 0,
    this.width = 0,
    this.unit = 'cm',
    this.imageBytes,
    this.imageName,
    this.savedImageUrl,
  });

  LogisticsItemEntry copyWith({
    String? name,
    String? type,
    double? length,
    double? height,
    double? width,
    String? unit,
    Uint8List? imageBytes,
    String? imageName,
    String? savedImageUrl,
  }) {
    return LogisticsItemEntry(
      name: name ?? this.name,
      type: type ?? this.type,
      length: length ?? this.length,
      height: height ?? this.height,
      width: width ?? this.width,
      unit: unit ?? this.unit,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      savedImageUrl: savedImageUrl ?? this.savedImageUrl,
    );
  }
}

class LogisticsBookingState {
  final UserRoute? selectedRoute;
  final String? selectedVehicle;
  final LogisticsVehicle? selectedVehicleData;
  final String? selectedGoodType;
  final List<LogisticsItemEntry> addedItems;
  final String selectedUnit;
  final bool isAddingItem;
  final int helperCount;
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;
  final List<LatLng> routePoints;
  final double distance;
  final String? appliedCoupon;
  final double discountAmount;
  final AddressEntry? selectedPickupAddress;
  final AddressEntry? selectedDropoffAddress;
  
  // API Fetch states
  final List<dynamic> suggestions;
  final bool isFetchingRoute;
  final bool isBooking;
  final bool isFetchingSuggestions;
  final String? errorMessage;
  final String? bookingSuccessId;

  LogisticsBookingState({
    this.selectedRoute,
    this.selectedVehicle,
    this.selectedVehicleData,
    this.selectedGoodType,
    this.addedItems = const [],
    this.selectedUnit = 'cm',
    this.isAddingItem = false,
    this.helperCount = 0,
    this.pickup,
    this.dropoff,
    this.routePoints = const [],
    this.distance = 0.0,
    this.appliedCoupon,
    this.discountAmount = 0.0,
    this.selectedPickupAddress,
    this.selectedDropoffAddress,
    this.suggestions = const [],
    this.isFetchingRoute = false,
    this.isBooking = false,
    this.isFetchingSuggestions = false,
    this.errorMessage,
    this.bookingSuccessId,
  });

  LogisticsBookingState copyWith({
    UserRoute? Function()? selectedRoute,
    String? Function()? selectedVehicle,
    LogisticsVehicle? Function()? selectedVehicleData,
    String? Function()? selectedGoodType,
    List<LogisticsItemEntry>? addedItems,
    String? selectedUnit,
    bool? isAddingItem,
    int? helperCount,
    Map<String, dynamic>? Function()? pickup,
    Map<String, dynamic>? Function()? dropoff,
    List<LatLng>? routePoints,
    double? distance,
    String? Function()? appliedCoupon,
    double? discountAmount,
    AddressEntry? Function()? selectedPickupAddress,
    AddressEntry? Function()? selectedDropoffAddress,
    List<dynamic>? suggestions,
    bool? isFetchingRoute,
    bool? isBooking,
    bool? isFetchingSuggestions,
    String? Function()? errorMessage,
    String? Function()? bookingSuccessId,
  }) {
    return LogisticsBookingState(
      selectedRoute: selectedRoute != null ? selectedRoute() : this.selectedRoute,
      selectedVehicle: selectedVehicle != null ? selectedVehicle() : this.selectedVehicle,
      selectedVehicleData: selectedVehicleData != null ? selectedVehicleData() : this.selectedVehicleData,
      selectedGoodType: selectedGoodType != null ? selectedGoodType() : this.selectedGoodType,
      addedItems: addedItems ?? this.addedItems,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      helperCount: helperCount ?? this.helperCount,
      pickup: pickup != null ? pickup() : this.pickup,
      dropoff: dropoff != null ? dropoff() : this.dropoff,
      routePoints: routePoints ?? this.routePoints,
      distance: distance ?? this.distance,
      appliedCoupon: appliedCoupon != null ? appliedCoupon() : this.appliedCoupon,
      discountAmount: discountAmount ?? this.discountAmount,
      selectedPickupAddress: selectedPickupAddress != null ? selectedPickupAddress() : this.selectedPickupAddress,
      selectedDropoffAddress: selectedDropoffAddress != null ? selectedDropoffAddress() : this.selectedDropoffAddress,
      suggestions: suggestions ?? this.suggestions,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      isBooking: isBooking ?? this.isBooking,
      isFetchingSuggestions: isFetchingSuggestions ?? this.isFetchingSuggestions,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      bookingSuccessId: bookingSuccessId != null ? bookingSuccessId() : this.bookingSuccessId,
    );
  }
}
