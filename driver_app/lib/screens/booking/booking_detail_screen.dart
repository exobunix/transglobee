import 'package:driver_app/services/rest_api_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:driver_app/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/screens/chat/chat_screen.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:driver_app/services/socket_service.dart';
import 'package:driver_app/services/auth_service.dart';
import '../../core/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../widgets/delay_reason_sheet.dart';
import '../navigation/navigation_screen.dart';
import 'active_ride_screen.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  BookingModel? _cachedBooking;
  Future<BookingModel?>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).joinRide(widget.bookingId);
    });
    
    // Check if the booking is already in local providers
    final pending = ref.read(pendingBookingsProvider);
    final active = ref.read(activeBookingsProvider);
    final history = ref.read(historyBookingsProvider);
    final allBookings = [...pending, ...active, ...history];
    final found = allBookings.any((b) => b.id == widget.bookingId);
    
    if (!found) {
      _fetchFuture = _loadBookingFromServer();
    }
  }

  Future<BookingModel?> _loadBookingFromServer() async {
    try {
      final repo = ref.read(restApiRepositoryProvider);
      final res = await repo.getBookingById(widget.bookingId);
      if (res.success && res.data != null) {
        ref.read(bookingProvider.notifier).addBooking(res.data!);
        return res.data;
      }
    } catch (e) {
      debugPrint('Error loading booking from server: $e');
    }
    return null;
  }

  Widget _buildNotFoundScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Trip Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.darkTextSecondary, size: 48),
            const SizedBox(height: 16),
            const Text('Trip not found or still loading...', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('GO BACK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: AppTheme.darkBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingBookingsProvider);
    final active = ref.watch(activeBookingsProvider);
    final history = ref.watch(historyBookingsProvider);
    final allBookings = [...pending, ...active, ...history];

    final booking = allBookings.cast<BookingModel?>().firstWhere(
      (b) => b?.id == widget.bookingId,
      orElse: () => null,
    );

    // Update cache if we found a match
    if (booking != null) {
      _cachedBooking = booking;
    }

    // Use cached data if available, even if currently missing from provider
    final displayBooking = booking ?? _cachedBooking;

    if (displayBooking == null) {
      if (_fetchFuture != null) {
        return FutureBuilder<BookingModel?>(
          future: _fetchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.darkBg,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.neonGreen),
                ),
              );
            }
            final fetched = snapshot.data;
            if (fetched != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _cachedBooking = fetched;
                });
              });
            }
            return _buildNotFoundScreen(context);
          },
        );
      }
      return _buildNotFoundScreen(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Trip Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(displayBooking),
            const SizedBox(height: 24),
            _buildPassengerCard(context, ref, displayBooking),
            const SizedBox(height: 24),
            _buildRouteCard(displayBooking),
            const SizedBox(height: 24),
            _buildFareBreakdown(displayBooking),
            const SizedBox(height: 24),

            if (displayBooking.railwayStation != null)
              _buildDispatchInfo(displayBooking),

            const SizedBox(height: 40),
            
            if (displayBooking.status != 'completed' && displayBooking.status != 'cancelled')
              _buildActionButtons(context, ref, displayBooking),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppTheme.neonGreen, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Status', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                Text(
                  booking.status.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(color: AppTheme.neonGreen, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchInfo(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.train_rounded, color: AppTheme.neonGreen, size: 24),
              SizedBox(width: 12),
              Text('DISPATCH INSTRUCTION', 
                style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Admin has selected ${booking.railwayStation} as your transit station for this logistics trip.',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Proceed to this station after picking up the goods.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(BuildContext context, WidgetRef ref, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.cabBlue,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.userName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.earningsAmber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      booking.userRating != null && booking.userRating! > 0
                          ? booking.userRating!.toStringAsFixed(1)
                          : '5.0',
                      style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.neonGreen),
            onPressed: () async {
              final Uri url = Uri(scheme: 'tel', path: booking.userPhone);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.cabBlue),
            onPressed: () {
              final driverProfile = ref.read(driverProfileProvider).value;
              if (driverProfile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: booking.userId ?? '',
                      receiverName: booking.userName,
                      receiverPhone: booking.userPhone,
                      driverId: driverProfile.id,
                      bookingId: booking.id,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BookingModel booking) {
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final pickup = booking.getPickupAddressForDriver(driverDbId, driverFbId);
    final drop = booking.getDropAddressForDriver(driverDbId, driverFbId);
    final hasSegment = booking.dispatchType == 'LOGISTICS' && 
                       (driverDbId != null || driverFbId != null) && 
                       booking.segments.any((s) => s.driverId == driverDbId || s.driverId == driverFbId);
    final detailsPickup = hasSegment ? null : booking.pickupDetails;
    final detailsDrop = hasSegment ? null : booking.dropDetails;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        children: [
          _routeItem(Icons.trip_origin, AppTheme.neonGreen, 'Pickup', pickup, details: detailsPickup),
          
          if (booking.railwayStation != null) ...[
             const SizedBox(height: 12),
             Row(
               children: [
                 const SizedBox(width: 11),
                 Container(width: 2, height: 16, color: AppTheme.darkDivider),
                 const SizedBox(width: 16),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                   decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: Row(
                     children: [
                       const Icon(Icons.train, color: AppTheme.neonGreen, size: 14),
                       const SizedBox(width: 8),
                       Text('STATION: ${booking.railwayStation}', 
                         style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
          ] else
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 4),
               child: Row(
                 children: [
                   const SizedBox(width: 11),
                   Column(children: List.generate(4, (i) => Container(width: 2, height: 4, margin: const EdgeInsets.symmetric(vertical: 2), color: AppTheme.darkDivider))),
                 ],
               ),
             ),

          _routeItem(Icons.location_on, AppTheme.offlineRed, 'Drop-off', drop, details: detailsDrop),
        ],
      ),
    );
  }

  Widget _routeItem(IconData icon, Color color, String label, String address, {Map<String, dynamic>? details}) {
    final house = details?['house']?.toString();
    final floor = details?['floor']?.toString();
    final landmark = details?['landmark']?.toString();
    final cityPincode = [details?['city'], details?['pincode']].where((e) => e != null).join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
              Text(address, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              
              if (details != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (house != null && house.isNotEmpty) _detailBadge('House: $house'),
                    if (floor != null && floor.isNotEmpty) _detailBadge('Floor: $floor'),
                    if (cityPincode.isNotEmpty) _detailBadge(cityPincode),
                    if (landmark != null && landmark.isNotEmpty) 
                      Row(
                        children: [
                          const Icon(Icons.near_me, size: 10, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(landmark, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }

  Widget _buildFareBreakdown(BookingModel booking) {
    final driverId = ref.watch(authServiceProvider).currentUser?.uid;
    final fare = booking.getFareForDriver(driverId);
    final distance = booking.getDistanceForDriver(driverId);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Est. Fare', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('₹${fare.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Distance', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Type', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('Cash', style: TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingModel booking) {
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final pickup = booking.getPickupAddressForDriver(driverDbId, driverFbId);
    final drop = booking.getDropAddressForDriver(driverDbId, driverFbId);
    final hasSegment = booking.dispatchType == 'LOGISTICS' && 
                       (driverDbId != null || driverFbId != null) && 
                       booking.segments.any((s) => s.driverId == driverDbId || s.driverId == driverFbId);
    final detailsPickup = hasSegment ? null : booking.pickupDetails;

    return Column(
      children: [
        // Acceptance Preview (Specifically for Pending/Broadcast bookings)
        if (booking.status == 'pending') ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.neonGreen, size: 16),
                    SizedBox(width: 8),
                    Text('PICK-UP INFO', 
                      style: TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(pickup, 
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                if (detailsPickup != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${detailsPickup['house'] != null ? "House: ${detailsPickup['house']} " : ""}${detailsPickup['floor'] != null ? "Floor: ${detailsPickup['floor']} " : ""}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
                if (booking.railwayStation != null) ...[
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    children: [
                      const Icon(Icons.train_rounded, color: AppTheme.neonGreen, size: 16),
                      const SizedBox(width: 10),
                      Text('Target Station: ${booking.railwayStation}', 
                        style: const TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              // Logic to advance status
              if (booking.status == 'pending') {
                ref.read(bookingControllerProvider.notifier).acceptBooking(booking.id);
                ref.read(bookingProvider.notifier).acceptBooking(booking.id); // Sync legacy provider for now
                // Detail screen will update automatically via provider
                return;
              }
              
              if (['accepted', 'on_the_way', 'arrived'].contains(booking.status)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveRideScreen(booking: booking),
                  ),
                );
              } else {
                String nextStatus = '';
                if (booking.status == 'ongoing') nextStatus = 'completed';
                
                if (nextStatus == 'completed') {
                  if (booking.paymentStatus == 'unpaid') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Waiting for customer payment...'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    _showCompleteTripDialog(context, ref, booking);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              booking.status == 'pending' ? 'ACCEPT & PROCEED' : _buttonLabel(booking.status, booking.paymentStatus),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DelayReasonSheet(onReasonSelected: (r) {}),
                  );
                },
                icon: const Icon(Icons.report_problem_outlined, size: 20),
                label: const Text('REPORT DELAY'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.truckOrange,
                  side: const BorderSide(color: AppTheme.truckOrange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  gmaps.LatLng? dest;
                  String destName = '';

                  if (['accepted', 'on_the_way'].contains(booking.status)) {
                    dest = gmaps.LatLng(
                      booking.getPickupLatForDriver(driverDbId, driverFbId) ?? 26.8467, 
                      booking.getPickupLngForDriver(driverDbId, driverFbId) ?? 80.9462
                    );
                    destName = 'Pickup: $pickup';
                  } else {
                    dest = gmaps.LatLng(
                      booking.getDropLatForDriver(driverDbId, driverFbId) ?? 26.8467, 
                      booking.getDropLngForDriver(driverDbId, driverFbId) ?? 80.9462
                    );
                    destName = 'Drop: $drop';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        destination: dest!,
                        destinationName: destName,
                        rideId: booking.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_outlined, size: 20),
                label: const Text('NAVIGATE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.cabBlue,
                  side: const BorderSide(color: AppTheme.cabBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        if (booking.status != 'pending') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelTripDialog(context, ref, booking),
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.offlineRed, size: 20),
              label: const Text('CANCEL RIDE', style: TextStyle(color: AppTheme.offlineRed, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.offlineRed, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelTripDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Ride', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this ride?', style: TextStyle(color: AppTheme.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO', style: TextStyle(color: AppTheme.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ref.read(bookingProvider.notifier).updateStatus(booking.id, 'cancelled');
                if (context.mounted) {
                  Navigator.pop(context); // Go back
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling ride: $e'), backgroundColor: AppTheme.offlineRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.offlineRed, foregroundColor: Colors.white),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  String _buttonLabel(String status, String paymentStatus) {
    switch (status) {
      case 'accepted': 
      case 'on_the_way': 
      case 'arrived': return 'VERIFY OTP & START';
      case 'ongoing': return paymentStatus == 'paid' ? 'COMPLETE TRIP' : 'WAIT FOR PAYMENT';
      default: return 'CONTINUE';
    }
  }

  void _showCompleteTripDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    final controller = TextEditingController(text: booking.fare.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Complete Trip', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm final fare amount:', style: TextStyle(color: AppTheme.darkTextSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.neonGreen, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppTheme.neonGreen, fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.darkDivider)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final fare = double.tryParse(controller.text) ?? booking.fare;
              // Call API #12
              await ref.read(bookingControllerProvider.notifier).completeTrip(
                booking.id, 
                booking.distanceKm, // Use actual distance from booking
                20,   // Placeholder duration
                bookingType: booking.dispatchType,
              );
              ref.read(bookingProvider.notifier).completeTrip(booking.id, fare);
              ref.read(chatProvider.notifier).clearChat();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: AppTheme.darkBg),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }
}
