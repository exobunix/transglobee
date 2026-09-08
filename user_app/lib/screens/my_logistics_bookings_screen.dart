import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/rest_api_repository.dart';
import '../models/booking_model.dart';

class MyLogisticsBookingsScreen extends ConsumerStatefulWidget {
  const MyLogisticsBookingsScreen({super.key});

  @override
  ConsumerState<MyLogisticsBookingsScreen> createState() => _MyLogisticsBookingsScreenState();
}

class _MyLogisticsBookingsScreenState extends ConsumerState<MyLogisticsBookingsScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String? _error;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final repo = ref.read(restApiRepositoryProvider);
      setState(() => _isLoading = true);

      final response = await repo.getBookingHistory();
      if (response.success && mounted) {
        setState(() {
          _bookings = response.data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? "Failed to fetch bookings";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredBookings {
    if (_selectedFilter == 'All') return _bookings;
    return _bookings.where((b) {
      final status = (b.status ?? '').toString().toLowerCase();
      if (_selectedFilter == 'Pending') return status == 'pending';
      if (_selectedFilter == 'Confirmed') {
        return status == 'confirmed' ||
            status == 'processing' ||
            status == 'in_transit' ||
            status == 'assigned';
      }
      if (_selectedFilter == 'Completed') {
        return status == 'completed' || status == 'delivered';
      }
      if (_selectedFilter == 'Cancelled') return status == 'cancelled';
      return true;
    }).toList();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  String _formatCurrency(double val) {
    // Basic comma formatting for Indian Rupee
    final str = val.toStringAsFixed(0);
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final otherNumbers = str.substring(0, str.length - 3);
    var formatted = "";
    var count = 0;
    for (var i = otherNumbers.length - 1; i >= 0; i--) {
      formatted = otherNumbers[i] + formatted;
      count++;
      if (count == 2 && i != 0) {
        formatted = ",$formatted";
        count = 0;
      }
    }
    return "$formatted,$lastThree";
  }

  @override
  Widget build(BuildContext context) {
    final bookingsList = _filteredBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF14201B), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Logistics Bookings',
              style: GoogleFonts.lexend(
                color: const Color(0xFF14201B),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            actions: [
              if (!_isLoading && _bookings.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      "${_bookings.length} Bookings",
                      style: GoogleFonts.notoSans(
                        color: const Color(0xFF68736E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF167A45)))
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.notoSans(color: const Color(0xFFD95353)),
                        ),
                      )
                    : bookingsList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFF167A45),
                            onRefresh: _fetchBookings,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                              itemCount: bookingsList.length,
                              itemBuilder: (ctx, index) {
                                final booking = bookingsList[index];
                                return _buildBookingCard(booking);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF167A45)),
          ),
          const SizedBox(height: 20),
          Text(
            'No bookings found',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF14201B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recently booked logistics will appear here',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: const Color(0xFF68736E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final status = booking.status;
    final vehicle = booking.vehicleType ?? 'Logistics';
    final date = booking.scheduledTime ?? DateTime.now();

    // Parse actual locations from rawJson if present
    final locationsList = booking.rawJson['locations'] as List?;
    var pickupAddress = 'Location';
    var dropoffAddress = 'Location';
    if (locationsList != null && locationsList.isNotEmpty) {
      final pLoc = locationsList.firstWhere(
        (e) => e['type'] == 'pickup' || e['type'] == 'origin',
        orElse: () => locationsList[0],
      );
      final dLoc = locationsList.firstWhere(
        (e) => e['type'] == 'dropoff' || e['type'] == 'destination',
        orElse: () => locationsList.length > 1 ? locationsList[1] : null,
      );
      if (pLoc != null) {
        pickupAddress = pLoc['name'] ?? pLoc['address'] ?? 'Location';
      }
      if (dLoc != null) {
        dropoffAddress = dLoc['name'] ?? dLoc['address'] ?? 'Location';
      }
    }

    final double fareVal = booking.fare ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECEA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(status),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.notoSans(
                        color: const Color(0xFF68736E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Vehicle info + Fare
                Row(
                  children: [
                    // Modern vehicle icon container
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          _getVehicleIcon(vehicle),
                          color: const Color(0xFF167A45),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Names
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle,
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF14201B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.type.toUpperCase(),
                            style: GoogleFonts.notoSans(
                              color: const Color(0xFF68736E),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fare Display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${_formatCurrency(fareVal)}",
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: const Color(0xFF167A45),
                          ),
                        ),
                        Text(
                          "Estimated Fare",
                          style: GoogleFonts.notoSans(
                            color: const Color(0xFF68736E),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE3E8E5), height: 1),
                ),

                // 3. Route Section
                _buildRouteVisualization(pickupAddress, dropoffAddress),
              ],
            ),
          ),

          // 4. Card Footer
          GestureDetector(
            onTap: () => _showBookingDetails(booking),
            child: Container(
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6EF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Booking Details',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF167A45),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF167A45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        bgColor = const Color(0xFFEAF6EF);
        textColor = const Color(0xFF168A4A);
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFD95353);
        break;
      case 'in_transit':
      case 'processing':
      case 'confirmed':
      case 'assigned':
        bgColor = const Color(0xFFEAF6EF);
        textColor = const Color(0xFF168A4A);
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFFFF6DD);
        textColor = const Color(0xFFD89B20);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.lexend(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteVisualization(String pickup, String drop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, color: Color(0xFF167A45), size: 10),
            Container(
              width: 1.5,
              height: 36,
              color: const Color(0xFFE3E8E5),
            ),
            const Icon(Icons.location_on, color: Color(0xFFD95353), size: 12),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pickup Location",
                style: GoogleFonts.notoSans(
                  color: const Color(0xFF68736E),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pickup,
                style: GoogleFonts.notoSans(
                  color: const Color(0xFF14201B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Text(
                "Drop-off Location",
                style: GoogleFonts.notoSans(
                  color: const Color(0xFF68736E),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                drop,
                style: GoogleFonts.notoSans(
                  color: const Color(0xFF14201B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String vehicle) {
    final v = vehicle.toLowerCase();
    if (v.contains('flight')) return Icons.flight_takeoff_rounded;
    if (v.contains('train')) return Icons.train_rounded;
    if (v.contains('sea')) return Icons.directions_boat_rounded;
    return Icons.local_shipping_rounded;
  }

  void _showBookingDetails(BookingModel booking) {
    final status = booking.status;
    final vehicle = booking.vehicleType ?? 'Logistics';
    final date = (booking.scheduledTime ?? DateTime.now()).toLocal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
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
                            Text(vehicle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Booked on ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2,'0')}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status.toUpperCase(), 
                            style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Addresses
                    _sectionHeader('Addresses'),
                    _detailLocationCard(
                      title: 'Pickup',
                      label: 'Pickup Location',
                      fullAddress: 'Lat: ${booking.pickupLocation?.lat}, Lng: ${booking.pickupLocation?.lng}',
                      icon: Icons.circle,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _detailLocationCard(
                      title: 'Delivery',
                      label: 'Drop-off Location',
                      fullAddress: 'Lat: ${booking.dropLocation?.lat}, Lng: ${booking.dropLocation?.lng}',
                      icon: Icons.location_on,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),

                    // Amount
                    _sectionHeader('Price Breakdown'),
                    _priceRow('Estimated Fare', booking.estimatedFare ?? 0),
                    if (booking.estimatedCost != null)
                      _priceRow('Estimated Cost', booking.estimatedCost),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                    _priceRow('Total Amount', booking.fare ?? 0, isTotal: true),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
    );
  }

  Widget _detailLocationCard({
    required String title,
    required String label,
    required String fullAddress,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(fullAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, dynamic amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 18 : 14, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? context.colors.textPrimary : context.colors.textSecondary
          )),
          Text('₹${(double.tryParse(amount.toString()) ?? 0.0).toStringAsFixed(2)}', style: TextStyle(
            fontSize: isTotal ? 22 : 14, 
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : (isTotal ? context.theme.primaryColor : context.colors.textPrimary)
          )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled': return Colors.red;
      case 'in_transit': return Colors.orange;
      default: return Colors.blue;
    }
  }
}
