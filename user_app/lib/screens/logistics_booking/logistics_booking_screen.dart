import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';
import '../../providers/logistics_booking_state.dart';
import '../../providers/logistics_booking_notifier.dart';
import '../../providers/logistics_vehicle_provider.dart';
import '../../providers/user_provider.dart';
import '../address_book_screen.dart';
import '../my_logistics_bookings_screen.dart';
import '../support_screen.dart';
import 'widgets/step_tracker.dart';
import 'widgets/address_selector_widget.dart';
import 'widgets/coupon_bottom_sheet.dart';
import 'widgets/logistics_item_form.dart';
import 'widgets/logistics_map_section.dart';
import 'widgets/location_input_section.dart';
import 'widgets/vehicle_selector.dart';
import 'booking_logic_mixin.dart';

typedef _ItemEntry = LogisticsItemEntry;

class LogisticsBookingScreen extends ConsumerStatefulWidget {
  const LogisticsBookingScreen({super.key});

  @override
  ConsumerState<LogisticsBookingScreen> createState() =>
      _LogisticsBookingScreenState();
}

class _LogisticsBookingScreenState
    extends ConsumerState<LogisticsBookingScreen> with LogisticsBookingHandlers {
  LogisticsBookingState get _state => state;
  LogisticsBookingNotifier get _notifier => notifier;

  List<_ItemEntry> get _addedItems => state.addedItems;
  Future<void> _saveAllItemsAndBook(String goodTypeName) async {}

  UserRoute? get _selectedRoute => selectedRoute;
  set _selectedRoute(UserRoute? val) => selectedRoute = val;

  String? get _selectedVehicle => selectedVehicle;
  set _selectedVehicle(String? val) => selectedVehicle = val;

  LogisticsVehicle? get _selectedVehicleData => selectedVehicleData;
  set _selectedVehicleData(LogisticsVehicle? val) => selectedVehicleData = val;

  double get _helperCostPerPerson => helperCostPerPerson;
  int get _helperCount => helperCount;
  set _helperCount(int val) => helperCount = val;

  Map<String, dynamic>? get _pickup => pickup;
  set _pickup(Map<String, dynamic>? val) => pickup = val;

  Map<String, dynamic>? get _dropoff => dropoff;
  set _dropoff(Map<String, dynamic>? val) => dropoff = val;

  List<LatLng> get _routePoints => routePoints;
  double get _distance => distance;

  String? get _appliedCoupon => appliedCoupon;
  double get _discountAmount => discountAmount;

  AddressEntry? get _selectedPickupAddress => selectedPickupAddress;
  set _selectedPickupAddress(AddressEntry? val) => selectedPickupAddress = val;

  AddressEntry? get _selectedDeliveryAddress => selectedDeliveryAddress;
  set _selectedDeliveryAddress(AddressEntry? val) => selectedDeliveryAddress = val;

  bool get _isAddingItem => isAddingItem;
  bool get _isSavingGood => isSavingGood;
  set _isSavingGood(bool val) => isSavingGood = val;

  TextEditingController get _pickupSearchController => pickupSearchController;
  TextEditingController get _dropoffSearchController => dropoffSearchController;
  FocusNode get _pickupFocusNode => pickupFocusNode;
  FocusNode get _dropoffFocusNode => dropoffFocusNode;
  TextEditingController get _goodTypeController => goodTypeController;

  List<Map<String, dynamic>> get _searchResults => searchResults;
  // set _searchResults(List<Map<String, dynamic>> val) => searchResults = val;

  Timer? get _debounce => debounce;
  set _debounce(Timer? val) => debounce = val;

  bool get _showSuggestions => showSuggestions;
  // set _showSuggestions(bool val) => showSuggestions = val;

  bool get _activeSearchingPickup => activeSearchingPickup;
  // set _activeSearchingPickup(bool val) => activeSearchingPickup = val;

  DateTime get _selectedDate => selectedDate;
  // set _selectedDate(DateTime val) => selectedDate = val;

  String get _selectedTime => selectedTime;
  // set _selectedTime(String val) => selectedTime = val;

  @override
  void initState() {
    super.initState();
    initHandlers();
  }

  @override
  void dispose() {
    disposeHandlers();
    super.dispose();
  }



  double get _vehiclePrice => _notifier.vehiclePrice;
  double get _helperCost => _notifier.helperCost;
  double get _totalPrice => _notifier.totalPrice;

  // Future<void> _fetchRoute() => fetchRoute();
  String? _validateBookingInputs() => validateBookingInputs();
  Map<String, dynamic>? _buildValidatedPickupAddressPayload() => buildValidatedPickupAddressPayload();
  Map<String, dynamic>? _buildValidatedReceivedAddressPayload() => buildValidatedReceivedAddressPayload();
  Future<String> _saveLogisticsBooking({
    required String goodTypeName,
    Map<String, dynamic>? pickupAddress,
    Map<String, dynamic>? receivedAddress,
  }) => saveLogisticsBooking(goodTypeName: goodTypeName, pickupAddress: pickupAddress, receivedAddress: receivedAddress);
  // String _getMonthName(int month) => getMonthName(month);
  // Future<void> _selectDate() => selectDate();
  // Future<void> _selectTime() => selectTime();
  void _showAssignedRoutesBottomSheet(List<UserRoute> assignedRoutes) => showAssignedRoutesBottomSheet(assignedRoutes);

  int _getCurrentStep() {
    if (_pickup == null || _dropoff == null) return 1;
    if (_selectedVehicle == null) return 2;
    if (_addedItems.isEmpty) return 3;
    return 4;
  }




  @override
  Widget build(BuildContext context) {
    // final typeGoodsAsync = ref.watch(typeGoodsProvider);
    final vehiclesAsync = ref.watch(logisticsVehiclesProvider);
    final userAsync = ref.watch(fullUserProfileProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: context.colors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Book Logistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  'Fast • Reliable • Secure',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    Icons.headset_mic_outlined,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 38,
                    height: 38,
                    child: ClipOval(
                      child: Image.network(
                        'https://randomuser.me/api/portraits/men/47.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 18,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepTracker(currentStep: _getCurrentStep()),

                  // ── Select Route Section ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.route_outlined,
                              color: Color(0xFF0F5A3B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Select Route',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            final assignedRoutes = userAsync.value?.assignedRoutes ?? [];
                            _showAssignedRoutesBottomSheet(assignedRoutes);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF0F5A3B)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_border,
                                  color: Color(0xFF0F5A3B),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'My Routes',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F5A3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Map Section ──────────────────────────────────────
                  LogisticsMapSection(
                    pickup: _pickup,
                    dropoff: _dropoff,
                    routePoints: _routePoints,
                  ),

                  // ── Address Selection & Date/Time ────────────────────
                  LocationInputSection(
                    pickupSearchController: _pickupSearchController,
                    dropoffSearchController: _dropoffSearchController,
                    pickupFocusNode: _pickupFocusNode,
                    dropoffFocusNode: _dropoffFocusNode,
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    showSuggestions: _showSuggestions,
                    searchResults: _searchResults,
                    activeSearchingPickup: _activeSearchingPickup,
                    pickup: _pickup,
                    dropoff: _dropoff,
                    selectedRoute: _selectedRoute,
                    onSwapLocations: () {
                      final tempText = _pickupSearchController.text;
                      _pickupSearchController.text = _dropoffSearchController.text;
                      _dropoffSearchController.text = tempText;
                      final tempLoc = _pickup;
                      _pickup = _dropoff;
                      _dropoff = tempLoc;
                    },
                    onSelectDate: selectDate,
                    onSelectTime: selectTime,
                    onSearchChanged: (val) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 500),
                        () => fetchSuggestions(val),
                      );
                    },
                    onSuggestionTapped: selectSuggestion,
                  ),

                  // ── Select Vehicle Type ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Vehicle Type',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          'View All Vehicles >',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5A3B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: VehicleSelector(
                      vehiclesAsync: vehiclesAsync,
                      selectedRoute: _selectedRoute,
                      selectedVehicle: _selectedVehicle,
                      onVehicleSelected: (vehicle) {
                        setState(() {
                          _selectedVehicle = vehicle.name;
                          _selectedVehicleData = vehicle;
                        });
                      },
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: _helperCount > 0
                            ? const Color(0xFF0F5A3B).withValues(alpha: 0.3)
                            : Colors.grey.shade200,
                        width: _helperCount > 0 ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (_helperCount > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 5,
                              child: Container(
                                color: const Color(0xFF0F5A3B),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5A3B).withValues(
                                      alpha: _helperCount > 0 ? 0.15 : 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.group_outlined,
                                    color: _helperCount > 0
                                        ? const Color(0xFF0F5A3B)
                                        : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Need Loading/Unloading Help?',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add helpers to assist with your goods',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${_helperCostPerPerson.toInt()} per helper',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F5A3B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: _helperCount > 0
                                            ? () => setState(
                                                  () => _helperCount--,
                                                )
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _helperCount > 0
                                                ? Colors.white
                                                : Colors.transparent,
                                            boxShadow: _helperCount > 0
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: _helperCount > 0
                                                ? const Color(0xFF0F5A3B)
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          '$_helperCount',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: _helperCount > 0
                                                ? const Color(0xFF0F5A3B)
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                              () => _helperCount++,
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF0F5A3B),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0F5A3B)
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'Type of Goods',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _goodTypeController,
                      decoration: InputDecoration(
                        hintText:
                            'Enter type of goods (e.g., Furniture, Electronics)',
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),

                  // ── Item Details Form ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Add Items',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (_addedItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5A3B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_addedItems.length} added',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_addedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ..._addedItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0F5A3B,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF0F5A3B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.type} · ${item.length}×${item.height}×${item.width} ${item.unit}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _notifier.removeAddedItem(idx),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: LogisticsItemForm(
                      isAddingItem: _isAddingItem,
                      goodType: _goodTypeController.text.trim(),
                      onAddItem: ({
                        required name,
                        required length,
                        required height,
                        required width,
                        required unit,
                      }) async {
                        _notifier.setUnit(unit);
                        String goodTypeName = _goodTypeController.text.trim();
                        if (goodTypeName.isEmpty) goodTypeName = 'General';
                        await _notifier.addItemToList(
                          name: name,
                          goodTypeName: goodTypeName,
                          length: length,
                          height: height,
                          width: width,
                          imageBytes: null,
                          imageName: null,
                        );
                      },
                    ),
                  ),

                  // ── Pickup & Delivery Address Selector ───────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: AddressSelectorWidget(
                      title: 'Pickup Address',
                      subtitle: 'Select saved home/office address',
                      selected: _selectedPickupAddress,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressBookScreen(
                            onSelect: (addr) =>
                                setState(() => _selectedPickupAddress = addr),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: AddressSelectorWidget(
                      title: 'Delivery Address',
                      subtitle: 'Select saved destination address',
                      selected: _selectedDeliveryAddress,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressBookScreen(
                            onSelect: (addr) =>
                                setState(() => _selectedDeliveryAddress = addr),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
      

          // ── Footer ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Estimated Total',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                size: 14.sp,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_totalPrice.toInt()}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F5A3B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Including all charges',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      GestureDetector(
                        onTap: _showCouponBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF0F5A3B)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                color: Color(0xFF0F5A3B),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _appliedCoupon != null
                                    ? _appliedCoupon!
                                    : 'Apply Coupon',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F5A3B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        (_pickup != null &&
                            _dropoff != null &&
                            _addedItems.isNotEmpty)
                        ? () async {
                            final bookingValidationError =
                                _validateBookingInputs();
                            if (bookingValidationError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(bookingValidationError)),
                              );
                              return;
                            }

                            String goodTypeName = _goodTypeController.text
                                .trim();
                            if (goodTypeName.isEmpty) goodTypeName = 'General';

                            try {
                              setState(() => _isSavingGood = true);
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              await _saveAllItemsAndBook(goodTypeName);

                              await _saveLogisticsBooking(
                                goodTypeName: goodTypeName,
                                pickupAddress:
                                    _buildValidatedPickupAddressPayload(),
                                receivedAddress:
                                    _buildValidatedReceivedAddressPayload(),
                              );

                              if (mounted) {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '🎉 Logistics booking successful! Redirecting to your bookings...',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );

                                await Future.delayed(
                                  const Duration(seconds: 3),
                                );

                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyLogisticsBookingsScreen(),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Booking failed: $e')),
                                );
                              }
                            } finally {
                              if (mounted)
                                setState(() => _isSavingGood = false);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5A3B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSavingGood
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _addedItems.isEmpty
                                    ? 'Add at least 1 item to book'
                                    : 'Continue',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CouponBottomSheet(
        basePrice: _vehiclePrice + _helperCost,
        appliedCoupon: _appliedCoupon,
        onCouponApplied: (code, discount) {
          _notifier.setCoupon(code, discount);
        },
      ),
    );
  }
}
