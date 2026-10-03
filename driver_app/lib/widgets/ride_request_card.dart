import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/vehicle_type_provider.dart';
import '../services/socket_service.dart';
import '../features/driver/controllers/driver_providers.dart';

class RideRequestCard extends ConsumerStatefulWidget {
  final Function(double)? onAccept;
  final VoidCallback? onDecline;
  final String? adminId;
  final String? adminName;
  final Map<String, dynamic>? rideData;

  const RideRequestCard({
    super.key,
    this.onAccept,
    this.onDecline,
    this.adminId,
    this.adminName,
    this.rideData,
  });

  @override
  ConsumerState<RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends ConsumerState<RideRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _additionalFare = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).negotiateResultStream.listen((data) {
        if (!mounted) return;
        final rideId = (widget.rideData?['id'] ?? widget.rideData?['_id'])?.toString();
        if (data['rideId']?.toString() == rideId) {
          final accepted = data['accepted'] == true;
          final extra = data['additionalAmount'] ?? _additionalFare;
          if (accepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Passenger accepted +₹$extra fare!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _additionalFare = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passenger declined extra fare negotiation.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VehicleType _vehicleTypeFromRide() {
    final raw = (widget.rideData?['type'] ??
            widget.rideData?['bookingCategory'] ??
            'CAB')
        .toString()
        .toUpperCase();
    if (raw == 'CAB' || raw == 'RETAIL' || raw == 'RIDE') {
      return VehicleType.cab;
    }
    if (raw == 'SHUTTLE' || raw.contains('BUS')) {
      return VehicleType.bus;
    }
    return VehicleType.truck;
  }

  @override
  Widget build(BuildContext context) {
    final rideId = widget.rideData?['id'] ?? widget.rideData?['_id'];
    if (widget.rideData == null || rideId == null) {
      return const SizedBox.shrink();
    }

    final vehicleType = _vehicleTypeFromRide();
    final customerName = widget.rideData?['userName']?.toString() ??
        widget.rideData?['name']?.toString() ??
        widget.rideData?['customerName']?.toString() ??
        (widget.rideData?['user'] is Map ? widget.rideData!['user']['name']?.toString() : null) ??
        'Guest User';
    final customerPhone = widget.rideData?['userPhone']?.toString() ??
        widget.rideData?['phone']?.toString() ??
        widget.rideData?['mobileNumber']?.toString() ??
        (widget.rideData?['user'] is Map ? widget.rideData!['user']['phone']?.toString() : null) ??
        '';
    final pickText = widget.rideData?['pick']?.toString() ??
        widget.rideData?['pickupLocation']?.toString() ??
        widget.rideData?['pickupAddress']?.toString() ??
        (widget.rideData?['pickup'] is Map
            ? (widget.rideData!['pickup']['address'] ?? widget.rideData!['pickup']['name'])?.toString()
            : null) ??
        'Pick up location';
    final dropText = widget.rideData?['drop']?.toString() ??
        widget.rideData?['dropLocation']?.toString() ??
        widget.rideData?['dropAddress']?.toString() ??
        (widget.rideData?['dropoff'] is Map
            ? (widget.rideData!['dropoff']['address'] ?? widget.rideData!['dropoff']['name'])?.toString()
            : null) ??
        'Drop location';

    final typeUpper = (widget.rideData?['type'] ?? widget.rideData?['bookingCategory'] ?? '').toString().toUpperCase();
    final isCab = typeUpper == 'CAB' || typeUpper == 'RETAIL' || typeUpper == 'RIDE';
    final isLogistics = !isCab && (widget.rideData?['isLogistics'] == true ||
        widget.rideData?['bookingCategory']?.toString().toUpperCase() == 'LOGISTICS' ||
        widget.rideData?['type']?.toString().toUpperCase() == 'LOGISTICS');
    final showFare = widget.rideData?['showFare'] ?? (!isLogistics);

    String rawMode = widget.rideData?['rideMode']?.toString() ?? 'Standard';
    if (isCab && (rawMode.toUpperCase().contains('LOGISTIC') || rawMode.toUpperCase().contains('ECONOMY'))) {
      rawMode = 'Cab Service';
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: vehicleType.accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: vehicleType.accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: vehicleType.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vehicleType.icon,
                      color: vehicleType.accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: vehicleType.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: vehicleType.accentColor.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                vehicleType.label.toUpperCase(),
                                style: TextStyle(
                                  color: vehicleType.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                vehicleType.requestLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: vehicleType.accentColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$rawMode • ${widget.rideData?['distance'] ?? '0 km'} away',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.darkTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showFare)
                    InkWell(
                      onTap: () => _showFareBreakdown(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.earningsAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.earningsAmber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${((double.tryParse((widget.rideData?['fare'] ?? '0').toString()) ?? 0.0) + _additionalFare).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.earningsAmber,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline, size: 14, color: AppTheme.earningsAmber),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueGrey),
                      ),
                      child: Text(
                        typeUpper == 'SHUTTLE' ? 'Shuttle' : 'Logistics',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Route Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickText,
                            style: const TextStyle(
                              color: AppTheme.darkTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 18,
                            color: AppTheme.darkDivider,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.offlineRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.offlineRed.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dropText,
                            style: const TextStyle(
                              color: AppTheme.darkTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Distance + Time chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChip(Icons.route, widget.rideData?['distance'] ?? '0 km', vehicleType.accentColor),
                    const SizedBox(width: 8),
                    _buildChip(Icons.access_time, 'Live', AppTheme.darkTextSecondary),
                    const SizedBox(width: 8),
                    _buildChip(Icons.person, customerName, AppTheme.earningsAmber),
                    if (customerPhone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildChip(Icons.phone, customerPhone, Colors.blue),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Negotiation Info
              if (showFare)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Negotiate Fare:', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        _negotiationButton(10),
                        const SizedBox(width: 8),
                        _negotiationButton(20),
                        const SizedBox(width: 8),
                        _negotiationButton(50),
                        const SizedBox(width: 8),
                        _negotiationButton(100),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.offlineRed,
                        side: BorderSide(
                          color: AppTheme.offlineRed.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.onAccept != null) {
                          final fareValue = widget.rideData?['fare'];
                          double baseFare = 0.0;
                          if (fareValue is num) {
                            baseFare = fareValue.toDouble();
                          } else if (fareValue is String) {
                            baseFare = double.tryParse(fareValue) ?? 0.0;
                          }
                          widget.onAccept!(baseFare + _additionalFare);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vehicleType.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        onEnd: () {}, // Not needed for simple loop, but we can do better
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, size: 14),
                            SizedBox(width: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Accept Ride NOW',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _negotiationButton(int amount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _additionalFare += amount;
        });
        final rideId = (widget.rideData?['id'] ?? widget.rideData?['_id'])?.toString();
        if (rideId != null && rideId.isNotEmpty) {
          final driverProfile = ref.read(driverProfileProvider).value;
          ref.read(socketServiceProvider).sendNegotiateFare(
            rideId: rideId,
            additionalAmount: amount.toDouble(),
            driverId: driverProfile?.id,
            driverName: driverProfile?.fullName ?? 'Driver',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Negotiation sent: +₹$amount. Waiting for passenger response...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.neonGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
        ),
        child: Text(
          '+₹$amount',
          style: const TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showFareBreakdown(BuildContext context) {
    final baseFare = double.tryParse((widget.rideData?['fare'] ?? '0').toString()) ?? 0.0;
    final totalFare = baseFare + _additionalFare;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fare Summary Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppTheme.darkDivider),
            const SizedBox(height: 12),
            _breakdownRow('Base & Distance Fare', '₹${baseFare.toStringAsFixed(0)}'),
            if (_additionalFare > 0) ...[
              const SizedBox(height: 8),
              _breakdownRow('Negotiated Extra Fare', '+₹$_additionalFare', color: AppTheme.neonGreen),
            ],
            const SizedBox(height: 8),
            _breakdownRow('Taxes & Convenience Fees', 'Included'),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.darkDivider),
            const SizedBox(height: 8),
            _breakdownRow('Total Booking Fare', '₹${totalFare.toStringAsFixed(0)}', isTotal: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String title, String val, {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal ? Colors.white : AppTheme.darkTextSecondary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            color: color ?? (isTotal ? AppTheme.earningsAmber : Colors.white),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getFareText(VehicleType vehicleType) {
    int base = vehicleType == VehicleType.cab ? 180 : (vehicleType == VehicleType.truck ? 2400 : 650);
    if (base > 1000) {
      return '₹${(base + _additionalFare).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '₹${base + _additionalFare}';
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
