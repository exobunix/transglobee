import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/core/theme.dart';
import 'package:driver_app/models/booking_model.dart';
import 'package:driver_app/providers/booking_provider.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:driver_app/services/auth_service.dart';
import 'package:driver_app/screens/chat/chat_screen.dart';
import 'package:driver_app/screens/booking/booking_detail_screen.dart';
import 'package:driver_app/screens/booking/active_ride_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});
  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with TickerProviderStateMixin {
  late TabController _vehicleTabs;

  @override
  void initState() {
    super.initState();
    _vehicleTabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _vehicleTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        toolbarHeight: 0, // Hide app bar part but keep bottom
        bottom: TabBar(
          controller: _vehicleTabs,
          labelColor: AppTheme.neonGreen,
          unselectedLabelColor: AppTheme.darkTextSecondary,
          indicatorColor: AppTheme.neonGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'CABS', icon: Icon(Icons.local_taxi, size: 20)),
            Tab(text: 'BUS', icon: Icon(Icons.directions_bus, size: 20)),
            Tab(text: 'LOGISTICS', icon: Icon(Icons.local_shipping, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _vehicleTabs,
        children: const [
          BookingsTabContent(filterVehicleType: 'cab'),
          BookingsTabContent(filterVehicleType: 'bus'),
          BookingsTabContent(filterVehicleType: 'truck'),
        ],
      ),
    );
  }
}

class BookingsTabContent extends ConsumerStatefulWidget {
  final String filterVehicleType;
  const BookingsTabContent({super.key, required this.filterVehicleType});

  @override
  ConsumerState<BookingsTabContent> createState() => _BookingsTabContentState();
}

class _BookingsTabContentState extends ConsumerState<BookingsTabContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _statusTabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _statusTabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _statusTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var pending = ref.watch(pendingBookingsProvider);
    var active = ref.watch(activeBookingsProvider);
    var history = ref.watch(historyBookingsProvider);

    pending = pending.where((b) => b.vehicleType == widget.filterVehicleType).toList();
    active = active.where((b) => b.vehicleType == widget.filterVehicleType).toList();
    history = history.where((b) => b.vehicleType == widget.filterVehicleType).toList();

    return Column(
      children: [
        Container(
          color: AppTheme.darkSurface.withValues(alpha: 0.5),
          child: TabBar(
            controller: _statusTabs,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppTheme.neonGreen,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Active (${active.length})'),
              Tab(text: 'History (${history.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _statusTabs,
            children: [
              RefreshIndicator(
                onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
                color: AppTheme.neonGreen,
                child: _buildPendingList(pending),
              ),
              RefreshIndicator(
                onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
                color: AppTheme.neonGreen,
                child: _buildActiveList(active),
              ),
              RefreshIndicator(
                onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
                color: AppTheme.neonGreen,
                child: _buildHistoryList(history),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No pending requests', Icons.inbox_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _PendingBookingCard(booking: bookings[i], tabs: _statusTabs),
    );
  }

  Widget _buildActiveList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No active trips', Icons.directions_car_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _ActiveBookingCard(booking: bookings[i]),
    );
  }

  Widget _buildHistoryList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No trip history yet', Icons.history);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _HistoryBookingCard(booking: bookings[i]),
    );
  }

  Widget _buildEmpty(String msg, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppTheme.darkDivider),
                const SizedBox(height: 12),
                Text(msg, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pending Booking Card ──
class _PendingBookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final TabController tabs;
  const _PendingBookingCard({required this.booking, required this.tabs});
  @override
  ConsumerState<_PendingBookingCard> createState() => _PendingBookingCardState();
}

class _PendingBookingCardState extends ConsumerState<_PendingBookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final displayFare = b.getFareForDriver(driverDbId, driverFbId);
    final displayPickup = b.getPickupAddressForDriver(driverDbId, driverFbId);
    final displayDrop = b.getDropAddressForDriver(driverDbId, driverFbId);
    final displayDistance = b.getDistanceForDriver(driverDbId, driverFbId);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
      child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: b.vehicleType == 'truck' ? AppTheme.truckOrange.withValues(alpha: 0.3) : AppTheme.earningsAmber.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: (b.vehicleType == 'truck' ? AppTheme.truckOrange : AppTheme.earningsAmber).withValues(alpha: 0.08), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _TypeBadge(b.vehicleType, b.subType),
                  const SizedBox(width: 8),
                  Text('#ID: ${b.id.substring(b.id.length > 6 ? b.id.length - 6 : 0)}', style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.earningsAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('₹${displayFare.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteRow(displayPickup, displayDrop),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (b.railwayStation != null) ...[
                      _InfoChip(Icons.train_outlined, 'STATION: ${b.railwayStation}', color: AppTheme.neonGreen),
                      const SizedBox(width: 8),
                    ],
                    _InfoChip(Icons.route, '${displayDistance.toStringAsFixed(1)} km'),
                    const SizedBox(width: 8),
                    if (b.estimatedTime != null && b.estimatedTime!.isNotEmpty) ...[
                      _InfoChip(Icons.access_time, b.estimatedTime!, color: AppTheme.earningsAmber),
                      const SizedBox(width: 8),
                    ],
                    if (b.estimatedDate != null && b.estimatedDate!.isNotEmpty) ...[
                      _InfoChip(Icons.calendar_today, b.estimatedDate!, color: AppTheme.cabBlue),
                      const SizedBox(width: 8),
                    ],
                    _InfoChip(Icons.person, b.userName),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.phone, b.userPhone),
                    if (b.transportName != null || b.transportNumber != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        b.vehicleType == 'truck' ? Icons.local_shipping : Icons.info_outline,
                        '${b.transportName ?? ""} ${b.transportNumber ?? ""}'.trim(),
                        color: AppTheme.truckOrange,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(bookingProvider.notifier).rejectBooking(b.id),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.offlineRed, side: BorderSide(color: AppTheme.offlineRed.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(bookingProvider.notifier).acceptBooking(b.id);
                          
                          // Switch to Active Tab internally
                          widget.tabs.animateTo(1);
                          
                          // Navigate to detail screen immediately
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(bookingId: b.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Accept',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                    ),
                  ),
                ],
              ),
            ],
        ),
      ),
    );
  }
}

