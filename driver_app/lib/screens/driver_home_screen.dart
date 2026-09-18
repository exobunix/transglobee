import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/core/theme.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:driver_app/models/booking_model.dart';

import 'package:driver_app/providers/vehicle_type_provider.dart';
import 'package:driver_app/widgets/vehicle_type_selector.dart';
import 'package:driver_app/widgets/earnings_dashboard.dart';
import 'package:driver_app/widgets/ride_request_card.dart';

import 'package:driver_app/widgets/status_chip.dart';
import 'package:driver_app/screens/booking/booking_detail_screen.dart';
import 'package:driver_app/services/socket_service.dart';
import 'package:driver_app/providers/booking_provider.dart';
import 'package:driver_app/providers/active_ride_tracking_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:driver_app/features/driver/controllers/driver_providers.dart';
import 'package:driver_app/features/driver/models/request/update_location_request.dart';
import 'package:driver_app/core/network/api_state.dart';
import 'package:driver_app/features/driver/models/response/driver_profile_response.dart';

import '../core/app_router.dart';

// ── Providers ──
class DriverStatusNotifier extends Notifier<DriverStatus> {
  @override
  DriverStatus build() => DriverStatus.offline;
  void set(DriverStatus value) {
    if (state == value) return;
    state = value;

    // Sync with backend service using new controller
    final isOnline = value != DriverStatus.offline;
    ref
        .read(updateDriverStatusControllerProvider.notifier)
        .updateOnlineStatus(isOnline);
  }

  void updateLocal(DriverStatus value) {
    if (state == value) return;
    state = value;
  }
}

final driverStatusProvider =
    NotifierProvider<DriverStatusNotifier, DriverStatus>(
  DriverStatusNotifier.new,
);

class ShowRequestNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void show() => state = true;
  void hide() => state = false;
}

final showRequestProvider = NotifierProvider<ShowRequestNotifier, bool>(
  ShowRequestNotifier.new,
);

class CurrentRideRequestNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void setRide(Map<String, dynamic>? data) => state = data;
}

final currentRideRequestProvider =
    NotifierProvider<CurrentRideRequestNotifier, Map<String, dynamic>?>(
  CurrentRideRequestNotifier.new,
);

