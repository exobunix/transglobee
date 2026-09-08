import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/booking_model.dart';
import '../providers/api_state_providers.dart';
import '../services/rest_api_repository.dart';
import 'home_screen.dart'; // import navigateToRideTracking

class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _resolveBookingLabel(Map<String, dynamic> ride) {
    final display = ride['displayType']?.toString();
    if (display != null && display.isNotEmpty) return display.toUpperCase();

    final category = (ride['bookingCategory'] ?? ride['type'] ?? '')
        .toString()
        .toLowerCase();
    if (category == 'cab' ||
        ride['rideMode'] != null && ride['locations'] is List) {
      return 'CAB';
    }
    if (category == 'shuttle') return 'SHUTTLE';
    if (category == 'logistics' || ride['items'] is List) return 'LOGISTICS';

    final vehicle = (ride['vehicleType'] ?? ride['rideMode'] ?? '')
        .toString()
        .toLowerCase();
    if (vehicle.contains('bus') || vehicle.contains('shuttle'))
      return 'SHUTTLE';
    if (vehicle.contains('truck') ||
        vehicle.contains('train') ||
        vehicle.contains('flight') ||
        vehicle.contains('cargo') ||
        vehicle.contains('logistics')) {
      return 'LOGISTICS';
    }
    if (rideModelHasCabShape(ride)) return 'CAB';
    return 'RIDE';
  }

  bool rideModelHasCabShape(Map<String, dynamic> ride) {
    return ride['locations'] is List && (ride['locations'] as List).length >= 2;
  }

  Map<String, dynamic> _formatRide(BookingModel rideModel) {
    final ride = rideModel.rawJson;
    final status = (ride['status'] ?? 'pending').toString().toLowerCase();
    final label = _resolveBookingLabel(ride);
    final locations = ride['locations'] as List?;
    final pickup =
        ride['pickupAddress']?['label'] ??
        ride['pickup']?['address'] ??
        ride['pickup']?['name'] ??
        (locations != null && locations.isNotEmpty
            ? locations[0]['address'] ?? locations[0]['title']
            : null) ??
        'Pickup';
    final drop =
        ride['receivedAddress']?['label'] ??
        ride['dropoff']?['address'] ??
        ride['dropoff']?['name'] ??
        (locations != null && locations.length > 1
            ? locations[1]['address'] ?? locations[1]['title']
            : null) ??
        'Delivery';
    final dateObj = ride['createdAt'] != null
        ? DateTime.tryParse(ride['createdAt'])?.toLocal()
        : null;
    final dateStr = dateObj != null
        ? '${dateObj.day}/${dateObj.month}/${dateObj.year}'
        : (ride['date'] ?? 'N/A');
    final price =
        ride['totalPrice'] ?? ride['fare'] ?? ride['estimatedFare'] ?? 0.0;

    IconData icon = Icons.directions_car;
    Color color = Colors.blue;
    if (label == 'SHUTTLE') {
      icon = Icons.directions_bus;
      color = Colors.purple;
    } else if (label == 'LOGISTICS') {
      icon = Icons.local_shipping;
      color = Colors.orange;
    }

    return {
      'date': dateStr,
      'from': pickup,
      'to': drop,
      'price':
          '₹${(double.tryParse(price.toString()) ?? 0.0).toStringAsFixed(2)}',
      'type': label,
      'icon': icon,
      'color': color,
      'status': status,
      'originalModel': rideModel,
    };
  }

  List<Map<String, dynamic>> _getPastRides(List<BookingModel> bookings) {
    return bookings
        .where((b) {
          final s = (b.rawJson['status'] ?? '').toString().toLowerCase();
          return s == 'delivered' || s == 'cancelled' || s == 'completed';
        })
        .map(_formatRide)
        .toList();
  }

  List<Map<String, dynamic>> _getUpcomingRides(List<BookingModel> bookings) {
    return bookings
        .where((b) {
          final s = (b.rawJson['status'] ?? '').toString().toLowerCase();
          return s != 'delivered' && s != 'cancelled' && s != 'completed';
        })
        .map(_formatRide)
        .toList();
  }

  void _showRideDetails(Map<String, dynamic> ride, bool isUpcoming) {
    final status = ride['status']?.toString() ?? 'pending';
    Color statusColor = Colors.blue;
    if (status == 'completed' || status == 'delivered') {
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
    } else if (status == 'in_transit') {
      statusColor = Colors.orange;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title and Icon Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ride['type'],
                              style: const TextStyle(
                                color: Color(0xFF0F4A2C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ride['date'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (ride['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ride['icon'] as IconData,
                      color: ride['color'] as Color,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Route Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.circle, color: const Color(0xFF0F4A2C), size: 10),
                        Container(
                          width: 1.5,
                          height: 36,
                          color: Colors.grey[300],
                        ),
                        const Icon(Icons.location_on, color: Colors.red, size: 12),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pickup Location",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride['from'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Dropoff Location",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride['to'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total Fare Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4A2C).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Fare (Paid via Cash)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      ride['price'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4A2C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (isUpcoming) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          navigateToRideTracking(
                            sheetContext,
                            ride['originalModel'],
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4A2C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Track Ride",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final bookingId =
                              ride['originalModel']?.bookingId?.isNotEmpty == true
                              ? ride['originalModel']?.bookingId
                              : ride['originalModel']?.rawJson?['_id']
                                        ?.toString() ??
                                    '';

                          if (bookingId != null && bookingId.isNotEmpty) {
                            try {
                              showDialog(
                                context: sheetContext,
                                barrierDismissible: false,
                                builder: (dialogContext) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF0F4A2C)),
                                ),
                              );

                              final repo = ref.read(restApiRepositoryProvider);
                              final response = await repo.cancelBooking(
                                bookingId: bookingId,
                                reason: 'User cancelled via app',
                              );

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext); // Close loading indicator
                                Navigator.pop(sheetContext); // Close bottom sheet

                                if (response.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Ride Cancelled Successfully"),
                                    ),
                                  );
                                  ref.invalidate(bookingsHistoryProvider);
                                  ref.invalidate(recentBookingsProvider);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Failed to cancel: ${response.message}"),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext); // Close loading
                                Navigator.pop(sheetContext); // Close sheet
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error cancelling: $e")),
                                );
                              }
                            }
                          } else {
                            Navigator.pop(sheetContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Cancel Ride",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Close Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsHistoryAsync = ref.watch(bookingsHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Activity",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF0F4A2C),
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: "Past"),
                Tab(text: "Upcoming"),
              ],
            ),
          ),
        ),
      ),
      body: bookingsHistoryAsync.when(
        data: (bookings) {
          final past = _getPastRides(bookings);
          final upcoming = _getUpcomingRides(bookings);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRideList(past, false),
              _buildRideList(upcoming, true),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0F4A2C))),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, bool isUpcoming) {
    final status = ride['status']?.toString() ?? 'pending';
    Color statusColor = Colors.blue;
    if (status == 'completed' || status == 'delivered') {
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
    } else if (status == 'in_transit') {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRideDetails(ride, isUpcoming),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (ride['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ride['icon'] as IconData,
                      color: ride['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['type'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride['date'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Timeline (Route)
              Row(
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, color: const Color(0xFF0F4A2C), size: 10),
                      Container(
                        width: 1.5,
                        height: 24,
                        color: Colors.grey[300],
                      ),
                      const Icon(Icons.location_on, color: Color(0xFFE65F2B), size: 12),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['from'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ride['to'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Price and details arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ride['price'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        "Details",
                        style: TextStyle(
                          color: Color(0xFF0F4A2C),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, color: Color(0xFF0F4A2C), size: 10),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideList(List<Map<String, dynamic>> rides, bool isUpcoming) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No activity found",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        return _buildRideCard(rides[index], isUpcoming);
      },
    );
  }
}
