import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import '../services/location_service.dart';
import '../widgets/leaflet_map.dart';
import 'ride_tracking_screen.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../services/rest_api_repository.dart';

class SearchingRideScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final String distance;
  final String rideMode;
  final String price;
  final String? otp;
  final String rideId;
  final Map<String, dynamic> vehicle;

  const SearchingRideScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.rideMode,
    required this.price,
    this.otp,
    required this.rideId,
    required this.vehicle,
  });

  @override
  ConsumerState<SearchingRideScreen> createState() => _SearchingRideScreenState();
}

class _SearchingRideScreenState extends ConsumerState<SearchingRideScreen>
    with SingleTickerProviderStateMixin {
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  StreamSubscription? _acceptedSubscription;
  StreamSubscription? _statusSubscription;
  Timer? _statusPollTimer;
  bool _hasNavigated = false;
  double _currentPrice = 0.0;
  bool _isUpdatingFare = false;
  int? _selectedFareAmount;

  AnimationController? _pulseController;

  AnimationController get pulseController {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    return _pulseController!;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _currentPrice = double.tryParse(widget.price.replaceAll('₹', '')) ?? 0.0;
    
    // Ensure animation controller is initialized
    pulseController;

    _loadRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeRealtimeUpdates());
  }

  Future<void> _initializeRealtimeUpdates() async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    if (!mounted) return;

    final userProfile = await ref.read(fullUserProfileProvider.future).catchError((_) => null);
    final mongoUserId = userProfile?.id;
    final firebaseId = authService.currentUser?.uid;
    final userName = userProfile?.name;

    final socketRooms = <String>{
      if (mongoUserId != null && mongoUserId.isNotEmpty) mongoUserId,
      if (firebaseId != null && firebaseId.isNotEmpty) firebaseId,
      widget.rideId,
    };

    final primaryRoom = socketRooms.first;
    ref.read(socketServiceProvider).connect(
      primaryRoom,
      name: userName ?? 'Guest User',
      additionalUserIds: socketRooms.skip(1).toList(),
    );

    ref.read(socketServiceProvider).joinRide(widget.rideId);

    _acceptedSubscription =
        ref.read(socketServiceProvider).rideAcceptedStream.listen(_handleRideAcceptedEvent);

    _statusSubscription =
        ref.read(socketServiceProvider).rideStatusStream.listen(_handleRideStatusEvent);

    await _pollRideStatus();
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollRideStatus());
  }

  bool _matchesRideId(String? receivedId) {
    if (receivedId == null) return false;
    return receivedId.toLowerCase() == widget.rideId.toString().toLowerCase();
  }

  void _handleRideAcceptedEvent(Map<String, dynamic> data) {
    debugPrint("Ride accepted socket: ${data['rideId']} (target: ${widget.rideId})");
    if (_matchesRideId(data['rideId']?.toString())) {
      _navigateToTracking(data);
    }
  }

  void _handleRideStatusEvent(Map<String, dynamic> data) {
    final status = data['status']?.toString();
    debugPrint("Ride status socket: $status for ${data['rideId']}");
    if (!_matchesRideId(data['rideId']?.toString())) return;
    if (ref.read(rideServiceProvider).isRideAcceptedStatus(status)) {
      _navigateToTracking(data);
    }
  }

  Future<void> _pollRideStatus() async {
    if (!mounted || _hasNavigated) return;

    try {
      final rideService = ref.read(rideServiceProvider);
      final payload = await rideService.fetchRidePayload(widget.rideId);
      if (!mounted || _hasNavigated || payload == null) return;

      final status = payload['status']?.toString();
      final hasDriver = payload['driverId'] != null ||
          payload['driver'] != null ||
          payload['driverSnapshot'] != null;

      if (rideService.isRideAcceptedStatus(status) && hasDriver) {
        debugPrint("Ride accepted via API poll — navigating");
        _navigateToTracking({
          'rideId': widget.rideId,
          'status': status,
          'otp': payload['otp'],
          'fare': payload['fare'] ?? payload['actualFare'] ?? payload['totalPrice'],
          'driver': payload['driver'] ?? payload['driverSnapshot'],
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Ride status poll failed: $e");
      }
    }
  }

  void _navigateToTracking(Map<String, dynamic> data) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _statusPollTimer?.cancel();
    final negotiatedFare = data['fare'];
    Map<String, dynamic> finalVehicle = widget.vehicle;

    if (negotiatedFare != null) {
      finalVehicle = Map<String, dynamic>.from(widget.vehicle);
      finalVehicle['price'] = negotiatedFare;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          vehicle: finalVehicle,
          rideId: widget.rideId,
          otp: data['otp']?.toString() ?? widget.otp,
          distance: widget.distance,
          driverData: data['driver'] is Map
              ? Map<String, dynamic>.from(data['driver'])
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _acceptedSubscription?.cancel();
    _statusSubscription?.cancel();
    _statusPollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['latitude'] ?? widget.pickup['lat']),
      _parseDouble(widget.pickup['longitude'] ?? widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['latitude'] ?? widget.dropoff['lat']),
      _parseDouble(widget.dropoff['longitude'] ?? widget.dropoff['lng']),
    );

    try {
      final routeData = await LocationService.getRouteData(pickupPos, dropoffPos);
      if (mounted) {
        setState(() {
          final List<dynamic> rawPoints = routeData['points'] ?? [];
          _routePoints = rawPoints.map((p) => LatLng(p[0], p[1])).toList();
        });
        _fitBounds();
      }
    } catch (e) {
      debugPrint("Error loading route: $e");
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    try {
      final validPoints = _routePoints.where((p) =>
        p.latitude >= -90 && p.latitude <= 90 &&
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) return;

      final bounds = LatLngBounds.fromPoints(validPoints);
      final screenHeight = MediaQuery.maybeOf(context)?.size.height ?? 800.0;
      // Sheet takes ~52% of screen height. Add padding so polygon route is 100% visible above sheet.
      final bottomPadding = (screenHeight * 0.54) + 30;

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.only(top: 120, bottom: bottomPadding, left: 50, right: 50),
        ),
      );
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupLat = _parseDouble(widget.pickup['latitude'] ?? widget.pickup['lat']);
    final pickupLng = _parseDouble(widget.pickup['longitude'] ?? widget.pickup['lng']);
    final dropoffLat = _parseDouble(widget.dropoff['latitude'] ?? widget.dropoff['lat']);
    final dropoffLng = _parseDouble(widget.dropoff['longitude'] ?? widget.dropoff['lng']);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1628),
      body: Stack(
        children: [
          // 1. Background Map View
          Positioned.fill(
            child: LeafletMap(
              mapController: _mapController,
              location: {'lat': pickupLat, 'lng': pickupLng},
              polylines: [
                if (_routePoints.isNotEmpty)
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF0F4A2C),
                    strokeWidth: 8.0,
                    borderStrokeWidth: 3.0,
                    borderColor: Colors.white.withValues(alpha: 0.9),
                  ),
              ],
              markers: [
                // Pickup marker (Glowing Green with concentric rings)
                Marker(
                  point: LatLng(pickupLat, pickupLng),
                  width: 60,
                  height: 60,
                  child: AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24 + (pulseController.value * 28),
                            height: 24 + (pulseController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF19C37D).withOpacity((1.0 - pulseController.value).clamp(0.0, 1.0) * 0.4),
                            ),
                          ),
                          Container(
                            width: 18 + (pulseController.value * 14),
                            height: 18 + (pulseController.value * 14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF19C37D).withOpacity((1.0 - pulseController.value).clamp(0.0, 1.0) * 0.6),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF19C37D),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Destination marker (Red with soft red glow)
                Marker(
                  point: LatLng(dropoffLat, dropoffLng),
                  width: 50,
                  height: 50,
                  child: AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 20 + (pulseController.value * 20),
                            height: 20 + (pulseController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE05252).withOpacity((1.0 - pulseController.value).clamp(0.0, 1.0) * 0.4),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE05252),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Subtle black/fade overlay at the bottom where map meets the bottom sheet
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.52 - 20,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B1628).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 2. Top Floating Header Area
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Floating Close Button (Glassmorphism, 52-56px)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101C30).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.close, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Title Header (Booking Request Pill with glowing Searching dot)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101C30).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Booking Request",
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Glowing Green Dot (Searching)
                              AnimatedBuilder(
                                animation: pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF19C37D),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF19C37D).withOpacity((1.0 - pulseController.value).clamp(0.0, 1.0) * 0.8),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 52), // Symmetry balance
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Sheet Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.54,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF101C30),
                    Color(0xFF0A1425),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 25,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Bottom sheet drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Scrollable Bottom Sheet Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // 1. Searching Animation (Pulse Concentric Rings)
                            _buildSearchingAnimation(),
                            const SizedBox(height: 16),

                            // 2. Main Status Text
                            Text(
                              "Finding your ride...",
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Connecting with nearby drivers",
                              style: GoogleFonts.notoSans(
                                color: const Color(0xFFAAB3C2),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Indeterminate search progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 3,
                                width: 140,
                                child: LinearProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF19C37D)),
                                  backgroundColor: const Color(0xFF182338),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. Driver Search Details Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.radar, color: const Color(0xFF778296), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "Searching within 5 km",
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xFF778296),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.timer_outlined, color: const Color(0xFF778296), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "Est. time: 1–3 min",
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xFF778296),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Trip summary pill details
                            _buildGlassTripSummaryCard(),
                            const SizedBox(height: 24),

                            // 5. Fare Boost Section
                            _buildFareBoostSection(),
                            const SizedBox(height: 28),

                            // 6. Cancel Button
                            ElevatedButton.icon(
                              onPressed: () => _showCancelDialog(),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text("Cancel Request"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFFE05252),
                                minimumSize: const Size(double.infinity, 58),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: Color(0xFFE05252), width: 1.2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingAnimation() {
    final primaryColor = const Color(0xFF19C37D);
    return SizedBox(
      height: 100,
      width: 100,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Concentric Ring 3
              Container(
                width: 48 + (pulseController.value * 48),
                height: 48 + (pulseController.value * 48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: (1.0 - pulseController.value).clamp(0.0, 1.0) * 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              // Concentric Ring 2
              Container(
                width: 48 + (((pulseController.value + 0.5) % 1.0) * 48),
                height: 48 + (((pulseController.value + 0.5) % 1.0) * 48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: (1.0 - ((pulseController.value + 0.5) % 1.0)).clamp(0.0, 1.0) * 0.4),
                    width: 1.5,
                  ),
                ),
              ),
              // Center circle container
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassTripSummaryCard() {
    final pickupName = widget.pickup['name'] ?? widget.pickup['address'] ?? "Pickup Location";
    final dropoffName = widget.dropoff['name'] ?? widget.dropoff['address'] ?? "Dropoff Location";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182338).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF344158), width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF19C37D), size: 10),
                  Container(
                    width: 1.5,
                    height: 24,
                    color: const Color(0xFF344158),
                  ),
                  const Icon(Icons.location_on, color: Color(0xFFE05252), size: 12),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickupName,
                      style: GoogleFonts.notoSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      dropoffName,
                      style: GoogleFonts.notoSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF344158), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn("Distance", widget.distance),
              Container(width: 1, height: 20, color: const Color(0xFF344158)),
              _buildMetricColumn("Type", widget.rideMode),
              Container(width: 1, height: 20, color: const Color(0xFF344158)),
              _buildMetricColumn("Fare", "₹${_currentPrice.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String val) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.notoSans(color: const Color(0xFF778296), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.lexend(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFareBoostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Increase fare",
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Higher fare may get you a driver faster",
                  style: GoogleFonts.notoSans(
                    color: const Color(0xFF778296),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFareCard(10, false)),
            const SizedBox(width: 12),
            Expanded(child: _buildFareCard(20, true)), // +20 is recommended
            const SizedBox(width: 12),
            Expanded(child: _buildFareCard(30, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildFareCard(int amount, bool isRecommended) {
    final isSelected = _selectedFareAmount == amount;
    return GestureDetector(
      onTap: _isUpdatingFare ? null : () {
        setState(() => _selectedFareAmount = amount);
        _increaseFare(amount);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF19C37D).withOpacity(0.12)
                  : const Color(0xFF182338).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF19C37D)
                    : (isRecommended ? const Color(0xFF19C37D).withOpacity(0.4) : const Color(0xFF344158)),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF19C37D).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    "+₹$amount",
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Faster match",
                    style: GoogleFonts.notoSans(
                      color: isSelected ? const Color(0xFF19C37D) : const Color(0xFFAAB3C2),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19C37D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "RECOMMENDED",
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _increaseFare(int amount) async {
    if (_isUpdatingFare) return;
    setState(() => _isUpdatingFare = true);

    try {
      final res = await ref.read(rideServiceProvider).updateFare(widget.rideId, amount);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _currentPrice += amount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Fare increased to ₹${_currentPrice.toStringAsFixed(0)}",
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF19C37D),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error increasing fare: $e");
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFare = false);
      }
    }
  }

  Future<void> _cancelRide() async {
    try {
      final repo = ref.read(restApiRepositoryProvider);
      final response = await repo.cancelBooking(
        bookingId: widget.rideId,
        reason: 'User cancelled request',
      );
      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request cancelled successfully.',
              style: GoogleFonts.notoSans(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel request: ${response.message}',
              style: GoogleFonts.notoSans(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error cancelling request: $e',
              style: GoogleFonts.notoSans(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF101C30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF344158)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE05252), size: 24),
            const SizedBox(width: 10),
            Text(
              "Cancel Booking?",
              style: GoogleFonts.lexend(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel this booking request?",
          style: GoogleFonts.notoSans(color: const Color(0xFFAAB3C2), fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "No, Keep",
              style: GoogleFonts.notoSans(color: const Color(0xFF778296), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cancelRide();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05252),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              "Yes, Cancel",
              style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