// ── Active Booking Card ──
class _ActiveBookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _ActiveBookingCard({required this.booking});

  final _statuses = const ['accepted', 'on_the_way', 'arrived', 'started', 'completed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final displayPickup = b.getPickupAddressForDriver(driverDbId, driverFbId);
    final displayDrop = b.getDropAddressForDriver(driverDbId, driverFbId);
    
    // Calculate progress (0-4)
    int statusIdx = 0;
    if (b.status == 'accepted' || b.status == 'confirmed') {
      statusIdx = 0;
    } else if (b.status == 'on_the_way') statusIdx = 1;
    else if (b.status == 'arrived') statusIdx = 2;
    else if (b.status == 'ongoing' || b.status == 'in_transit') statusIdx = 3;
    else if (b.status == 'completed' || b.status == 'delivered') statusIdx = 4;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppTheme.neonGreen.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(b.vehicleType, b.subType),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(b.status), style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _RouteRow(displayPickup, displayDrop),
          if (b.railwayStation != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.train_outlined, color: AppTheme.neonGreen, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('VIA STATION: ${b.railwayStation}', 
                    style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          if (b.transportName != null || b.transportNumber != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  b.subType.toLowerCase().contains('train') ? Icons.train :
                  b.subType.toLowerCase().contains('flight') ? Icons.flight :
                  b.subType.toLowerCase().contains('sea') ? Icons.directions_boat :
                  Icons.local_shipping,
                  color: AppTheme.truckOrange,
                  size: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${b.subType.toUpperCase()} DETAILS: ${b.transportName ?? ""} - ${b.transportNumber ?? ""}'.trim().replaceAll(' - ', ' '), 
                    style: const TextStyle(color: AppTheme.truckOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          if (b.estimatedTime != null && b.estimatedTime!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.earningsAmber, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('ESTIMATED TIME: ${b.estimatedTime}', 
                    style: const TextStyle(color: AppTheme.earningsAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          if (b.estimatedDate != null && b.estimatedDate!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.cabBlue, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('ESTIMATED DATE: ${b.estimatedDate}', 
                    style: const TextStyle(color: AppTheme.cabBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Progress steps
          _buildProgressBar(statusIdx),
          const SizedBox(height: 14),
          // Action buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final driverProfile = ref.read(driverProfileProvider).value;
                        if (driverProfile == null) return;
            
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiverId: b.userId ?? '',
                              receiverName: b.userName,
                              driverId: driverProfile.id,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.neonGreen, side: BorderSide(color: AppTheme.neonGreen.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(b),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cabBlue, side: BorderSide(color: AppTheme.cabBlue.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Nav', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: () {
                        // All accepted statuses (accepted/confirmed/arrived) should allow 
                        // going to details/OTP screen if it's not ongoing yet.
                        if (['accepted', 'confirmed', 'arrived', 'on_the_way'].contains(b.status)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveRideScreen(booking: b),
                            ),
                          );
                        } else {
                          _advanceStatus(ref, b);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: Text(_nextAction(b.status), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    const m = {'accepted': 'Accepted', 'on_the_way': 'On the Way', 'arrived': 'Arrived', 'ongoing': 'In Progress', 'confirmed': 'Confirmed', 'in_transit': 'In Transit'};
    return m[s] ?? s;
  }

  String _nextAction(String s) {
    const m = {'accepted': 'On Way', 'on_the_way': 'Arrived', 'arrived': 'Start Trip', 'ongoing': 'Complete', 'confirmed': 'Start Transit', 'in_transit': 'Deliver'};
    return m[s] ?? 'Update';
  }

  void _openMap(BookingModel b) async {
    final lat = (b.status == 'ongoing' || b.status == 'in_transit') ? b.dropLat : b.pickupLat;
    final lng = (b.status == 'ongoing' || b.status == 'in_transit') ? b.dropLng : b.pickupLng;
    
    if (lat == null || lng == null) return;
    
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _advanceStatus(WidgetRef ref, BookingModel b) {
    const next = {'accepted': 'on_the_way', 'on_the_way': 'arrived', 'arrived': 'ongoing', 'ongoing': 'completed', 'confirmed': 'in_transit', 'in_transit': 'delivered'};
    if (next.containsKey(b.status)) {
      ref.read(bookingProvider.notifier).updateStatus(b.id, next[b.status]!);
    }
  }

  Widget _buildProgressBar(int idx) {
    final labels = ['Accepted', 'On Way', 'Arrived', 'Started', 'Done'];
    return Row(
      children: List.generate(5, (i) {
        final done = i <= idx;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: Container(height: 3, color: done ? AppTheme.neonGreen : AppTheme.darkDivider)),
              if (i < 4) const SizedBox(width: 0),
            ],
          ),
        );
      }),
    );
  }

  void _showDelaySheet(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Delay Reason', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Heavy Traffic', 'Vehicle Issue', 'Loading Delay', 'Breakdown', 'Weather', 'Road Block', 'Wrong Route', 'Other'].map((r) =>
                GestureDetector(
                  onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delay reported: $r'), backgroundColor: AppTheme.truckOrange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppTheme.darkDivider)),
                    child: Text(r, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w500)),
                  ),
                )
              ).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── History Booking Card ──
class _HistoryBookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _HistoryBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    final driverProfile = ref.watch(driverProfileProvider).value;
    final driverDbId = driverProfile?.id;
    final driverFbId = driverProfile?.firebaseId ?? ref.watch(authServiceProvider).currentUser?.uid;
    
    final displayFare = b.getFareForDriver(driverDbId, driverFbId);
    final displayPickup = b.getPickupAddressForDriver(driverDbId, driverFbId);
    final displayDrop = b.getDropAddressForDriver(driverDbId, driverFbId);

    final isRejected = b.status == 'rejected';
    final isAccepted = b.status == 'accepted' || b.status == 'confirmed';
    final isCompleted = b.status == 'completed' || b.status == 'delivered';
    
    Color statusColor = AppTheme.neonGreen;
    IconData statusIcon = Icons.check_circle;
    
    if (isRejected) {
      statusColor = AppTheme.offlineRed;
      statusIcon = Icons.cancel;
    } else if (isAccepted) {
      statusColor = AppTheme.cabBlue;
      statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkDivider.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(b.userName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${displayPickup.split(',').first} → ${displayDrop.split(',').first}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (b.railwayStation != null) ...[
                  const SizedBox(height: 2),
                  Text('Via: ${b.railwayStation}', style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 4),
                Text(_formatTime(b.createdAt), style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${displayFare.toStringAsFixed(0)}', style: TextStyle(color: isCompleted ? AppTheme.earningsAmber : AppTheme.offlineRed, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              if (b.userRating != null)
                Row(children: [
                  const Icon(Icons.star, size: 12, color: AppTheme.earningsAmber),
                  const SizedBox(width: 2),
                  Text(b.userRating!.toString(), style: const TextStyle(color: AppTheme.earningsAmber, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Shared helper widgets ──
class _TypeBadge extends StatelessWidget {
  final String type;
  final String sub;
  const _TypeBadge(this.type, this.sub);

  @override
  Widget build(BuildContext context) {
    IconData icon = type == 'cab' ? Icons.local_taxi : type == 'truck' ? Icons.local_shipping : Icons.directions_bus;
    final subLower = sub.toLowerCase();
    
    if (type == 'truck') {
      if (subLower.contains('train')) {
        icon = Icons.train;
      } else if (subLower.contains('flight') || subLower.contains('air')) icon = Icons.flight;
      else if (subLower.contains('ship') || subLower.contains('cargo')) icon = Icons.directions_boat;
      else if (subLower.contains('express')) icon = Icons.bolt;
    }

    final color = type == 'cab' ? AppTheme.cabBlue : type == 'truck' ? AppTheme.truckOrange : AppTheme.busPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(sub, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup, drop;
  const _RouteRow(this.pickup, this.drop);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.darkSurface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.trip_origin, color: AppTheme.neonGreen, size: 14),
            const SizedBox(width: 10),
            Expanded(child: Text(pickup, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
            child: Row(children: [Container(width: 2, height: 14, color: AppTheme.darkDivider)]),
          ),
          Row(children: [
            const Icon(Icons.location_on, color: AppTheme.offlineRed, size: 14),
            const SizedBox(width: 10),
            Expanded(child: Text(drop, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color ?? AppTheme.darkTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color ?? AppTheme.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
