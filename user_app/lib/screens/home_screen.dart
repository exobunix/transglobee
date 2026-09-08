import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking_model.dart';
import '../providers/api_state_providers.dart';
import '../providers/user_provider.dart';
import 'location_search_screen.dart';
import 'offers_screen.dart';
import 'ride_booking_screen.dart';
import 'ride_tracking_screen.dart';
import 'logistics_booking/logistics_booking_screen.dart';
import 'bus_booking_screen.dart';
import 'my_logistics_bookings_screen.dart';
import 'notifications_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

void navigateToRideTracking(BuildContext context, dynamic booking) {
  if (booking is BookingModel) booking = booking.rawJson;
  final locations = booking['locations'] as List?;
  final pLoc = locations != null && locations.isNotEmpty ? locations[0] : null;
  final dLoc = locations != null && locations.length > 1 ? locations[1] : null;

  final pickupMap = {
    'name':
        booking['pickupAddress']?['label'] ??
        booking['pickup']?['name'] ??
        pLoc?['title'] ??
        pLoc?['address'] ??
        'Pickup',
    'lat':
        booking['pickupAddress']?['lat'] ??
        booking['pickup']?['lat'] ??
        pLoc?['latitude'] ??
        pLoc?['lat'] ??
        0.0,
    'lng':
        booking['pickupAddress']?['lng'] ??
        booking['pickup']?['lng'] ??
        pLoc?['longitude'] ??
        pLoc?['lng'] ??
        0.0,
  };

  final dropoffMap = {
    'name':
        booking['receivedAddress']?['label'] ??
        booking['dropoff']?['name'] ??
        dLoc?['title'] ??
        dLoc?['address'] ??
        'Drop-off',
    'lat':
        booking['receivedAddress']?['lat'] ??
        booking['dropoff']?['lat'] ??
        dLoc?['latitude'] ??
        dLoc?['lat'] ??
        0.0,
    'lng':
        booking['receivedAddress']?['lng'] ??
        booking['dropoff']?['lng'] ??
        dLoc?['longitude'] ??
        dLoc?['lng'] ??
        0.0,
  };

  final vehicleMap = {
    'name': booking['vehicleType'] ?? booking['rideMode'] ?? 'Vehicle',
    'price':
        (booking['totalPrice'] ??
                booking['fare'] ??
                booking['estimatedFare'] ??
                0.0)
            .toString(),
  };

  final rideId = booking['bookingId'] ?? booking['_id'] ?? '';
  final otp = booking['otp']?.toString();
  final driverData =
      booking['driver'] ??
      booking['driverSnapshot'] ??
      booking['driver_snapshot'];
  final distance = (booking['distance'] ?? '').toString();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RideTrackingScreen(
        pickup: pickupMap,
        dropoff: dropoffMap,
        vehicle: vehicleMap,
        rideId: rideId,
        otp: otp,
        driverData: driverData,
        distance: distance,
      ),
    ),
  );
}



