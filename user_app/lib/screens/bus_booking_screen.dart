import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'bus_seat_selection_screen.dart';

class BusBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;

  const BusBookingScreen({super.key, this.pickup, this.dropoff});

  @override
  ConsumerState<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends ConsumerState<BusBookingScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Selected Travel Date
  late DateTime _selectedDate;
  final List<DateTime> _dateOptions = [];

  // Track selected timing per vehicle ID
  final Map<String, String> _selectedTimingMap = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    for (int i = 0; i < 7; i++) {
      _dateOptions.add(now.add(Duration(days: i)));
    }
    Future.microtask(() => _fetchAssignedBusRoutes());
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  bool _isTimingPast(DateTime date, String timing) {
    final now = DateTime.now();
    // If date is in the future
    if (date.year > now.year ||
        (date.year == now.year && date.month > now.month) ||
        (date.year == now.year && date.month == now.month && date.day > now.day)) {
      return false;
    }
    // If date is in the past
    if (date.year < now.year ||
        (date.year == now.year && date.month < now.month) ||
        (date.year == now.year && date.month == now.month && date.day < now.day)) {
      return true;
    }

    // Same day: compare hour and minute with current time
    try {
      final parts = timing.trim().split(' ');
      if (parts.length != 2) return false;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      final departureDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      return departureDateTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Re-assign default timing to the first upcoming timing for each vehicle
      for (var item in _vehicles) {
        final vehicleId = item['_id']?.toString() ?? '';
        final timings = (item['departureTimings'] as List?)?.map((e) => e.toString()).toList() ?? [];
        String? nextUpcoming;
        for (final t in timings) {
          if (!_isTimingPast(date, t)) {
            nextUpcoming = t;
            break;
          }
        }
        if (nextUpcoming != null) {
          _selectedTimingMap[vehicleId] = nextUpcoming;
        } else if (timings.isNotEmpty) {
          _selectedTimingMap[vehicleId] = timings.first;
        }
      }
    });
  }

  Future<void> _fetchAssignedBusRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      // Fetch vehicles of type 'bus' (Backend automatically filters by user's assignedRoutes if present)
      final response = await apiService.get('/transglobe/vehicles?type=bus');

      if (response != null && response['success'] == true && response['data'] != null) {
        final List data = response['data'];
        final List<Map<String, dynamic>> loaded = [];

        for (var item in data) {
          if (item is Map<String, dynamic>) {
            loaded.add(item);
            final vehicleId = item['_id']?.toString() ?? '';
            final timings = (item['departureTimings'] as List?)?.map((e) => e.toString()).toList() ?? [];

            String? nextUpcoming;
            for (final t in timings) {
              if (!_isTimingPast(_selectedDate, t)) {
                nextUpcoming = t;
                break;
              }
            }
            _selectedTimingMap[vehicleId] = nextUpcoming ?? (timings.isNotEmpty ? timings.first : '08:30 AM');
          }
        }

        if (mounted) {
          setState(() {
            _vehicles = loaded;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response?['message'] ?? 'Failed to load assigned bus routes.';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching assigned bus routes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not connect to server. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateSeatFare(Map<String, dynamic> vehicle, Map<String, dynamic> route) {
    // 1. If admin explicitly configured pricePerSeat or fixed ticket price per seat > 0
    final adminPricePerSeat = (vehicle['pricePerSeat'] as num?)?.toDouble() ??
        (vehicle['pricing']?['pricePerSeat'] as num?)?.toDouble() ??
        (vehicle['pricing']?['fixedPrice'] as num?)?.toDouble() ??
        0.0;
    if (adminPricePerSeat > 0) {
      return adminPricePerSeat;
    }

    // 2. Based on pricePerKm and route distance
    final rawPricePerKm = (vehicle['pricing']?['pricePerKm'] as num?)?.toDouble() ??
        (vehicle['pricePerKm'] as num?)?.toDouble() ??
        0.0;
    final distance = (route['distance'] as num?)?.toDouble() ?? 10.0;
    final capacity = (vehicle['passengerCapacity'] as num?)?.toDouble() ?? 20.0;

    if (rawPricePerKm > 0) {
      // Whole-vehicle rate (e.g. >= ₹15/km for a bus): split by seat capacity
      if (rawPricePerKm >= 15.0) {
        final perSeat = (rawPricePerKm * distance) / (capacity > 0 ? capacity : 20.0);
        return perSeat.clamp(40.0, 500.0).roundToDouble();
      } else {
        // Direct per-seat per-km rate (e.g. ₹3 - ₹5 / km)
        final perSeat = rawPricePerKm * distance;
        return perSeat.clamp(30.0, 500.0).roundToDouble();
      }
    }

    // 3. Fallback based on route distance (e.g. ₹5/km, minimum ₹50)
    final fallbackFare = (distance * 5.0).clamp(50.0, 200.0).roundToDouble();
    return fallbackFare;
  }

  void _navigateToSeatSelection(Map<String, dynamic> vehicle, Map<String, dynamic> route) {
    final vehicleId = vehicle['_id']?.toString() ?? '';
    final timings = (vehicle['departureTimings'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final selectedTiming = _selectedTimingMap[vehicleId] ?? (timings.isNotEmpty ? timings.first : '08:30 AM');
    final formattedDate = _formatDateForApi(_selectedDate);

    if (_isTimingPast(_selectedDate, selectedTiming)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedTiming has already departed for today. Please select an upcoming departure.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final fare = _calculateSeatFare(vehicle, route);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusSeatSelectionScreen(
          vehicle: vehicle,
          route: route,
          selectedDate: formattedDate,
          selectedTiming: selectedTiming,
          farePerSeat: fare,
          pickup: widget.pickup,
          dropoff: widget.dropoff,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.colors.textPrimary ?? AppTheme.lightTextPrimary;
    final textSecondary = context.colors.textSecondary ?? AppTheme.lightTextSecondary;
    final primaryColor = context.theme.primaryColor;
    final cardColor = context.theme.cardColor;

    final userAsync = ref.watch(fullUserProfileProvider);
    final user = userAsync.value;
    final hasAssignedRoutes = user != null && user.assignedRoutes.isNotEmpty;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shuttle & Bus Booking',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            tooltip: 'Refresh Routes',
            onPressed: _fetchAssignedBusRoutes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedBusRoutes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Corporate Assigned Routes Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      primaryColor.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAssignedRoutes ? 'Corporate Assigned Routes' : 'Assigned Shuttle Routes',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasAssignedRoutes
                                ? 'Showing buses authorized for your company route profile'
                                : 'Select your route, travel date and book seats like RedBus',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Date Selection Strip (RedBus / MakeMyTrip style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Date',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _dateOptions.length,
                        itemBuilder: (context, index) {
                          final date = _dateOptions[index];
                          final isSelected = date.year == _selectedDate.year &&
                              date.month == _selectedDate.month &&
                              date.day == _selectedDate.day;

                          return GestureDetector(
                            onTap: () => _onDateSelected(date),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : context.theme.dividerColor.withValues(alpha: 0.15),
                                  width: isSelected ? 2 : 1,
                                ),
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
                                  Text(
                                    _formatDayName(date),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateShort(date),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Available Buses Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Buses (${_vehicles.length})',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDateForApi(_selectedDate),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bus List / Loading / Error
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAssignedBusRoutes,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_vehicles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.directions_bus_filled_outlined, size: 54, color: textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No Buses Available on Assigned Routes',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasAssignedRoutes
                              ? 'There are currently no active buses scheduled for your assigned routes. Please check back later or contact your company coordinator.'
                              : 'No routes have been assigned to your corporate user account yet. Please ask your administrator to assign routes to your profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vehicles.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    final routes = vehicle['routes'] as List?;
                    final primaryRoute = (routes != null && routes.isNotEmpty && routes[0] is Map)
                        ? routes[0] as Map<String, dynamic>
                        : {
                            'name': 'Direct Corporate Express',
                            'source': 'Sector 18 Terminal',
                            'destination': 'Cyber City Tech Park',
                            'distance': 12.0,
                            'estimatedDuration': 35,
                          };

                    return _buildBusCard(vehicle, primaryRoute);
                  },
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> vehicle, Map<String, dynamic> route) {
    final primaryColor = context.theme.primaryColor;
    final cardColor = context.theme.cardColor;
    final textPrimary = context.colors.textPrimary ?? AppTheme.lightTextPrimary;
    final textSecondary = context.colors.textSecondary ?? AppTheme.lightTextSecondary;

    final vehicleId = vehicle['_id']?.toString() ?? '';
    final busName = vehicle['vehicleName'] ?? 'Corporate Shuttle';
    final numberPlate = vehicle['numberPlate'] ?? 'DL-01-SHUTTLE';
    final capacity = vehicle['passengerCapacity'] ?? 24;

    final fare = _calculateSeatFare(vehicle, route);

    final source = route['source'] ?? 'Origin';
    final destination = route['destination'] ?? 'Destination';
    final distance = (route['distance'] as num?)?.toDouble() ?? 10.0;
    final duration = route['estimatedDuration'] ?? 30;

    final timings = (vehicle['departureTimings'] as List?)?.map((e) => e.toString()).toList() ??
        ['07:30 AM', '09:00 AM', '11:30 AM', '02:00 PM', '05:00 PM', '07:30 PM'];

    final selectedTiming = _selectedTimingMap[vehicleId] ?? timings.first;

    // Check if the currently selected timing has departed
    final isSelectedPast = _isTimingPast(_selectedDate, selectedTiming);
    // Check if ALL timings have departed for today
    final allTimingsPast = timings.every((t) => _isTimingPast(_selectedDate, t));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Bus title & Plate
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_bus, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: context.theme.dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              numberPlate,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.event_seat, size: 12, color: primaryColor),
                          const SizedBox(width: 3),
                          Text(
                            '$capacity Seats',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${fare.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per seat',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Route Details Path
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              source,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3.5),
                        child: Container(
                          width: 1,
                          height: 14,
                          color: textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              destination,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '~$duration min',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Timings Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Timing / Departure:',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (allTimingsPast)
                  Text(
                    'All departed today',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: timings.map((timing) {
                final isPast = _isTimingPast(_selectedDate, timing);
                final isSelectedTiming = timing == selectedTiming && !isPast;

                return GestureDetector(
                  onTap: () {
                    if (isPast) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$timing has already departed for today. Please select an upcoming departure or tomorrow.'),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _selectedTimingMap[vehicleId] = timing;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.shade200
                          : (isSelectedTiming ? primaryColor : context.theme.scaffoldBackgroundColor),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPast
                            ? Colors.grey.shade300
                            : (isSelectedTiming
                                ? primaryColor
                                : context.theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPast ? Icons.history : Icons.schedule,
                          size: 12,
                          color: isPast
                              ? Colors.grey.shade500
                              : (isSelectedTiming ? Colors.white : textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timing,
                          style: TextStyle(
                            color: isPast
                                ? Colors.grey.shade500
                                : (isSelectedTiming ? Colors.white : textPrimary),
                            fontSize: 11,
                            fontWeight: isSelectedTiming ? FontWeight.bold : FontWeight.w500,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isPast) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Departed)',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Action Button: Select Seats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: (allTimingsPast || isSelectedPast)
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('This departure has already passed. Please select tomorrow to book.'),
                            backgroundColor: Colors.amber.shade900,
                          ),
                        );
                      }
                    : () => _navigateToSeatSelection(vehicle, route),
                icon: Icon(
                  (allTimingsPast || isSelectedPast) ? Icons.block : Icons.event_seat,
                  size: 18,
                ),
                label: Text(
                  allTimingsPast
                      ? 'Departed for Today (Select Next Day)'
                      : (isSelectedPast
                          ? 'Selected Time Departed'
                          : 'Select Seats ($selectedTiming)'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (allTimingsPast || isSelectedPast)
                      ? Colors.grey.shade400
                      : primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: (allTimingsPast || isSelectedPast) ? 0 : 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