// ── Main Screen ──
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _onlineBannerController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerFade;
  StreamSubscription? _newRideSub;
  StreamSubscription? _rideAssignedSub;
  StreamSubscription? _rideCancelledSub;
  StreamSubscription? _fareUpdatedSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _statusChangeSub;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _onlineBannerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _onlineBannerController,
      curve: Curves.easeOutCubic,
    ));
    _bannerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _onlineBannerController, curve: Curves.easeIn),
    );

    // Listen to profile updates
    ref.listenManual(driverProfileControllerProvider, (previous, next) {
      if (next.status == ApiStatus.success && next.data != null) {
        final driverProfile = next.data!;
        final socketService = ref.read(socketServiceProvider);
        socketService.connect(driverProfile.id, name: driverProfile.name);

        // Sync initial online status from database profile status
        if (driverProfile.status == 'active') {
          ref.read(driverStatusProvider.notifier).updateLocal(DriverStatus.available);
          _onlineBannerController.forward();
        } else {
          ref.read(driverStatusProvider.notifier).updateLocal(DriverStatus.offline);
          _onlineBannerController.reverse();
        }

        _connectionSub?.cancel();
        _connectionSub = socketService.connectionSuccessStream.listen((data) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Connected successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    });

    // Polling fallback when socket missed a new_ride event
    ref.listenManual(incomingRideRequestsProvider, (previous, next) {
      try {
        if (next.isEmpty ||
            ref.read(driverStatusProvider) != DriverStatus.available) {
          return;
        }
        if (ref.read(currentRideRequestProvider) != null) return;

        final currentVehicleType = ref.read(vehicleTypeProvider).name; // 'cab', 'truck', 'bus'
        // If driver is on Cab tab, show all types of bookings (Cab, Truck, Bus). Otherwise filter strictly.
        final filteredNext = (currentVehicleType == 'cab')
            ? next
            : next.where((b) => b.vehicleType == currentVehicleType).toList();
        if (filteredNext.isEmpty) return;

        final firstRide = filteredNext.first;
        debugPrint('[DISPATCH] Polling surfaced ride ${firstRide.id} (${firstRide.dispatchType})');

        ref.read(currentRideRequestProvider.notifier).setRide(firstRide.toRideRequestMap());
        ref.read(showRequestProvider.notifier).show();
      } catch (e) {
        debugPrint('Error in incoming ride listener: $e');
      }
    });

    // Handle vehicle type switching to update or hide current ride request card
    ref.listenManual(vehicleTypeProvider, (previous, next) {
      final currentRide = ref.read(currentRideRequestProvider);
      if (currentRide != null) {
        final bookingVehicleType = currentRide['vehicleType']?.toString().toLowerCase() ?? 'cab';
        // When switching to Cab tab, any booking type is allowed. When switching to other tabs, match strictly.
        if (next.name != 'cab' && bookingVehicleType != next.name) {
          ref.read(showRequestProvider.notifier).hide();
          ref.read(currentRideRequestProvider.notifier).setRide(null);
        }
      }
      
      // Auto-promote first matching pending request for new vehicle tab
      final pending = ref.read(incomingRideRequestsProvider);
      final currentVehicleType = next.name;
      final filteredPending = (currentVehicleType == 'cab')
          ? pending
          : pending.where((b) => b.vehicleType == currentVehicleType).toList();
      if (filteredPending.isNotEmpty &&
          ref.read(driverStatusProvider) == DriverStatus.available &&
          ref.read(currentRideRequestProvider) == null) {
        ref.read(currentRideRequestProvider.notifier).setRide(filteredPending.first.toRideRequestMap());
        ref.read(showRequestProvider.notifier).show();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(driverProfileControllerProvider);
      if (profileState.status == ApiStatus.success && profileState.data != null) {
        ref
            .read(socketServiceProvider)
            .connect(profileState.data!.id, name: profileState.data!.name);
      } else {
        ref.read(driverProfileControllerProvider.notifier).getDriverProfile();
      }

      // Fetch current booking to resume any active trip
      ref.read(currentBookingControllerProvider.notifier).getCurrentBooking();

      final socketService = ref.read(socketServiceProvider);

      _newRideSub?.cancel();
      _newRideSub = socketService.newRideStream.listen((data) {
        print("Driver App Received New Ride Request: $data");

        try {
          final bookingType = (data['type'] ?? data['bookingCategory'] ?? 'CAB')
              .toString()
              .toUpperCase();
          final status = (data['status'] ?? 'pending').toString().toLowerCase();

          // Cab: show immediately. Logistics/shuttle: only after roadmap approval.
          final isCab = bookingType == 'CAB' || bookingType == 'RETAIL';
          final isApprovedJob = status == 'pending_for_driver' ||
              (data['roadmapStatus']?.toString().toLowerCase() == 'approved');
          if (!isCab && !isApprovedJob) {
            return;
          }

          final newBooking = BookingModel.fromJson(data);
          ref.read(bookingProvider.notifier).addIncomingRequest(newBooking);

          final currentVehicleType = ref.read(vehicleTypeProvider).name; // 'cab', 'truck', 'bus'
          // If on Cab tab, accept all incoming booking requests, otherwise only matching vehicle type
          final isEligibleTab = (currentVehicleType == 'cab') || (newBooking.vehicleType == currentVehicleType);
          if (ref.read(driverStatusProvider) == DriverStatus.available && isEligibleTab) {
            ref.read(currentRideRequestProvider.notifier).setRide(
                  Map<String, dynamic>.from(data as Map),
                );
            ref.read(showRequestProvider.notifier).show();
          }
        } catch (e) {
          print("Error processing new ride: $e");
        }
      });

      _rideAssignedSub?.cancel();
      _rideAssignedSub = socketService.rideAssignedStream.listen((data) {
        final currentRide = ref.read(currentRideRequestProvider);
        final takenId = data['rideId']?.toString() ?? data['bookingId']?.toString();
        if (currentRide != null && currentRide['id']?.toString() == takenId) {
          print(
              "Hiding ride request card as it was assigned to another driver");
          ref.read(showRequestProvider.notifier).hide();
          ref.read(currentRideRequestProvider.notifier).setRide(null);
        }
      });

      _rideCancelledSub?.cancel();
      _rideCancelledSub = socketService.rideCancelledStream.listen((data) {
        final currentRide = ref.read(currentRideRequestProvider);
        final cancelledId = data['rideId']?.toString() ?? data['bookingId']?.toString();
        if (currentRide != null && currentRide['id']?.toString() == cancelledId) {
          print("Hiding ride request card as it was cancelled by user");
          ref.read(showRequestProvider.notifier).hide();
          ref.read(currentRideRequestProvider.notifier).setRide(null);
        }
      });

      _fareUpdatedSub?.cancel();
      _fareUpdatedSub = socketService.fareUpdatedStream.listen((data) {
        print("Driver App Received Fare Update: $data");
        final currentRide = ref.read(currentRideRequestProvider);
        if (currentRide != null && currentRide['id'] == data['rideId']) {
          // Update the current ride request data
          final updatedRide = Map<String, dynamic>.from(currentRide);
          updatedRide['fare'] = data['newFare'];
          ref.read(currentRideRequestProvider.notifier).setRide(updatedRide);

          // Also update in BookingNotifier
          final newFareVal = data['newFare'];
          double newFareDouble = 0.0;
          if (newFareVal is num) {
            newFareDouble = newFareVal.toDouble();
          } else if (newFareVal is String) {
            newFareDouble = double.tryParse(newFareVal) ?? 0.0;
          }

          ref
              .read(bookingProvider.notifier)
              .updateBookingFare(data['rideId'], newFareDouble);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ride fare increased to ₹$newFareVal!'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });

      _statusChangeSub?.cancel();
      _statusChangeSub = socketService.statusChangeStream.listen((data) {
        print("Driver App Received Status Change via Stream: $data");
        try {
          final isOnline = data['isOnline'] == true;
          if (isOnline) {
            ref.read(driverStatusProvider.notifier).updateLocal(DriverStatus.available);
            _onlineBannerController.forward();
          } else {
            ref.read(driverStatusProvider.notifier).updateLocal(DriverStatus.offline);
            _onlineBannerController.reverse();
          }
        } catch (e) {
          print("Error updating status from socket: $e");
        }
      });
    });
  }

  @override
  void dispose() {
    _newRideSub?.cancel();
    _rideAssignedSub?.cancel();
    _rideCancelledSub?.cancel();
    _fareUpdatedSub?.cancel();
    _connectionSub?.cancel();
    _statusChangeSub?.cancel();
    _mapController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _onlineBannerController.dispose();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied");
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied forever");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    _startPositionUpdates();
  }

  void _startPositionUpdates() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Faster updates for smoother map movement
      ),
    ).listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);

        final tracking = ref.read(activeRideTrackingProvider);
        final currentBooking = ref.read(currentActiveBookingProvider);
        final activeId = tracking?.rideId ?? currentBooking?.id;
        final activeStatus = currentBooking?.status ?? 'accepted';
        if (activeId != null &&
            ['accepted', 'on_the_way', 'arrived', 'ongoing', 'in_transit']
                .contains(activeStatus)) {
          ref.read(socketServiceProvider).updateLocation(
                rideId: activeId,
                userId: tracking?.userId ?? currentBooking?.userId ?? '',
                latitude: position.latitude,
                longitude: position.longitude,
                heading: position.heading,
              );
          unawaited(() async {
            try {
              await ref.read(driverRepositoryProvider).updateLiveLocation(
                    UpdateLocationRequest(
                      lat: position.latitude,
                      lng: position.longitude,
                      heading: position.heading,
                      bookingId: activeId,
                    ),
                  );
            } catch (e) {
              debugPrint("Location sync error: $e");
            }
          }());
        }
      }
    }, onError: (error) {
      debugPrint("Geolocator stream error: $error");
    });
  }

  Future<void> _toggleOnlineStatus() async {
    final currentStatus = ref.read(driverStatusProvider);

    if (currentStatus != DriverStatus.offline) {
      ref.read(driverStatusProvider.notifier).set(DriverStatus.offline);
      ref.read(showRequestProvider.notifier).hide();
      _onlineBannerController.reverse();
    } else {
      _showStatusPicker();
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Your Status',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _statusOption(DriverStatus.available, 'Available',
                'Receive new booking requests', AppTheme.neonGreen),
            _statusOption(DriverStatus.busy, 'Busy',
                'Finish current tasks first', AppTheme.earningsAmber),
            _statusOption(DriverStatus.offline, 'Offline', 'Go off duty',
                AppTheme.offlineRed),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(
      DriverStatus status, String title, String sub, Color color) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        ref.read(driverStatusProvider.notifier).set(status);
        if (status == DriverStatus.available) {
          _onlineBannerController.forward();
        } else {
          _onlineBannerController.reverse();
          ref.read(showRequestProvider.notifier).hide();
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(
            status == DriverStatus.available
                ? Icons.check_circle
                : (status == DriverStatus.busy
                    ? Icons.schedule
                    : Icons.power_settings_new),
            color: color,
            size: 24),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(sub,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driverStatusProvider);
    final isOnline = status != DriverStatus.offline;
    final vehicleType = ref.watch(vehicleTypeProvider);
    final showRequest = ref.watch(showRequestProvider);
    final driverProfileState = ref.watch(driverProfileControllerProvider);

    return Theme(
      data: AppTheme.darkDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        drawer: _buildDrawer(context, driverProfileState, vehicleType),
        body: Stack(
          children: [
            // MAP LAYER (Always rendered immediately - never blocked by loading)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : const LatLng(19.0760, 72.8777),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.transglobe.driver_app',
                  maxZoom: 20,
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 80,
                        height: 80,
                        child: _buildDriverMarker(status, vehicleType),
                      ),
                    ],
                  ),
              ],
            ),

            // SUBTLE GPS LOCATING INDICATOR (Non-blocking)
            if (_isLoading && _currentPosition == null)
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: vehicleType.accentColor.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: vehicleType.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Locating GPS...',
                          style: TextStyle(
                            color: AppTheme.darkTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // TOP HEADER
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildProfileAvatar(driverProfileState),
                        const Spacer(),
                        StatusChip(
                          status: status,
                          onTap: _toggleOnlineStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const VehicleTypeSelector(),
                    // const SizedBox(height: 10),
                    // const VehicleSubOptions(),
                  ],
                ),
              ),
            ),

            // ONLINE STATUS BANNER (Moved to bottom for clean look)
            if (isOnline)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: SlideTransition(
                    position: _bannerSlide,
                    child: FadeTransition(
                      opacity: _bannerFade,
                      child: _buildOnlineBanner(vehicleType),
                    ),
                  ),
                ),
              ),

            // BIG GO-ONLINE BUTTON
            if (!isOnline)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(child: _buildGoOnlineButton(vehicleType)),
              ),

            // EARNINGS DASHBOARD
            // if (isOnline && !showRequest)
            //   const Positioned(
            //     bottom: 0,
            //     left: 0,
            //     right: 0,
            //     child: EarningsDashboard(),
            //   ),

            // RIDE REQUEST CARD
            if (isOnline && showRequest)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RideRequestCard(
                  rideData: ref.watch(currentRideRequestProvider),
                  onAccept: (fare) async {
                    final profileState =
                        ref.read(driverProfileControllerProvider);
                    if (profileState.data == null) return;

                    final rideData = ref.read(currentRideRequestProvider);
                    if (rideData != null) {
                      try {
                        final driverId = profileState.data!.id;
                        final bookingType = (rideData['type'] ??
                                rideData['bookingCategory'] ??
                                'CAB')
                            .toString();
                        final rideId = (rideData['id'] ?? rideData['_id'] ?? '').toString();
                        final userId = rideData['userId']?.toString() ?? '';
                        await ref.read(driverServiceProvider).acceptRide(
                              rideId,
                              fare: fare,
                              driverId: driverId,
                              bookingType: bookingType,
                            );
                        ref.read(activeRideTrackingProvider.notifier).state =
                            ActiveRideTracking(rideId: rideId, userId: userId);
                        ref.read(driverServiceProvider).setOnline(true);
                        ref.read(socketServiceProvider).joinRide(rideId);
                        ref
                            .read(bookingProvider.notifier)
                            .acceptBooking(rideId);

                        ref.read(showRequestProvider.notifier).hide();
                        ref.read(currentRideRequestProvider.notifier).setRide(null);

                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailScreen(
                              bookingId: (rideData['id'] ?? rideData['_id'] ?? '').toString(),
                            ),
                          ),
                        );
                      } catch (e) {
                        debugPrint("Error accepting ride: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not accept: $e')),
                          );
                        }
                      }
                    }
                  },
                  onDecline: () async {
                    final profileState =
                        ref.read(driverProfileControllerProvider);
                    final rideData = ref.read(currentRideRequestProvider);
                    if (profileState.data != null && rideData != null) {
                      try {
                        final bookingType = (rideData['type'] ??
                                rideData['bookingCategory'] ??
                                'CAB')
                            .toString();
                        await ref.read(driverServiceProvider).rejectRide(
                              (rideData['id'] ?? rideData['_id'] ?? '').toString(),
                              driverId: profileState.data!.id,
                              bookingType: bookingType,
                            );
                        ref
                            .read(bookingProvider.notifier)
                            .rejectBooking((rideData['id'] ?? rideData['_id'] ?? '').toString());
                      } catch (e) {
                        debugPrint("Error rejecting ride: $e");
                      }
                    }
                    ref.read(showRequestProvider.notifier).hide();
                    ref.read(currentRideRequestProvider.notifier).setRide(null);
                  },
                ),
              ),

            // CURRENT LOCATION BUTTON (Fixed & Repositioned)
            Positioned(
              right: 16,
              bottom: isOnline ? 100 : 40,
              child: _buildActionFab(
                _isLoading ? Icons.hourglass_empty : Icons.my_location,
                _getCurrentLocation,
                color: _isLoading ? AppTheme.darkTextSecondary : AppTheme.neonGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverMarker(DriverStatus status, VehicleType vehicleType) {
    final color = status == DriverStatus.available
        ? AppTheme.neonGreen
        : (status == DriverStatus.busy
            ? AppTheme.earningsAmber
            : vehicleType.accentColor);
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _glowAnim.value * 0.3),
                blurRadius: 25,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5), blurRadius: 8),
                  ],
                ),
                child: Icon(vehicleType.icon, color: Colors.white, size: 18),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(
      ApiState<DriverProfileResponseModel> driverProfileState) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => Scaffold.of(ctx).openDrawer(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: AppTheme.darkDivider.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                child: const Icon(Icons.person,
                    color: AppTheme.neonGreen, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (driverProfileState.status == ApiStatus.loading)
                      const Text('...',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.darkTextSecondary))
                    else if (driverProfileState.data != null)
                      Text(
                        driverProfileState.data!.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppTheme.darkTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      const Text('Driver',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkTextPrimary,
                              fontWeight: FontWeight.w700)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 8, color: AppTheme.earningsAmber),
                        const SizedBox(width: 2),
                        Text(
                          (driverProfileState.data?.rating != null && driverProfileState.data!.rating > 0)
                              ? driverProfileState.data!.rating.toStringAsFixed(1)
                              : '0.0',
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.earningsAmber,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.menu,
                  color: AppTheme.darkTextSecondary, size: 16),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.darkDivider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Stack(
        children: [
          const Icon(Icons.notifications_outlined,
              color: AppTheme.darkTextPrimary, size: 20),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.offlineRed,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.darkCard, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoOnlineButton(VehicleType vehicleType) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleOnlineStatus,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen
                          .withValues(alpha: 0.15 * _pulseAnim.value),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.neonGreen.withValues(alpha: 0.08),
                          AppTheme.neonGreen.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00C853)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonGreen.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_settings_new,
                                color: Colors.white, size: 32),
                            SizedBox(height: 2),
                            Text(
                              'GO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.neonGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Tap to go online as ${vehicleType.label}',
                  style: const TextStyle(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnlineBanner(VehicleType vehicleType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            vehicleType.accentColor.withValues(alpha: 0.9),
            vehicleType.accentColor,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: vehicleType.accentColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.5 + _glowAnim.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(vehicleType.icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            'ONLINE • ${vehicleType.label.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Searching...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFab(IconData icon, VoidCallback onTap, {Color? color}) {
    final themeColor = color ?? AppTheme.darkTextPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: themeColor, size: 20),
      ),
    );
  }
}

