import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'ride_tracking_screen.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../providers/user_provider.dart';
import 'searching_ride_screen.dart';
import '../services/rest_api_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shimmer_loading.dart';
import '../providers/api_state_providers.dart';


class RideBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final String serviceType;

  const RideBookingScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.serviceType,
  });

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  String _selectedVehicle = 'economy';
  String _paymentMode = 'cash'; // New payment state
  bool _isSearching = false;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDurationMin = 0.0;
  List<Map<String, dynamic>> _dynamicVehicles = [];
  bool _isFetchingPricing = false;
  bool _isRouteLoading = true;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _connectionSub;
  String? _currentRideId;
  String? _currentOtp;
  String? _appliedCoupon;
  double _discountAmount = 0.0;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first['id'];
    }

    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
    );

    _routePoints = [pickupPos, dropoffPos];

    _loadRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = ref.read(authServiceProvider);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fitBounds();
      });
      
      // Connect socket
      await authService.waitForSession();
      if (!mounted) return;

      final socketService = ref.read(socketServiceProvider);
      final userProfile = ref.read(fullUserProfileProvider).value;
      final userId = userProfile?.id; // This is the MongoDB _id
      final userName = userProfile?.name;
      
      if (userId != null && userId.isNotEmpty) {
        socketService.connect(userId, name: userName);
      } else {
        // Fallback to Firebase UID if MongoDB ID is not available yet
        final firebaseId = authService.currentUser?.uid;
        if (firebaseId != null) {
          socketService.connect(firebaseId, name: userName);
        }
      }

      _connectionSub?.cancel();
      _connectionSub = socketService.connectionSuccessStream.listen((data) {
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
            // SnackBar(
            //   content: Text(data['message'] ?? 'Connected successfully!'),
            //   backgroundColor: Colors.blueAccent,
            //   behavior: SnackBarBehavior.floating,
            //   duration: const Duration(seconds: 2),
            // ),
          // );
        }
      });
    });
  }

  Future<void> _loadRoute() async {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
    );

    try {
      final routeData = await LocationService.getRouteData(pickupPos, dropoffPos);
      if (mounted) {
        setState(() {
          final List<dynamic> rawPoints = routeData['points'] ?? [];
          _routePoints = rawPoints.map((p) => LatLng(p[0], p[1])).toList();
          _routeDistance = routeData['distance'] ?? 0.0;
          _routeDurationMin = routeData['duration'] ?? 0.0;
          _isRouteLoading = false;
        });
        _fitBounds();
        
        if (widget.serviceType != 'truck') {
          _fetchDynamicPricing();
        }
      }
    } catch (e) {
      debugPrint("Error loading route in RideBookingScreen: $e");
      if (mounted) {
        setState(() {
          _isRouteLoading = false;
        });
        _fitBounds();
        if (widget.serviceType != 'truck') {
          _fetchDynamicPricing();
        }
      }
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;

    try {
      // Validate points before creating bounds to prevent crash if coordinates are invalid
      final validPoints = _routePoints.where((p) => 
        p.latitude >= -90 && p.latitude <= 90 && 
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) {
        debugPrint("Not enough valid points to fit bounds");
        return;
      }

      final first = validPoints.first;
      final allIdentical = validPoints.every((p) => p.latitude == first.latitude && p.longitude == first.longitude);
      if (allIdentical) {
        _mapController.move(first, 15.0);
        return;
      }

      final bounds = LatLngBounds.fromPoints(validPoints);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 60,
            bottom: 300, 
            left: 30,
            right: 30,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
  }

  Future<void> _fetchDynamicPricing() async {
    if (mounted) setState(() => _isFetchingPricing = true);
    try {
      final repo = ref.read(restApiRepositoryProvider);
      final response = await repo.estimateFare(
        pickup: {
          'lat': _parseDouble(widget.pickup['lat']),
          'lng': _parseDouble(widget.pickup['lng']),
        },
        dropoff: {
          'lat': _parseDouble(widget.dropoff['lat']),
          'lng': _parseDouble(widget.dropoff['lng']),
        },
        distanceKm: _routeDistance,
        durationMins: _routeDurationMin,
      );
      if (response.success && response.data != null && mounted) {
        final List<dynamic> rides = response.data!['rides'] ?? [];
        setState(() {
          _dynamicVehicles = rides.map((r) => {
            'id': r['id']?.toString() ?? 'economy',
            'name': r['name']?.toString() ?? 'Transglobe',
            'icon': Icons.directions_car,
            'capacity': r['capacity']?.toString() ?? '4',
            'price': (r['estimatedFare'] ?? 0.0).toStringAsFixed(0),
            'eta': '${r['etaMinutes'] ?? 5} min away',
            'time': '${r['arrivalTime'] ?? ''}',
            'baseFare': r['baseFare'],
            'perKmRate': r['perKmRate'],
            'perMinuteRate': r['perMinuteRate'],
            'fareBreakdown': r['fareBreakdown'] ?? {},
          }).toList();
          if (_dynamicVehicles.isNotEmpty) {
            _selectedVehicle = _dynamicVehicles.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching dynamic pricing: $e");
    } finally {
      if (mounted) {
        setState(() => _isFetchingPricing = false);
      }
    }
  }

  List<Map<String, dynamic>> get _vehicles {
    List<Map<String, dynamic>> list;
    if (_dynamicVehicles.isNotEmpty) {
      list = List<Map<String, dynamic>>.from(_dynamicVehicles);
    } else if (widget.serviceType == 'truck') {
      list = [
        {
          'id': 'ace',
          'name': 'Tata Ace',
          'icon': Icons.local_shipping,
          'price': 450,
          'eta': '10 min',
          'time': '10 min',
        },
        {
          'id': 'pickup',
          'name': 'Pickup 8ft',
          'icon': Icons.local_shipping,
          'price': 650,
          'eta': '15 min',
          'time': '15 min',
        },
        {
          'id': '3wheeler',
          'name': '3 Wheeler',
          'icon': Icons.moped,
          'price': 300,
          'eta': '5 min',
          'time': '5 min',
        },
      ];
    } else {
      final now = DateTime.now();
      final durationRounded = _routeDurationMin.round();
      final arrivalTime = now.add(Duration(minutes: durationRounded));
      final timeStr =
          "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";

      final String tripDurationDisplay = durationRounded > 60
          ? "${(durationRounded / 60).floor()}h ${durationRounded % 60}m"
          : "$durationRounded min";

      final int etaVal = (2 + (_routeDistance * 0.4)).round().clamp(2, 10);

      list = [
        {
          'id': 'economy',
          'name': 'Transglobe',
          'icon': Icons.directions_car,
          'capacity': '4',
          'price': (50 + (_routeDistance * 15)).toStringAsFixed(0),
          'eta': '$etaVal min away',
          'time': "$timeStr • $tripDurationDisplay",
        },
      ];
    }

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final userProfile = ref.read(fullUserProfileProvider).value;
    final isLoggedIn = (user != null && userProfile != null);

    if (!isLoggedIn) {
      list = list.where((v) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final id = (v['id'] ?? '').toString().toLowerCase();
        return !name.contains('shuttle') && 
               !name.contains('logistics') && 
               !id.contains('shuttle') && 
               !id.contains('logistics');
      }).toList();
    }

    return list;
  }

  Map<String, dynamic> get _selectedVehicleData {
    return _vehicles.firstWhere(
      (v) => v['id'] == _selectedVehicle,
      orElse: () => _vehicles.first,
    );
  }

  void _showGuestDetailsDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Guest Booking Details",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Please enter your name and phone number to complete the booking.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: "Mobile Number",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.phone),
                    hintText: "e.g., 9876543210",
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your mobile number";
                    }
                    if (val.trim().length != 10) {
                      return "Enter exactly a 10-digit number";
                    }
                    return null;
                  },
                ),
             
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final guestName = nameCtrl.text.trim();
                  final guestPhone = phoneCtrl.text.trim();
                  Navigator.pop(context); // Close dialog
                  _executeBooking(guestName: guestName, guestPhone: guestPhone);
                }
              },
              child: const Text("Confirm & Book"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startBooking() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final userProfile = ref.read(fullUserProfileProvider).value;

    final isLoggedIn = (user != null && userProfile != null) || kDemoMode;

    if (!isLoggedIn) {
      _showGuestDetailsDialog();
      return;
    }

    _executeBooking();
  }

  Future<void> _executeBooking({String? guestName, String? guestPhone}) async {
    setState(() => _isSearching = true);
    
    // Listen for ride acceptance
    _socketSubscription?.cancel();
    _socketSubscription = ref.read(socketServiceProvider).rideAcceptedStream.listen(_handleRideAccepted);

    try {
      final repo = ref.read(restApiRepositoryProvider);
      
      final response = await repo.createBooking({
        'type': 'ride',
        if (guestName != null) 'name': guestName,
        if (guestPhone != null) 'mobileNumber': guestPhone,
        'pickupLocation': {
          'title': widget.pickup['name'] ?? 'Pickup',
          'address': widget.pickup['address'] ?? widget.pickup['name'],
          'latitude': widget.pickup['lat'],
          'longitude': widget.pickup['lng'],
        },
        'dropLocation': {
          'title': widget.dropoff['name'] ?? 'Dropoff',
          'address': widget.dropoff['address'] ?? widget.dropoff['name'],
          'latitude': widget.dropoff['lat'],
          'longitude': widget.dropoff['lng'],
        },
        'vehicleType': _selectedVehicle,
        'paymentMethod': _paymentMode,
        'distance': _routeDistance,
        'fare': ((num.tryParse(_selectedVehicleData['price'].toString()) ?? 0) - _discountAmount).clamp(0.0, double.infinity),
        if (_appliedCoupon != null) 'couponCode': _appliedCoupon,
        if (_discountAmount > 0) 'discountAmount': _discountAmount,
      });

      if (mounted) {
        if (response.success && response.data != null) {
          final booking = response.data!;
          
          // Save guest phone in SharedPreferences
          if (guestPhone != null) {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('guest_phone', guestPhone);
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride requested successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _currentRideId = booking.bookingId;
            _isSearching = false;
          });

          // Connect socket for guest user if not connected yet
          final socketService = ref.read(socketServiceProvider);
          final String? resolvedUserId = booking.rawJson['userId']?.toString();
          if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
            socketService.connect(resolvedUserId, name: guestName);
          } else {
            socketService.connect(booking.bookingId, name: guestName);
          }

          final dynamic negotiatedFare = booking.rawJson['fare'] ?? 
                                         booking.rawJson['totalPrice'] ?? 
                                         booking.rawJson['estimatedFare'] ?? 
                                         _selectedVehicleData['price'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchingRideScreen(
                pickup: widget.pickup,
                dropoff: widget.dropoff,
                distance: '${_routeDistance.toStringAsFixed(1)} km',
                rideMode: _selectedVehicleData['name'],
                price: "₹$negotiatedFare",
                otp: null, // New API might not return OTP immediately
                rideId: _currentRideId!,
                vehicle: _selectedVehicleData,
              ),
            ),
          );
        } else {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Failed to request ride.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    }
  }


  void _handleRideAccepted(dynamic data) {
    print("User App Received Acceptance: $data");
    if (mounted && data['rideId'] == _currentRideId) {
      final negotiatedFare = data['fare'];
      Map<String, dynamic> finalVehicle = _selectedVehicleData;
      
      if (negotiatedFare != null) {
        finalVehicle = Map<String, dynamic>.from(_selectedVehicleData);
        finalVehicle['price'] = negotiatedFare;
      }

      _completeBooking(
        data['rideId'],
        driverData: data['driver'] is Map ? Map<String, dynamic>.from(data['driver']) : null,
        otp: data['otp']?.toString() ?? _currentOtp,
        vehicleOverride: finalVehicle,
      );
    }
  }

  void _completeBooking(String rideId, {Map<String, dynamic>? driverData, String? otp, Map<String, dynamic>? vehicleOverride}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          vehicle: vehicleOverride ?? _selectedVehicleData,
          rideId: rideId,
          otp: otp,
          driverData: driverData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _connectionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: context.colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Fare Estimate",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: context.colors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      final selected = _vehicles.firstWhere(
                        (v) => v['id'] == _selectedVehicle,
                        orElse: () => _vehicles.first,
                      );
                      _showFareBreakdownSheet(context, selected);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LeafletMap(
                    mapController: _mapController,
                    location: {
                      'lat': _parseDouble(widget.pickup['lat']),
                      'lng': _parseDouble(widget.pickup['lng']),
                    },
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.black,
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                    markers: [
                      Marker(
                        point: pickupPos,
                        width: 220,
                        height: 60,
                        child: _buildMapLabel(
                          widget.pickup['name'] ?? 'Pickup',
                          true,
                        ),
                      ),
                      Marker(
                        point: dropoffPos,
                        width: 220,
                        height: 60,
                        child: _buildMapLabel(
                          widget.dropoff['name'] == 'Current Location' &&
                                  widget.pickup['name'] == 'Current Location'
                              ? 'Destination'
                              : widget.dropoff['name'] ?? 'Dropoff',
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Promotion
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Choose a ride",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rides we think you'll like",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                          // Promotion
                          // Container(
                          //   width: double.infinity,
                          //   margin:  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          //   padding:  EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFFE6F4EA),
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: Row(
                          //     children: [
                          //       const Icon(Icons.local_offer, color: Color(0xFF1E8E3E), size: 18),
                          //       const SizedBox(width: 12),
                          //       const Expanded(
                          //         child: Text(
                          //           "100% off your next 2 rides. Up to ₹300 per ri...",
                          //           style: TextStyle(color: Color(0xFF1E8E3E), fontWeight: FontWeight.bold, fontSize: 13),
                          //           overflow: TextOverflow.ellipsis,
                          //         ),
                          //       ),
                          //       const Icon(Icons.info_outline, color: Color(0xFF1E8E3E), size: 16),
                          //     ],
                          //   ),
                          // ),

                          // Vehicle List
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _vehicles.length,
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              itemBuilder: (context, index) {
                                final v = _vehicles[index];
                                final isSelected = _selectedVehicle == v['id'];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedVehicle = v['id']),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: isSelected 
                                          ? Border.all(color: const Color(0xFF0F4A2C), width: 2) 
                                          : Border.all(color: Colors.grey[200]!, width: 1),
                                      borderRadius: BorderRadius.circular(16),
                                      color: isSelected ? const Color(0xFFEBF3F0) : Colors.white,
                                    ),
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? const Color(0xFF0F4A2C).withOpacity(0.1) 
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            v['icon'] as IconData, 
                                            size: 28, 
                                            color: isSelected ? const Color(0xFF0F4A2C) : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      v['name'], 
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold, 
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    v['capacity'] ?? "1", 
                                                    style: TextStyle(
                                                      fontSize: 11, 
                                                      color: Colors.grey[600], 
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${v['eta']}${v['time'] != null && v['time'].toString().isNotEmpty ? ' • ' + (v['time'].toString().contains('•') ? v['time'].toString().split('•')[0].trim() : v['time'].toString()) : ''}",
                                                style: TextStyle(
                                                  color: Colors.grey[600], 
                                                  fontSize: 12, 
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_isRouteLoading && v['id'] == 'economy')
                                              const ShimmerLoading(width: 50, height: 18)
                                            else
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "₹${v['price']}", 
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w900, 
                                                      fontSize: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () => _showFareBreakdownSheet(context, v),
                                                    child: const Icon(
                                                      Icons.info_outline,
                                                      size: 15,
                                                      color: Color(0xFF0F4A2C),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (v['oldPrice'] != null)
                                              Text(
                                                "₹${v['oldPrice']}", 
                                                style: TextStyle(
                                                  color: Colors.grey[400], 
                                                  fontSize: 11, 
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Payment & Footer
                          const Divider(height: 1),
                          InkWell(
                            onTap: _showCouponBottomSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _appliedCoupon != null
                                          ? 'Coupon: $_appliedCoupon (-₹${_discountAmount.toInt()})'
                                          : 'Apply Coupon / Offers',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _appliedCoupon != null ? Colors.green : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_appliedCoupon != null)
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.clear, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _appliedCoupon = null;
                                          _discountAmount = 0.0;
                                        });
                                      },
                                    )
                                  else
                                    const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: _showPaymentPicker,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    _paymentMode == 'cash' 
                                      ? Icons.money 
                                      : _paymentMode == 'upi' 
                                        ? Icons.account_balance_wallet
                                        : Icons.wallet, 
                                    color: Colors.green
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _paymentMode.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: ElevatedButton(
                              onPressed: _startBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isSearching
                                    ? "Searching..."
                                    : "Choose ${_selectedVehicleData['name']}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),            ),
                  ),
              
                // Removed the embedded _buildSearchingOverlay since we now push a separate page

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLabel(String name, bool isPickup) {
    if (isPickup) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("2", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                      Text("min", style: TextStyle(color: Colors.white, fontSize: 8)),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "From ${name.split(',')[0]}",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "To ${name.split(',')[0]}",
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      );
    }
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text("Cash"),
              trailing: _paymentMode == 'cash' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'cash');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text("UPI"),
              trailing: _paymentMode == 'upi' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'upi');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallet, color: Colors.orange),
              title: const Text("Wallet"),
              trailing: _paymentMode == 'wallet' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'wallet');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateCouponDiscount(String code, String description, double basePrice) {
    final upperCode = code.toUpperCase();
    final upperDesc = description.toUpperCase();

    // 1. Try to find percentage
    double? percentage;
    final pctRegExp = RegExp(r'(\d+)\s*%');
    final pctMatch = pctRegExp.firstMatch(upperDesc) ?? pctRegExp.firstMatch(upperCode);
    if (pctMatch != null) {
      percentage = double.tryParse(pctMatch.group(1) ?? '');
    }

    // 2. Try to find max/up-to discount or flat discount amount
    double? limitAmount;
    final rupeeRegExp = RegExp(r'(?:₹|RS\.?|UP\s*TO\s*₹?|SAVE\s*₹?)\s*(\d+)', caseSensitive: false);
    final matches = rupeeRegExp.allMatches(upperDesc);
    if (matches.isNotEmpty) {
      final upToRegExp = RegExp(r'(?:UP\s*TO|MAX|MAXIMUM)\s*(?:₹|RS\.?)?\s*(\d+)', caseSensitive: false);
      final upToMatch = upToRegExp.firstMatch(upperDesc);
      if (upToMatch != null) {
        limitAmount = double.tryParse(upToMatch.group(1) ?? '');
      } else {
        limitAmount = double.tryParse(matches.first.group(1) ?? '');
      }
    }

    if (limitAmount == null) {
      final genericNumberRegExp = RegExp(r'(\d+)');
      final genericMatches = genericNumberRegExp.allMatches(upperDesc);
      for (final match in genericMatches) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          if (percentage != null && val == percentage) {
            continue;
          }
          limitAmount = val;
          break;
        }
      }
    }

    if (limitAmount == null) {
      final codeNumRegExp = RegExp(r'(\d+)');
      final codeMatch = codeNumRegExp.firstMatch(upperCode);
      if (codeMatch != null) {
        final codeVal = double.tryParse(codeMatch.group(1) ?? '');
        if (codeVal != null) {
          if (upperCode.contains('PCT') || upperCode.contains('PERCENT') || upperCode.contains('OFF') && codeVal <= 100) {
            percentage = codeVal;
          } else {
            limitAmount = codeVal;
          }
        }
      }
    }

    if (percentage == null && limitAmount == null) {
      return 50.0;
    }

    if (percentage != null) {
      final calcDiscount = basePrice * (percentage / 100.0);
      if (limitAmount != null) {
        return calcDiscount > limitAmount ? limitAmount : calcDiscount;
      }
      return calcDiscount;
    }

    return limitAmount ?? 50.0;
  }

  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final couponsAsync = ref.watch(couponsProvider);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Coupons',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    if (_appliedCoupon != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _appliedCoupon = null;
                            _discountAmount = 0.0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                couponsAsync.when(
                  data: (coupons) {
                    final activeCoupons = coupons.where((c) {
                      final val = c['value'];
                      if (val == null) return false;
                      final status = val['status']?.toString().toLowerCase() ?? 'active';
                      return status == 'active';
                    }).toList();

                    if (activeCoupons.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No coupons available at the moment.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final basePrice = double.tryParse(_selectedVehicleData['price']?.toString() ?? '0') ?? 0.0;

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeCoupons.length,
                        itemBuilder: (context, index) {
                          final c = activeCoupons[index];
                          final val = c['value'] ?? {};
                          final code = (val['title'] ?? c['key'] ?? '').toString();
                          final desc = (val['description'] ?? '').toString();
                          final discount = _calculateCouponDiscount(code, desc, basePrice);

                          return _buildCouponItem(code, desc, discount);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Failed to load coupons: $err',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponItem(String code, String desc, double discount) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.confirmation_number, color: Colors.orange),
      ),
      title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      trailing: ElevatedButton(
        onPressed: () {
          setState(() {
            _appliedCoupon = code;
            _discountAmount = discount;
          });
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        child: const Text('Apply'),
      ),
    );
  }

  void _showFareBreakdownSheet(BuildContext context, Map<String, dynamic> vehicle) {
    final breakdown = vehicle['fareBreakdown'] as Map<String, dynamic>? ?? {};
    final double baseFare = (breakdown['baseFare'] ?? vehicle['baseFare'] ?? 50).toDouble();
    final double totalKm = (breakdown['totalKm'] ?? _routeDistance).toDouble();
    final double perKmRate = (breakdown['perKmRate'] ?? vehicle['perKmRate'] ?? 15).toDouble();
    final double distanceCharge = (breakdown['distanceCharge'] ?? (totalKm * perKmRate)).toDouble();

    final int totalMin = (breakdown['totalMin'] ?? _routeDurationMin.round()).toInt();
    final double perMinuteRate = (breakdown['perMinuteRate'] ?? vehicle['perMinuteRate'] ?? 1.5).toDouble();
    final double timeCharge = (breakdown['timeCharge'] ?? (totalMin * perMinuteRate)).toDouble();

    final bool isNightShift = breakdown['isNightShift'] ?? (DateTime.now().hour >= 22 || DateTime.now().hour < 6);
    final double nightCharge = (breakdown['nightCharge'] ?? 0.0).toDouble();
    final int totalFare = breakdown['totalFare'] != null 
        ? (breakdown['totalFare'] as num).toInt() 
        : int.tryParse(vehicle['price'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fare Breakdown (${vehicle['name']})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4A2C).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Google Maps Route",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4A2C)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Distance: ${totalKm.toStringAsFixed(1)} km • Duration: $totalMin mins",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(height: 24),

            // Base Fare
            _buildBreakdownRow("Base Price", "₹${baseFare.toStringAsFixed(0)}"),
            const SizedBox(height: 10),

            // Distance Charge
            _buildBreakdownRow(
              "Distance Charge (${totalKm.toStringAsFixed(1)} km × ₹${perKmRate.toStringAsFixed(0)}/km)",
              "₹${distanceCharge.toStringAsFixed(0)}",
            ),
            const SizedBox(height: 10),

            // Time Charge
            _buildBreakdownRow(
              "Time Charge ($totalMin min × ₹${perMinuteRate.toStringAsFixed(1)}/min)",
              "₹${timeCharge.toStringAsFixed(0)}",
            ),
            const SizedBox(height: 10),

            // Night Shift Charge
            if (isNightShift || nightCharge > 0) ...[
              _buildBreakdownRow(
                "Night Shift Charge (10 PM - 6 AM)",
                "+ ₹${nightCharge.toStringAsFixed(0)}",
                isHighlight: true,
              ),
              const SizedBox(height: 10),
            ],

            const Divider(height: 24),

            // Total Booking Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Booking Price",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "₹$totalFare",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F4A2C)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? const Color(0xFFD97706) : Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFD97706) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