class HomeTab extends ConsumerStatefulWidget {
  final VoidCallback? onMenuPressed;
  const HomeTab({super.key, this.onMenuPressed});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  int _selectedVehicleIndex = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  void _startBannerAutoScroll(int totalCount) {
    _bannerTimer?.cancel();
    if (totalCount <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_bannerPageController.hasClients) return;
      _currentBannerIndex = (_currentBannerIndex + 1) % totalCount;
      _bannerPageController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _handleWhereTo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSearchScreen(title: 'Where to?'),
      ),
    );

    if (result != null && result is Map && mounted) {
      final pickup =
          result['pickup'] ??
          {
            'name': 'Current Location',
            'address': 'Using GPS',
            'lat': 19.0760,
            'lng': 72.8777,
          };
      final dropoff = result['dropoff'] ?? result;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideBookingScreen(
            pickup: pickup,
            dropoff: Map<String, dynamic>.from(dropoff),
            serviceType: 'cab',
          ),
        ),
      );
    }
  }

  Widget _buildPillButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(28.5355, 77.25),
                  initialZoom: 10.8,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.transglobe.user_app',
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () async {
                  final position = await LocationService.getCurrentLocation();
                  if (position != null) {
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      14.0,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed, color: const Color(0xFF0F4A2C), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Current Location",
                        style: TextStyle(
                          color: const Color(0xFF0F4A2C),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OffersScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, color: const Color(0xFF0F4A2C), size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        "Offers",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeItem({
    required int index,
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedVehicleIndex == index;
    final primaryColor = const Color(0xFF0F4A2C);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleIndex = index;
        });
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 105,
        margin: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? primaryColor 
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? primaryColor.withOpacity(0.12) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular badge background for the image
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.directions_car_filled_rounded, 
                    size: 24, 
                    color: isSelected ? primaryColor : Colors.grey[500]
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? primaryColor : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.notoSans(
                fontSize: 9, 
                fontWeight: FontWeight.w500,
                color: isSelected ? primaryColor.withOpacity(0.8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.black87,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.notoSans(
              fontSize: 7.5,
              color: Colors.black54,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(fullUserProfileProvider);
    final isLoggedIn = userAsync.value != null;
    final recentBookingsAsync = ref.watch(recentBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile & Welcome Text
                  GestureDetector(
                    onTap: widget.onMenuPressed,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          child: userAsync.when(
                            data: (user) => const Icon(Icons.person, color: Colors.black54),
                            loading: () => const CircularProgressIndicator(strokeWidth: 2),
                            error: (_, __) => const Icon(Icons.person, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            userAsync.when(
                              data: (user) => Text(
                                "Hello, ${user?.name ?? 'Guest'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              loading: () => const Text("Hello...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              error: (_, __) => const Text("Hello, Guest", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            Text(
                              "Welcome back!",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox.shrink(),

                  // Notifications Bell with Badge
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCount = ref.watch(unreadNotificationCountProvider);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.black87,
                                size: 22,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F4A2C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Pickup & Drop Card — Dark Green Premium (matches brand image)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D2A),
                  borderRadius: BorderRadius.circular(20),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: const Color(0xFF0F3D2A).withOpacity(0.35),
                  //     blurRadius: 20,
                  //     offset: const Offset(0, 8),
                  //   ),
                  // ],
                ),
                child: Stack(
                  children: [
                    // Subtle radial glow on right
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ── Left: Location Inputs ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Pickup Row
                                    GestureDetector(
                                      onTap: _handleWhereTo,
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        children: [
                                          // Up-arrow icon box
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Pickup Location",
                                                  style: GoogleFonts.lexend(
                                                    color: Colors.white.withOpacity(0.6),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                Text(
                                                  "Enter pickup location",
                                                  style: GoogleFonts.notoSans(
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // GPS icon
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.my_location_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Dotted vertical connector (extra compact)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 15, top: 1, bottom: 1),
                                      child: Column(
                                        children: List.generate(
                                          2,
                                          (i) => Container(
                                            width: 2,
                                            height: 3,
                                            margin: const EdgeInsets.symmetric(vertical: 0.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.35),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Dropoff Row
                                    GestureDetector(
                                      onTap: _handleWhereTo,
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        children: [
                                          // Down-arrow icon box (orange)
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE85D1A),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_downward_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Drop Location",
                                                  style: GoogleFonts.lexend(
                                                    color: Colors.white.withOpacity(0.6),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                Text(
                                                  "Enter drop location",
                                                  style: GoogleFonts.notoSans(
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // GPS icon
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.gps_fixed_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // ── Right: Illustration (Scaled down further) ──
                              SizedBox(
                                width: 80,
                                height: 85,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Globe circle
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 62,
                                        height: 62,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.15),
                                            width: 1.5,
                                          ),
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.07),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.public_rounded,
                                          color: Colors.white.withOpacity(0.25),
                                          size: 38,
                                        ),
                                      ),
                                    ),
                                    // Location pin on globe
                                    Positioned(
                                      top: 3,
                                      right: 15,
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 14,
                                      ),
                                    ),
                                    // Truck icon at bottom
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.local_shipping_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 34,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ── Quick Chips at bottom spanning full width ──
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            child: Row(
                              children: [
                                _buildGreenChip(Icons.home_rounded, "Home"),
                                const SizedBox(width: 8),
                                _buildGreenChip(Icons.work_rounded, "Work"),
                                const SizedBox(width: 8),
                                _buildGreenChip(Icons.star_rounded, "Saved Places"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Map View Card
              _buildMapCard(),

              const SizedBox(height: 16),

              // 4. Hero Banner / Promo Cargo Card
              ref.watch(bannersProvider).when(
                data: (bannersList) {
                  final activeBanners = bannersList.where((b) {
                    final val = b['value'] ?? {};
                    final status = val['status']?.toString().toLowerCase();
                    final isEnable = val['isEnable'];
                    final isInactive =
                        status == 'inactive' || isEnable == false;
                    final img =
                        (val['imageUrl'] ?? val['image'])?.toString() ?? '';
                    return !isInactive && img.isNotEmpty;
                  }).toList();

                  if (activeBanners.isEmpty) {
                    return _buildDefaultHeroBanner();
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        activeBanners.length != _currentBannerIndex) {
                      _startBannerAutoScroll(activeBanners.length);
                    }
                  });

                  return Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PageView.builder(
                          controller: _bannerPageController,
                          itemCount: activeBanners.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                          itemBuilder: (context, idx) {
                            final b = activeBanners[idx];
                            final val = b['value'] ?? {};
                            final img =
                                (val['imageUrl'] ?? val['image'])
                                    ?.toString() ??
                                '';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildDefaultHeroBannerContent(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (activeBanners.length > 1) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            activeBanners.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              width: _currentBannerIndex == index
                                  ? 20
                                  : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentBannerIndex == index
                                    ? const Color(0xFF0F4A2C)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => _buildDefaultHeroBanner(),
              ),

              const SizedBox(height: 16),

              // 5. Choose Vehicle Type Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Choose Vehicle Type",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleWhereTo,
                    child: const Text(
                      "View All >",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4A2C),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Horizontal list of Vehicles
              SizedBox(
                height: 125,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildVehicleTypeItem(
                      index: 0,
                      title: "Cab",
                      subtitle: "Car",
                      imagePath: "assets/images/cab.png",
                      onTap: _handleWhereTo,
                    ),
                    if (isLoggedIn) ...[
                      _buildVehicleTypeItem(
                        index: 1,
                        title: "Logistics",
                        subtitle: "Pickup",
                        imagePath: "assets/images/homescreen/service_ride.png",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogisticsBookingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildVehicleTypeItem(
                        index: 2,
                        title: "Shuttle",
                        subtitle: "Bus",
                        imagePath: "assets/images/bus.png",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusBookingScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

             
              const SizedBox(height: 20),

              // 6. Benefits/Features Row (4 Columns fitting full width and having same size/height)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.gps_fixed,
                        title: "Real-Time Tracking",
                        subtitle: "Track your shipment anytime, anywhere",
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.shield_outlined,
                        title: "Secure & Safe",
                        subtitle: "100% Insured Deliveries",
                        bgColor: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.access_time,
                        title: "On-Time Delivery",
                        subtitle: "We value your time",
                        bgColor: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFF57F17),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.headset_mic_outlined,
                        title: "24/7 Support",
                        subtitle: "We are always here to help",
                        bgColor: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF7B1FA2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recent bookings if any (preserving functionality)
              recentBookingsAsync.when(
                data: (recentBookings) {
                  if (recentBookings.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Logistics",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        const MyLogisticsBookingsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "See All",
                                style: TextStyle(
                                  color: Color(0xFF0F4A2C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentBookings.length,
                        itemBuilder: (ctx, index) {
                          return _buildRecentBookingCard(recentBookings[index]);
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // const SizedBox(height: 32),
  ]
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultHeroBanner() {
    return _buildDefaultHeroBannerContent();
  }

  Widget _buildDefaultHeroBannerContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF4F6F5),
            Color(0xFFE2E7E4),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Your Cargo,",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      "Our Responsibility",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4A2C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Fast. Reliable. Secure Logistics\nSolutions for you.",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        final isLoggedIn = ref.read(fullUserProfileProvider).value != null;
                        if (isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogisticsBookingScreen(),
                            ),
                          );
                        } else {
                          _handleWhereTo();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4A2C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Book Shipment",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF0F4A2C),
                                size: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(),
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: 0,
            top: 0,
            child: Image.asset(
              "assets/images/truck.png",
              width: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16, left: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String vehicle) {
    final v = vehicle.toLowerCase();
    if (v.contains('flight')) return Icons.flight_takeoff_rounded;
    if (v.contains('train')) return Icons.train_rounded;
    if (v.contains('sea')) return Icons.directions_boat_rounded;
    return Icons.local_shipping_rounded;
  }

  Widget _buildRecentBookingCard(dynamic booking) {
    if (booking is BookingModel) booking = booking.rawJson;
    const Color transPurple = Color(0xFF8B7DBE);
    final status = (booking['status'] ?? 'pending').toString();
    final vehicle =
        booking['vehicleType'] ?? booking['rideMode'] ?? 'Logistics';

    final locations = booking['locations'] as List?;
    final pickup =
        booking['pickupAddress']?['label'] ??
        booking['pickup']?['name'] ??
        (locations != null && locations.isNotEmpty
            ? locations[0]['title'] ?? locations[0]['address']
            : null) ??
        'Pickup';
    final drop =
        booking['receivedAddress']?['label'] ??
        booking['dropoff']?['name'] ??
        (locations != null && locations.length > 1
            ? locations[1]['title'] ?? locations[1]['address']
            : null) ??
        'Delivery';
    final date = DateTime.parse(booking['createdAt']).toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getVehicleIcon(vehicle),
                  color: Colors.black87,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          vehicle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getHistoryStatusColor(
                              status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getHistoryStatusColor(status),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (booking['otp'] != null &&
                            (status == 'confirmed' || status == 'processing'))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: transPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OTP: ${booking['otp']}',
                              style: const TextStyle(
                                color: transPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pickup → $drop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(double.tryParse((booking['totalPrice'] ?? booking['fare'] ?? 0.0).toString()) ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHistoryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_transit':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  void _showBookingDetails(dynamic booking) {
    if (booking is BookingModel) booking = booking.rawJson;
    const Color transPurple = Color(0xFF8B7DBE);
    final status = (booking['status'] ?? 'pending').toString();
    final vehicle =
        booking['vehicleType'] ?? booking['rideMode'] ?? 'Logistics';
    final items = booking['items'] as List? ?? [];

    final locations = booking['locations'] as List?;
    final pAddr = booking['pickupAddress'];
    final rAddr = booking['receivedAddress'];
    final pLoc = booking['pickup'];
    final dLoc = booking['dropoff'];

    final pickupLabel =
        pAddr?['fullAddress'] ??
        pLoc?['address'] ??
        (locations != null && locations.isNotEmpty
            ? locations[0]['address'] ?? locations[0]['title']
            : null) ??
        '';
    final dropoffLabel =
        rAddr?['fullAddress'] ??
        dLoc?['address'] ??
        (locations != null && locations.length > 1
            ? locations[1]['address'] ?? locations[1]['title']
            : null) ??
        '';
    final date = DateTime.parse(booking['createdAt']).toLocal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Booked on ${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getHistoryStatusColor(
                              status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getHistoryStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (booking['otp'] != null &&
                        (status == 'confirmed' || status == 'processing')) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: transPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: transPurple.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'GIVE THIS OTP TO DRIVER TO START',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              booking['otp'].toString(),
                              style: const TextStyle(
                                color: transPurple,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    const Text(
                      "Addresses",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _locationDetailItem("Pickup", pickupLabel),
                    const SizedBox(height: 12),
                    _locationDetailItem("Delivery", dropoffLabel),

                    const SizedBox(height: 24),
                    Text(
                      "Items (${items.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (it) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                it['itemName'] ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (it['length'] != null)
                              Text(
                                '${it['length']}x${it['height']}x${it['width']} ${it['unit'] ?? 'cm'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Amount Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _amountRow(
                      "Vehicle Fare",
                      booking['vehiclePrice'] ?? booking['fare'] ?? 0,
                    ),
                    if ((booking['helperCost'] ?? 0) > 0)
                      _amountRow("Helper Charges", booking['helperCost']),
                    if ((booking['discountAmount'] ?? 0) > 0)
                      _amountRow(
                        "Discount",
                        -(booking['discountAmount'] ?? 0),
                        isDiscount: true,
                      ),
                    const Divider(height: 24),
                    _amountRow(
                      "Total Paid",
                      booking['totalPrice'] ?? booking['fare'] ?? 0,
                      isTotal: true,
                    ),

                    if (status.toLowerCase() != 'delivered' &&
                        status.toLowerCase() != 'completed' &&
                        status.toLowerCase() != 'cancelled') ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          navigateToRideTracking(context, booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Track Booking",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationDetailItem(String title, String addr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(addr, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _amountRow(
    String label,
    dynamic amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${(double.tryParse(amount.toString()) ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 13,
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? Colors.green
                  : (isTotal ? Colors.black : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick-access chip shown below the search bar (Home, Work, Saved Places).
  Widget _buildGreenChip(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          onTap: () {
            // TODO: navigate to saved place or prefill search with [label]
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}