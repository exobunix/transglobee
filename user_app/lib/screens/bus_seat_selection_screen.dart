import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/rest_api_repository.dart';
import 'searching_ride_screen.dart';

class BusSeatSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> route;
  final String selectedDate;
  final String selectedTiming;
  final double farePerSeat;
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;
  final bool isWholeShuttleBooking;
  final String charterType; // 'particular_days', 'permanent', 'flexible'
  final int charterDays;
  final double wholeShuttleFare;

  const BusSeatSelectionScreen({
    super.key,
    required this.vehicle,
    required this.route,
    required this.selectedDate,
    required this.selectedTiming,
    required this.farePerSeat,
    this.pickup,
    this.dropoff,
    this.isWholeShuttleBooking = false,
    this.charterType = 'particular_days',
    this.charterDays = 1,
    this.wholeShuttleFare = 0.0,
  });

  @override
  ConsumerState<BusSeatSelectionScreen> createState() => _BusSeatSelectionScreenState();
}

class _BusSeatSelectionScreenState extends ConsumerState<BusSeatSelectionScreen> {
  final Set<String> _selectedSeats = {};
  Set<String> _bookedSeats = {};
  bool _isLoadingSeats = true;
  bool _isBooking = false;
  bool _isPastDeparture = false;

  late int _totalCapacity;
  Map<String, dynamic>? _backendSeatLayout;

  double get effectiveFarePerSeat {
    if (widget.farePerSeat > 0) return widget.farePerSeat;
    final adminPrice = (widget.vehicle['pricePerSeat'] as num?)?.toDouble() ??
        (widget.vehicle['pricing']?['pricePerSeat'] as num?)?.toDouble() ??
        (widget.vehicle['pricing']?['fixedPrice'] as num?)?.toDouble() ??
        0.0;
    if (adminPrice > 0) return adminPrice;
    return 50.0;
  }

