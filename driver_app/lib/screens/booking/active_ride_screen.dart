import 'dart:async';

import 'package:driver_app/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../services/driver_service.dart';
import '../chat/chat_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'items_verification_screen.dart';
import '../../services/auth_service.dart';
import '../../features/driver/controllers/driver_providers.dart';
class ActiveRideScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const ActiveRideScreen({super.key, required this.booking});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  final List<TextEditingController> _otpControllers = 
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  StreamSubscription? _paymentSubscription;
  StreamSubscription? _rideCancelledSubscription;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.joinRide(widget.booking.id);
      
      _paymentSubscription = socketService.paymentRequestedStream.listen((data) {
        if (data['rideId']?.toString() == widget.booking.id.toString() && mounted) {
          _showPaymentQR(context);
        }
      });

      _rideCancelledSubscription = socketService.rideCancelledStream.listen((data) {
        final cancelledId = data['rideId']?.toString() ?? data['bookingId']?.toString();
        if (cancelledId == widget.booking.id.toString() && mounted) {
          final ride = data['ride'] as Map?;
          _showCancellationSummaryDialog(ride != null ? Map<String, dynamic>.from(ride) : null);
        }
      });
    });
  }

  void _showCancellationSummaryDialog(Map<String, dynamic>? rideData) {
    final reason = rideData?['cancelReason'] ?? 'Cancelled by user';
    final distance = rideData?['distanceTravelled'] ?? 0.0;
    final fare = rideData?['fare'] ?? rideData?['cancellationFare'] ?? rideData?['totalPrice'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            const Text("Ride Cancelled", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "The user has cancelled this ride.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _summaryItem("Reason", reason.toString()),
            _summaryItem("Distance reached", "$distance km"),
            _summaryItem("Your Earnings", "₹$fare"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _loadRoute() async {
    // Identify if this driver is assigned to a specific segment
    final driverProfile = ref.read(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.read(authServiceProvider).currentUser?.uid;
    
    final mySegment = widget.booking.segments.cast<BookingSegment?>().firstWhere(
      (s) => s?.driverId == driverDbId || s?.driverId == driverFbId,
      orElse: () => null,
    );

    final pLat = mySegment?.start['lat'] ?? widget.booking.pickupLat;
    final pLng = mySegment?.start['lng'] ?? widget.booking.pickupLng;
    final dLat = mySegment?.end['lat'] ?? widget.booking.dropLat;
    final dLng = mySegment?.end['lng'] ?? widget.booking.dropLng;

    if (pLat == null || pLng == null || dLat == null || dLng == null) return;

    final start = LatLng(pLat, pLng);
    final end = LatLng(dLat, dLng);

    try {
      final routeData = await LocationService.getRouteData(start, end);
      if (mounted) {
        setState(() {
          _routePoints = routeData['points'];
        });
        
        // Fit bounds
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading route for driver: $e");
    }
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _rideCancelledSubscription?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      _showSnackBar('Please enter 4-digit OTP', isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ref.read(bookingControllerProvider.notifier).startTrip(widget.booking.id, otp);
      await ref.read(bookingProvider.notifier).verifyOtp(widget.booking.id, otp);
      if (mounted) {
        if (widget.booking.items != null && widget.booking.items!.isNotEmpty) {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(
               builder: (_) => ItemsVerificationScreen(booking: widget.booking),
             ),
           );
        } else {
           _showSnackBar('Ride started successfully!');
           _openMap(); 
           Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Invalid OTP. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar('Could not launch dialer', isError: true);
    }
  }

  void _openMap() async {
    final lat = widget.booking.dropLat;
    final lng = widget.booking.dropLng;
    if (lat == null || lng == null) return;
    
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _increaseFare(int increment) {
    final newFare = widget.booking.fare + increment;
    ref.read(socketServiceProvider).updateFare(widget.booking.id, increment, newFare);
    _showSnackBar('Fare increased by ₹$increment');
  }

  Widget _fareButton(int amount) {
    return GestureDetector(
      onTap: () => _increaseFare(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Text(
          '+$amount',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final displayFare = widget.booking.getFareForDriver(driverDbId, driverFbId);
    final displayPickup = widget.booking.getPickupAddressForDriver(driverDbId, driverFbId);
    final displayDrop = widget.booking.getDropAddressForDriver(driverDbId, driverFbId);
    final displayDistance = widget.booking.getDistanceForDriver(driverDbId, driverFbId);

    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      body: Column(
        children: [
          // Map at the top
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                        widget.booking.pickupLat ?? 0, widget.booking.pickupLng ?? 0),
                    initialZoom: 14,
                  ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Colors.black,
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routePoints.isNotEmpty ? _routePoints.first : LatLng(widget.booking.pickupLat ?? 0, widget.booking.pickupLng ?? 0),
                            width: 200,
                            height: 60,
                            child: _buildMapLabel(
                              displayPickup, 
                              true
                            ),
                          ),
                          Marker(
                            point: _routePoints.isNotEmpty ? _routePoints.last : LatLng(widget.booking.dropLat ?? 0, widget.booking.dropLng ?? 0),
                            width: 200,
                            height: 60,
                            child: _buildMapLabel(
                              displayDrop, 
                              false
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Ride Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E212D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[800],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.booking.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      widget.booking.userPhone,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        widget.booking.subType.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _makeCall(widget.booking.userPhone),
                              icon: const Icon(Icons.call, color: Color(0xFF00E676)),
                            ),
                            IconButton(
                              onPressed: () {
                                final driverProfile = ref.read(driverProfileProvider).value;
                                if (driverProfile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        receiverId: widget.booking.userId ?? '',
                                        receiverName: widget.booking.userName,
                                        driverId: driverProfile.id,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${displayFare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFBC02D),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _fareButton(10),
                                    const SizedBox(width: 4),
                                    _fareButton(20),
                                    const SizedBox(width: 4),
                                    _fareButton(30),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${displayDistance.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (widget.booking.railwayStation != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.train, color: Color(0xFF00E676), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ASSIGNED TRANSIT HUB', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text(widget.booking.railwayStation!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.booking.transportName != null || widget.booking.transportNumber != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                widget.booking.subType.toLowerCase().contains('train') ? Icons.train :
                                widget.booking.subType.toLowerCase().contains('flight') ? Icons.flight :
                                widget.booking.subType.toLowerCase().contains('sea') ? Icons.directions_boat :
                                Icons.local_shipping,
                                color: Colors.amber, 
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${widget.booking.subType.toUpperCase()} DETAILS', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text('${widget.booking.transportName ?? ""} ${widget.booking.transportNumber ?? ""}'.trim(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Route Locations
                        Stack(
                          children: [
                            Positioned(
                              left: 11,
                              top: 20,
                              bottom: 20,
                              child: Container(
                                width: 2,
                                color: Colors.grey[700],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLocationRow(
                                  const Color(0xFF00E676), 
                                  'PICKUP', 
                                  displayPickup
                                ),
                                const SizedBox(height: 24),
                                _buildLocationRow(
                                  Colors.red, 
                                  'DROP-OFF', 
                                  displayDrop
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (widget.booking.items != null && widget.booking.items!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 20),
                          _buildItemsSection(widget.booking.items!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // OTP Section (Only if not started)
                  if (widget.booking.status != 'ongoing' && widget.booking.status != 'completed')
                  Column(
                    children: [
                      const Text(
                        'Enter OTP to Start Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask the customer for the 4-digit code',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 56,
                            height: 64,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '-',
                                hintStyle: TextStyle(color: Colors.grey[700]),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[800]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF00E676)),
                                ),
                                fillColor: const Color(0xFF1E212D),
                                filled: true,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 3) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                if (value.isNotEmpty && index == 3) {
                                  _verifyOtp();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Ongoing Trip Section (Payment QR Button)
                   if (widget.booking.status == 'ongoing')
                   Column(
                    children: [
                       const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 48),
                       const SizedBox(height: 16),
                       const Text(
                        'Trip In Progress',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           ElevatedButton.icon(
                             onPressed: () => _showPaymentQR(context),
                             icon: const Icon(Icons.qr_code, color: Colors.black, size: 18),
                             label: const Text('PAYMENT QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.amber,
                               foregroundColor: Colors.black,
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                           const SizedBox(width: 12),
                           ElevatedButton.icon(
                             onPressed: () => _showCompleteTripDialog(context, ref, widget.booking),
                             icon: const Icon(Icons.done_all, color: Colors.black, size: 18),
                             label: const Text('COMPLETE TRIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF00E676),
                               foregroundColor: Colors.black,
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ],
                       ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.booking.status == 'ongoing' ? null : Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isVerifying
                ? const CircularProgressIndicator(color: Colors.black)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ITEMS TO TRANSPORT',
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF00E676)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['itemName']?.toString().toUpperCase() ?? 'UNNAMED ITEM',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Category: ${item['type'] ?? 'General'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showItemsSummaryDialog(BuildContext context, List<dynamic> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 60),
            const SizedBox(height: 20),
            const Text('ITEMS VERIFIED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Collection of ${items.length} items confirmed', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const Divider(height: 32, color: Colors.white12),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFF00E676)),
                const SizedBox(width: 10),
                Text(i['itemName']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
          ],
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _openMap(); // Open map
        Navigator.pop(context); // Back to previous screen or forward? 
        // Likely we want to stay on this screen if it's ongoing or go back.
        // The notifier update status will rebuild it.
      }
    });
  }

  void _showCompleteTripDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    final controller = TextEditingController(text: booking.fare.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Complete Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm final fare amount:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: Color(0xFF00E676), fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final fare = double.tryParse(controller.text) ?? booking.fare;
              await ref.read(bookingControllerProvider.notifier).completeTrip(
                booking.id, 
                booking.distanceKm, 
                20,   
                bookingType: booking.dispatchType,
              );
              ref.read(bookingProvider.notifier).completeTrip(booking.id, fare);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  void _showPaymentQR(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E212D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAYMENT QR',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: "upi://pay?pa=transglobe@upi&pn=Transglobe&am=${widget.booking.fare}&cu=INR",
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Amount to Collect: ₹${widget.booking.fare}',
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for customer payment...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1E212D),
          ),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: label == 'Pickup' ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: label == 'Pickup' ? null : BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapLabel(String name, bool isPickup) {
    String cleanName = name.contains(',') ? name.split(',')[0] : name;
    if (isPickup) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("2", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("min", style: TextStyle(color: Colors.white, fontSize: 8)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          cleanName, 
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
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
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    cleanName, 
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 2)),
          ),
        ],
      );
    }
  }
}