Widget _buildDrawer(BuildContext context,
    ApiState<DriverProfileResponseModel> driverProfileState,
    VehicleType vehicleType) {
  return Drawer(
    backgroundColor: AppTheme.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  vehicleType.accentColor.withValues(alpha: 0.15),
                  AppTheme.darkCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: vehicleType.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: vehicleType.accentColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: vehicleType.accentColor.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (driverProfileState.status == ApiStatus.loading)
                        const Text('...', style: TextStyle(color: Colors.white))
                      else if (driverProfileState.data != null)
                        Text(
                          driverProfileState.data!.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        )
                      else
                        const Text('Driver Name',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      const Text(
                        'Gold Member',
                        style: TextStyle(
                            color: AppTheme.earningsAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.history, 'Trips History', () {
                  Navigator.pop(context);
                }),
                _drawerItem(Icons.account_balance_wallet, 'Wallet', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.wallet);
                }),
                _drawerItem(Icons.star, 'Ratings', () {}),
                _drawerItem(Icons.help_outline, 'Support', () {}),
                _drawerItem(Icons.settings, 'Settings', () {}),
                const Divider(
                    color: AppTheme.darkDivider,
                    indent: 20,
                    endIndent: 20,
                    height: 40),
                _drawerItem(Icons.logout, 'Log Out', () {}),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
  return ListTile(
    onTap: onTap,
    leading: Icon(icon, color: AppTheme.darkTextSecondary, size: 22),
    title: Text(title,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
  );
}

// class VehicleSubOptions extends StatelessWidget {
//   const VehicleSubOptions({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 48,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: 4,
//         itemBuilder: (context, index) {
//           final labels = ['Daily', 'Rentals', 'Outstation', 'Prime'];
//           final isSelected = index == 0;
//           return Container(
//             margin: const EdgeInsets.only(right: 12),
//             child: FilterChip(
//               label: Text(labels[index]),
//               selected: isSelected,
//               onSelected: (_) {},
//               backgroundColor: AppTheme.darkCard,
//               selectedColor: AppTheme.neonGreen.withOpacity(0.2),
//               checkmarkColor: AppTheme.neonGreen,
//               labelStyle: TextStyle(
//                 color: isSelected ? AppTheme.neonGreen : AppTheme.darkTextSecondary,
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//                 side: BorderSide(
//                   color: isSelected ? AppTheme.neonGreen.withOpacity(0.5) : AppTheme.darkDivider,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