  @override
  void initState() {
    super.initState();
    _totalCapacity = (widget.vehicle['passengerCapacity'] as num?)?.toInt() ?? 24;
    if (_totalCapacity <= 0) _totalCapacity = 24;
    
    if (widget.isWholeShuttleBooking) {
      for (int i = 1; i <= _totalCapacity; i++) {
        _selectedSeats.add('$i');
      }
    }
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    setState(() => _isLoadingSeats = true);
    try {
      final repo = ref.read(restApiRepositoryProvider);
      final res = await repo.getBookedSeats(
        vehicleId: widget.vehicle['_id']?.toString(),
        routeId: widget.route['_id']?.toString(),
        date: widget.selectedDate,
        time: widget.selectedTiming,
      );
      if (mounted) {
        setState(() {
          _bookedSeats = (res['bookedSeats'] as List?)?.map((e) => e.toString()).toSet() ?? {};
          _totalCapacity = (res['totalCapacity'] as num?)?.toInt() ?? _totalCapacity;
          _isPastDeparture = res['isPast'] == true;
          _backendSeatLayout = res['seatLayout'] as Map<String, dynamic>?;
          _isLoadingSeats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSeats = false);
      }
    }
  }

  void _toggleSeat(String seatNumber) {
    if (widget.isWholeShuttleBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Whole shuttle is booked under Corporate Charter. All seats are reserved for your organization.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isPastDeparture) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select seats. This bus departure has already departed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bookedSeats.contains(seatNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat $seatNumber is already booked. Please choose another seat.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        if (_selectedSeats.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 6 seats can be selected per booking.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedSeats.add(seatNumber);
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_isPastDeparture) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This bus departure has already passed. Please select a future timing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat to proceed.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    final sortedSeats = widget.isWholeShuttleBooking
        ? List.generate(_totalCapacity, (i) => '${i + 1}')
        : (_selectedSeats.toList()..sort());
    final totalFare = widget.isWholeShuttleBooking
        ? (widget.wholeShuttleFare > 0 ? widget.wholeShuttleFare : effectiveFarePerSeat * _totalCapacity)
        : (effectiveFarePerSeat * sortedSeats.length);
    final distance = (widget.route['distance'] as num?)?.toDouble() ?? 10.0;

    final pickup = widget.pickup ?? {
      'name': widget.route['source'] ?? 'Origin Stop',
      'address': widget.route['source'] ?? 'Origin Stop',
      'lat': widget.route['startLat'] ?? 19.0760,
      'lng': widget.route['startLng'] ?? 72.8777,
    };

    final dropoff = widget.dropoff ?? {
      'name': widget.route['destination'] ?? 'Destination Stop',
      'address': widget.route['destination'] ?? 'Destination Stop',
      'lat': widget.route['endLat'] ?? 19.0890,
      'lng': widget.route['endLng'] ?? 72.8910,
    };

    try {
      final repo = ref.read(restApiRepositoryProvider);
      final response = await repo.createBooking({
        'type': 'shuttle',
        'bookingCategory': 'shuttle',
        'vehicleType': 'bus',
        'vehicleId': widget.vehicle['_id'],
        'routeId': widget.route['_id'],
        'fare': totalFare,
        'vehiclePrice': widget.isWholeShuttleBooking ? totalFare : effectiveFarePerSeat,
        'totalPrice': totalFare,
        'distance': distance,
        'distanceKm': distance,
        'departureTime': widget.selectedTiming,
        'selectedDate': widget.selectedDate,
        'selectedSeats': sortedSeats,
        'seatCount': sortedSeats.length,
        'passengerCount': sortedSeats.length,
        'isCharter': widget.isWholeShuttleBooking,
        'charterType': widget.charterType,
        'charterDays': widget.charterDays,
        'notes': widget.isWholeShuttleBooking
            ? 'Corporate Charter: Entire Shuttle Bus Reserved for ${widget.charterType}'
            : 'Individual seat booking',
        'travelDate': widget.selectedDate,
        'paymentMethod': 'cash',
        'pickupLocation': {
          'title': pickup['name'] ?? pickup['title'] ?? 'Origin',
          'address': pickup['address'] ?? pickup['name'],
          'latitude': pickup['lat'] ?? 19.0760,
          'longitude': pickup['lng'] ?? 72.8777,
        },
        'dropLocation': {
          'title': dropoff['name'] ?? dropoff['title'] ?? 'Destination',
          'address': dropoff['address'] ?? dropoff['name'],
          'latitude': dropoff['lat'] ?? 19.0890,
          'longitude': dropoff['lng'] ?? 72.8910,
        },
      });

      if (!mounted) return;

      if (response.success && response.data != null) {
        final booking = response.data!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingRideScreen(
              pickup: pickup,
              dropoff: dropoff,
              distance: '${distance.toStringAsFixed(1)} km',
              rideMode: '${widget.vehicle['vehicleName'] ?? "Bus"} (Seats: ${sortedSeats.join(", ")})',
              price: '₹${totalFare.toStringAsFixed(0)}',
              otp: null,
              rideId: booking.bookingId,
              vehicle: {
                'name': widget.vehicle['vehicleName'] ?? 'Shuttle Bus',
                'type': 'Bus',
                'price': totalFare,
                'seats': sortedSeats,
              },
            ),
          ),
        );
      } else {
        throw Exception(response.message ?? 'Failed to book shuttle seats.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  /// Fallback row layout generator matching EXACT capacity if backend didn't supply one
  List<Map<String, dynamic>> _generateFallbackRows(int capacity) {
    final List<Map<String, dynamic>> rows = [];
    int seatsAssigned = 0;
    int rowNum = 1;

    while (seatsAssigned < capacity) {
      final remaining = capacity - seatsAssigned;
      if (remaining == 5) {
        rows.add({
          'rowNumber': rowNum,
          'isBackRow': true,
          'left': ['${rowNum}A', '${rowNum}B'],
          'center': ['${rowNum}C'],
          'right': ['${rowNum}D', '${rowNum}E'],
        });
        seatsAssigned += 5;
      } else if (remaining < 4) {
        final left = <String>[];
        final right = <String>[];
        if (remaining >= 1) left.add('${rowNum}A');
        if (remaining >= 2) left.add('${rowNum}B');
        if (remaining >= 3) right.add('${rowNum}C');
        rows.add({
          'rowNumber': rowNum,
          'isBackRow': false,
          'left': left,
          'right': right,
        });
        seatsAssigned += remaining;
      } else {
        rows.add({
          'rowNumber': rowNum,
          'isBackRow': false,
          'left': ['${rowNum}A', '${rowNum}B'],
          'right': ['${rowNum}C', '${rowNum}D'],
        });
        seatsAssigned += 4;
      }
      rowNum++;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;
    final cardColor = context.theme.cardColor;
    final textPrimary = context.colors.textPrimary ?? AppTheme.lightTextPrimary;
    final textSecondary = context.colors.textSecondary ?? AppTheme.lightTextSecondary;
    final screenWidth = MediaQuery.of(context).size.width;

    final busName = widget.vehicle['vehicleName'] ?? 'Executive Shuttle';
    final routeName = widget.route['name'] ?? '${widget.route['source'] ?? "Source"} ➔ ${widget.route['destination'] ?? "Destination"}';

    // Extract rows strictly from backend seatLayout or exact capacity generator
    final List<dynamic> layoutRows = _backendSeatLayout?['rows'] as List<dynamic>? ??
        _generateFallbackRows(_totalCapacity);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Seats',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$busName • ${widget.selectedTiming}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            tooltip: 'Refresh seats',
            onPressed: _fetchBookedSeats,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner if trip is in the past
            if (_isPastDeparture)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This departure (${widget.selectedTiming}) on ${widget.selectedDate} has already passed. Bookings are closed.',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Route & Timing Info Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isWholeShuttleBooking ? primaryColor.withValues(alpha: 0.08) : cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isWholeShuttleBooking ? primaryColor.withValues(alpha: 0.3) : context.theme.dividerColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.directions_bus, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routeName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isWholeShuttleBooking
                                  ? '🏢 Complete Shuttle Charter • ⏰ ${widget.selectedTiming} • ${widget.charterType == 'permanent' ? 'Permanent Monthly Contract' : widget.charterType == 'flexible' ? 'Flexible Shift' : '${widget.charterDays} Particular Days'}'
                                  : '📅 ${widget.selectedDate} • ⏰ ${widget.selectedTiming} • ₹${effectiveFarePerSeat.toStringAsFixed(0)}/seat',
                              style: TextStyle(
                                color: widget.isWholeShuttleBooking ? primaryColor : textSecondary,
                                fontSize: 11,
                                fontWeight: widget.isWholeShuttleBooking ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.isWholeShuttleBooking) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Seat Map Preview (Read-Only) — Entire Shuttle Reserved for your Organization',
                              style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Seat Status Legend Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: widget.isWholeShuttleBooking
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Reserved for Corporate Charter', primaryColor),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Available', Colors.grey.shade300, isOutline: true),
                        _buildLegendItem('Selected', primaryColor),
                        _buildLegendItem('Booked', Colors.grey.shade500),
                      ],
                    ),
            ),

            const Divider(height: 16),

            // Interactive Bus Seat Layout (Exactly matching Backend Capacity)
            Expanded(
              child: _isLoadingSeats
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading backend seat layout...'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth > 500 ? 420 : screenWidth * 0.92,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: context.theme.dividerColor.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Driver Cabin & Entry Door
                                _buildDriverCabin(primaryColor),

                                const SizedBox(height: 16),

                                // Aisle Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'WINDOW (A)',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'AISLE',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'WINDOW (D)',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Seating Grid strictly rendered row by row from backend
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: layoutRows.length,
                                  itemBuilder: (context, rowIndex) {
                                    final rowData = Map<String, dynamic>.from(layoutRows[rowIndex] as Map);
                                    final bool isBackRow = rowData['isBackRow'] == true;
                                    final int rowNum = (rowData['rowNumber'] as num?)?.toInt() ?? (rowIndex + 1);

                                    final List leftSeats = (rowData['left'] as List?) ?? [];
                                    final List rightSeats = (rowData['right'] as List?) ?? [];
                                    final List centerSeats = (rowData['center'] as List?) ?? [];

                                    if (isBackRow) {
                                      // Back row continuous seats
                                      final List allBackSeats = [...leftSeats, ...centerSeats, ...rightSeats];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: allBackSeats.map((s) => _buildSeat(s.toString())).toList(),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Left Pair
                                          Row(
                                            children: leftSeats.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final seatStr = entry.value.toString();
                                              return Padding(
                                                padding: EdgeInsets.only(right: idx < leftSeats.length - 1 ? 8.0 : 0.0),
                                                child: _buildSeat(seatStr, isWindow: idx == 0),
                                              );
                                            }).toList(),
                                          ),

                                          // Center Walking Aisle
                                          Container(
                                            width: 32,
                                            height: 44,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$rowNum',
                                              style: TextStyle(
                                                color: textSecondary.withValues(alpha: 0.4),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),

                                          // Right Pair
                                          Row(
                                            children: rightSeats.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final seatStr = entry.value.toString();
                                              final isWindowSeat = idx == rightSeats.length - 1;
                                              return Padding(
                                                padding: EdgeInsets.only(right: idx < rightSeats.length - 1 ? 8.0 : 0.0),
                                                child: _buildSeat(seatStr, isWindow: isWindowSeat),
                                              );
                                            }).toList(),
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
                    ),
            ),

            // Bottom Sticky Checkout Bar
            _buildBottomCheckoutBar(primaryColor, cardColor, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCabin(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Passenger Entry Door
          Row(
            children: [
              Icon(Icons.meeting_room_outlined, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 6),
              Text(
                'ENTRY / EXIT',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Driver's Cabin
          Row(
            children: [
              Text(
                'DRIVER',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.airline_seat_recline_extra,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(String seatNumber, {bool isWindow = false}) {
    final isBooked = _bookedSeats.contains(seatNumber);
    final isSelected = _selectedSeats.contains(seatNumber);
    final primaryColor = context.theme.primaryColor;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isBooked || _isPastDeparture) {
      backgroundColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      textColor = Colors.grey.shade600;
    } else if (isSelected) {
      backgroundColor = primaryColor;
      borderColor = primaryColor;
      textColor = Colors.white;
    } else {
      backgroundColor = context.theme.cardColor;
      borderColor = primaryColor.withValues(alpha: 0.35);
      textColor = context.colors.textPrimary ?? AppTheme.lightTextPrimary;
    }

    return InkWell(
      onTap: () => _toggleSeat(seatNumber),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Headrest indicator
            Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : ((isBooked || _isPastDeparture) ? Colors.grey.shade500 : primaryColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              seatNumber,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isBooked || _isPastDeparture)
              Icon(Icons.close, size: 10, color: Colors.grey.shade600)
            else if (isSelected)
              const Icon(Icons.check, size: 10, color: Colors.white)
            else if (isWindow)
              Text(
                'W',
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isOutline = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isOutline ? Colors.grey.shade500 : color,
              width: 1.5,
            ),
          ),
          child: isOutline
              ? null
              : (label == 'Selected'
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutBar(
    Color primaryColor,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final seatCount = _selectedSeats.length;
    final totalFare = widget.isWholeShuttleBooking
        ? (widget.wholeShuttleFare > 0 ? widget.wholeShuttleFare : effectiveFarePerSeat * _totalCapacity)
        : (effectiveFarePerSeat * seatCount);
    final sortedSeats = _selectedSeats.toList()..sort();

    final canBook = !_isPastDeparture && !_isBooking && (widget.isWholeShuttleBooking || seatCount > 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selected details & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPastDeparture)
                  Text(
                    'Trip Departed',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (widget.isWholeShuttleBooking) ...[
                  Text(
                    'Complete Charter (${_totalCapacity} Seats)',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ] else if (seatCount > 0) ...[
                  Text(
                    'Seats: ${sortedSeats.join(", ")}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ] else ...[
                  Text(
                    'No seat selected',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${totalFare.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.isWholeShuttleBooking
                          ? ' (${widget.charterType == 'permanent' ? 'Monthly Contract' : widget.charterType == 'flexible' ? 'Shift Booking' : '${widget.charterDays} Days'})'
                          : (seatCount > 0 ? ' ($seatCount ${seatCount == 1 ? "seat" : "seats"})' : ''),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Proceed Button
          ElevatedButton(
            onPressed: canBook ? _confirmBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canBook ? 3 : 0,
            ),
            child: _isBooking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        _isPastDeparture 
                            ? 'Departed' 
                            : (widget.isWholeShuttleBooking ? 'Book Charter' : 'Book Now'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(_isPastDeparture ? Icons.block : Icons.arrow_forward, size: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
