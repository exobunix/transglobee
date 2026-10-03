import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';
import '../core/theme.dart';
import 'rating_screen.dart';
import 'chat_screen.dart';
import '../providers/chat_provider.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../services/api_service.dart';
import '../services/rest_api_repository.dart';
import '../models/ride_model.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final Map<String, dynamic> vehicle;
  final String rideId;
  final String? otp;
  final String? distance;

  final Map<String, dynamic>? driverData;

  const RideTrackingScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.vehicle,
    required this.rideId,
    this.otp,
    this.driverData,
    this.distance,
  });

  @override
  ConsumerState<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  String _rideStatus = 'On the way';
  String _rawStatus = 'accepted';
  String _driverETA = '2 mins away';
  List<LatLng> _routePoints = [];
  StreamSubscription? _statusSubscription;
  StreamSubscription? _locationSubscription;
  LatLng? _driverPos;
  double _driverHeading = 0.0;
  double _currentFare = 0.0;
  String _paymentStatus = 'unpaid';
  StreamSubscription? _fareSubscription;
  StreamSubscription? _roadmapSubscription;
  StreamSubscription? _acceptedSubscription;
  StreamSubscription? _negotiateSubscription;
  StreamSubscription? _cancelByDriverSubscription;
  Timer? _driverPollTimer;
  List<LogisticsSegment> _segments = [];
  String? _startOtp;
  String? _endOtp;

  AnimationController? _driverMarkerAnimController;
  Animation<double>? _driverMarkerAnim;
  LatLng? _animStartPos;
  LatLng? _animEndPos;

  late Map<String, dynamic> _driver;

  bool _hasNavigatedToRating = false;
  bool _driverDetailsLoaded = false;
  String? _bookingUserId;

  final DraggableScrollableController _sheetController =
    DraggableScrollableController();

bool _isSheetOpen = true;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> _buildDriverState({Map<String, dynamic>? source}) {
    final d = source ?? widget.driverData ?? {};
    final rideMode = widget.vehicle['name']?.toString();
    final isGenericRideLabel = rideMode == null ||
        rideMode.isEmpty ||
        rideMode.toLowerCase() == 'economy' ||
        rideMode.toLowerCase() == 'transglobe';

    final rawImg = (d['profileImage'] != null && d['profileImage'].toString().isNotEmpty)
        ? d['profileImage'].toString()
        : (d['photo'] != null && d['photo'].toString().isNotEmpty)
            ? d['photo'].toString()
            : (d['avatar'] != null && d['avatar'].toString().isNotEmpty)
                ? d['avatar'].toString()
                : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    final vehicleModel = d['vehicle_name'] ??
        d['vehicleName'] ??
        d['vehicle_model'] ??
        d['vehicleModel'] ??
        d['model'] ??
        d['vehicleType'] ??
        d['vehicle'] ??
        (isGenericRideLabel ? 'Cab' : rideMode);

    return {
      'id': d['driver_id'] ?? d['_id'] ?? d['uid'] ?? d['id'],
      'name': d['name']?.toString() ?? 'Driver',
      'rating': d['rating']?.toString() ?? '4.9',
      'vehicle': vehicleModel.toString(),
      'plate': (d['vehicle_number'] ??
              d['vehicleNumber'] ??
              d['vichle_number'] ??
              d['plate'] ??
              'N/A')
          .toString(),
      'phone': d['phone']?.toString() ?? '',
      'otp': widget.otp?.toString() ?? d['otp']?.toString() ?? '----',
      'image': rawImg,
    };
  }

  void _applyDriverFromMap(Map<String, dynamic>? source, {String? otp, dynamic fare}) {
    if (source == null) return;
    setState(() {
      _driver = _buildDriverState(source: source);
      if (otp != null && otp.isNotEmpty) {
        _driver['otp'] = otp;
      }
      if (fare != null) {
        _currentFare = _parseDouble(fare);
      }
      _driverDetailsLoaded = _driver['name']?.toString() != 'Driver' ||
          (_driver['phone']?.toString().isNotEmpty ?? false);
      _updateDisplayedOtp();
    });
    _applyDriverLocation(source);
  }

  void _updateDisplayedOtp() {
    String resolvedOtp = '----';

    if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
      if (_startOtp != null && _startOtp!.isNotEmpty && _startOtp != '----') {
        resolvedOtp = _startOtp!;
      } else if (_segments.isNotEmpty) {
        final activeSegIndex = _segments.indexWhere((s) => s.status != 'completed');
        if (activeSegIndex != -1) {
          resolvedOtp = _segments[activeSegIndex].otp ?? widget.otp ?? '----';
        } else {
          resolvedOtp = widget.otp ?? '----';
        }
      } else {
        resolvedOtp = widget.otp ?? '----';
      }
    } else if (['ongoing', 'in_transit'].contains(_rawStatus)) {
      if (_endOtp != null && _endOtp!.isNotEmpty && _endOtp != '----') {
        resolvedOtp = _endOtp!;
      } else {
        final isLogisticsOrShuttle = _segments.isNotEmpty ||
            widget.vehicle['name']?.toString().toLowerCase().contains('shuttle') == true ||
            widget.vehicle['name']?.toString().toLowerCase().contains('truck') == true ||
            widget.vehicle['name']?.toString().toLowerCase().contains('cargo') == true;

        if (isLogisticsOrShuttle) {
          resolvedOtp = widget.otp ?? '----';
        }
      }
    }

    if (resolvedOtp == '----' && _driver['otp'] != null && _driver['otp'] != '----') {
      if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
        resolvedOtp = _driver['otp']!;
      }
    }

    _driver['otp'] = resolvedOtp;
  }

  bool get _shouldShowOtp {
    final currentOtp = _driver['otp']?.toString().trim() ?? '';
    // If the OTP is blank or dashes, never show the OTP box
    if (currentOtp.isEmpty || currentOtp == '----' || currentOtp.contains('-')) {
      return false;
    }

    final isLogistics = _segments.isNotEmpty ||
        widget.vehicle['name']?.toString().toLowerCase().contains('shuttle') == true ||
        widget.vehicle['name']?.toString().toLowerCase().contains('truck') == true ||
        widget.vehicle['name']?.toString().toLowerCase().contains('cargo') == true;

    // For ongoing rides, cab rides do NOT need OTP; only multi-stop/delivery with endOtp
    if (['ongoing', 'in_transit'].contains(_rawStatus)) {
      return isLogistics && _endOtp != null && _endOtp!.isNotEmpty && _endOtp != '----';
    }

    if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
      return true;
    }

    return false;
  }

  void _applyDriverLocation(Map<String, dynamic> source) {
    final lat = _parseDouble(
      source['latitude'] ?? source['lat'] ?? source['location']?['latitude'],
    );
    final lng = _parseDouble(
      source['longitude'] ?? source['lng'] ?? source['location']?['longitude'],
    );
    if (lat == 0 && lng == 0) return;
    
    final oldDriverPos = _driverPos;
    final newDriverPos = LatLng(lat, lng);
    final wasDriverPosNull = oldDriverPos == null;

    final pLat = _coord(widget.pickup, true);
    final pLng = _coord(widget.pickup, false);
    final dLat = _coord(widget.dropoff, true);
    final dLng = _coord(widget.dropoff, false);
    final destination = ['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)
        ? LatLng(pLat, pLng)
        : LatLng(dLat, dLng);

    setState(() {
      _driverHeading = _parseDouble(source['heading']);
      _driverETA = _calculateEstimatedTime(newDriverPos, destination);
    });

    if (wasDriverPosNull) {
      setState(() {
        _driverPos = newDriverPos;
      });
      _loadRoute();
    } else {
      _animStartPos = _driverPos ?? oldDriverPos;
      _animEndPos = newDriverPos;
      _driverMarkerAnimController?.forward(from: 0.0);

      final distanceMoved = const Distance().as(LengthUnit.Meter, oldDriverPos, newDriverPos);
      if (distanceMoved > 150) {
        _loadRoute();
      }
    }
  }

  IconData get _vehicleMarkerIcon {
    final vName = widget.vehicle['name']?.toString().toLowerCase() ?? '';
    final vType = widget.vehicle['type']?.toString().toLowerCase() ?? '';
    final rawType = widget.vehicle['category']?.toString().toLowerCase() ?? '';
    if (vName.contains('truck') || vType.contains('truck') || vName.contains('cargo') || 
        rawType.contains('logistics') || _segments.isNotEmpty) {
      return Icons.local_shipping;
    }
    if (vName.contains('bus') || vType.contains('bus') || vName.contains('shuttle') || rawType.contains('shuttle')) {
      return Icons.directions_bus;
    }
    return Icons.navigation;
  }

  double _coord(Map<String, dynamic> point, bool isLat) {
    if (isLat) {
      return _parseDouble(point['lat'] ?? point['latitude']);
    }
    return _parseDouble(point['lng'] ?? point['longitude']);
  }

  @override
  void initState() {
    super.initState();

    _driverMarkerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _driverMarkerAnim = CurvedAnimation(
      parent: _driverMarkerAnimController!,
      curve: Curves.easeInOutQuad,
    )..addListener(() {
        if (_animStartPos != null && _animEndPos != null && mounted) {
          final t = _driverMarkerAnim!.value;
          final lat = _animStartPos!.latitude + (_animEndPos!.latitude - _animStartPos!.latitude) * t;
          final lng = _animStartPos!.longitude + (_animEndPos!.longitude - _animStartPos!.longitude) * t;
          setState(() {
            _driverPos = LatLng(lat, lng);
          });
        }
      });

    _driver = _buildDriverState();
    if (widget.driverData != null) {
      _applyDriverFromMap(Map<String, dynamic>.from(widget.driverData!));
    }
    _currentFare = _parseDouble(widget.vehicle['price']);
    _rawStatus = 'accepted';
    _rideStatus = _mapStatusLabel(_rawStatus);

    _loadRoute();
    _fetchDriverAndRideDetails();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = ref.read(authServiceProvider);
      await authService.waitForSession();
      if (!mounted) return;

      final userProfile = await ref.read(fullUserProfileProvider.future).catchError((_) => null);
      final mongoUserId = userProfile?.id;
      final firebaseId = authService.currentUser?.uid;
      final userName = userProfile?.name;
      final socketRooms = <String>{
        if (mongoUserId != null && mongoUserId.isNotEmpty) mongoUserId,
        if (firebaseId != null && firebaseId.isNotEmpty) firebaseId,
        if (_bookingUserId != null && _bookingUserId!.isNotEmpty) _bookingUserId!,
      };
      if (socketRooms.isNotEmpty) {
        ref.read(socketServiceProvider).connect(
          socketRooms.first,
          name: userName,
          additionalUserIds: socketRooms.skip(1).toList(),
        );
      } else {
        // Fallback room connection using rideId for guest tracking
        ref.read(socketServiceProvider).connect(widget.rideId, name: 'Guest User');
      }

      ref.read(socketServiceProvider).joinRide(widget.rideId);

      _driverPollTimer?.cancel();
      _driverPollTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _fetchDriverAndRideDetails(),
      );

      _acceptedSubscription =
          ref.read(socketServiceProvider).rideAcceptedStream.listen((data) {
        if (data['rideId']?.toString() != widget.rideId.toString()) return;
        if (!mounted) return;
        final driver = data['driver'];
        if (driver is Map) {
          _applyDriverFromMap(
            Map<String, dynamic>.from(driver),
            otp: data['otp']?.toString(),
            fare: data['fare'],
          );
        }
        setState(() {
          _rawStatus = (data['status'] ?? 'accepted').toString().toLowerCase();
          _rideStatus = _mapStatusLabel(_rawStatus);
        });
        _loadRoute();
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fitBounds();
      });

      // Listen for status updates
      _statusSubscription = ref.read(socketServiceProvider).rideStatusStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          final newStatus = data['status']?.toString() ?? _rawStatus;
          if (mounted) {
            final oldRawStatus = _rawStatus;
            setState(() {
              _rawStatus = newStatus.toLowerCase();
              _rideStatus = _mapStatusLabel(_rawStatus);
              if (data['driver'] != null && data['driver'] is Map) {
                _applyDriverFromMap(Map<String, dynamic>.from(data['driver']));
              }
              if (data['paymentStatus'] != null) {
                _paymentStatus = data['paymentStatus'].toString();
              }
              _updateDisplayedOtp();
            });

            if (_rawStatus != oldRawStatus) {
              _loadRoute();
            }

            if (_rawStatus == 'cancelled') {
              if (data['cancelledBy'] == 'driver' || (data['reason'] != null && data['reason'].toString().toLowerCase().contains('driver'))) {
                _showDriverCancelledDialog(data['message']?.toString());
              } else if (oldRawStatus == 'ongoing' || oldRawStatus == 'in_transit') {
                if (data['ride'] != null && data['ride'] is Map) {
                  _showCancellationSummaryDialog(Map<String, dynamic>.from(data['ride']));
                }
              }
            }

            if ((_rawStatus == 'completed' || _rawStatus == 'delivered') && !_hasNavigatedToRating) {
              _navigateToRating();
            }
          }
        }
      });

      _negotiateSubscription = ref.read(socketServiceProvider).negotiateReceivedStream.listen((data) {
        final rId = (data['rideId'] ?? data['bookingId'])?.toString();
        if (rId == widget.rideId.toString() && mounted) {
          _showNegotiationPopup(Map<String, dynamic>.from(data));
        }
      });

      _cancelByDriverSubscription = ref.read(socketServiceProvider).rideCancelledByDriverStream.listen((data) {
        final rId = (data['rideId'] ?? data['bookingId'])?.toString();
        if (rId == widget.rideId.toString() && mounted) {
          _showDriverCancelledDialog(data['message']?.toString());
        }
      });

      _locationSubscription =
          ref.read(socketServiceProvider).driverLocationStream.listen((data) {
        final receivedId = (data['rideId'] ?? data['bookingId'])?.toString().toLowerCase();
        final currentId = widget.rideId.toString().toLowerCase();
        if (receivedId != null && receivedId.isNotEmpty && receivedId != currentId) {
          return;
        }
        if (!mounted) return;
        _applyDriverLocation(Map<String, dynamic>.from(data));
      });
      // Listen for fare increase
      _fareSubscription = ref.read(socketServiceProvider).fareIncreasedStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          final amount = data['amount'];
          final newFareVal = data['newFare'];
          double newFareDouble = 0.0;
          if (newFareVal is num) {
            newFareDouble = newFareVal.toDouble();
          } else if (newFareVal is String) {
            newFareDouble = double.tryParse(newFareVal) ?? 0.0;
          }
          
          if (mounted) {
            setState(() {
              _currentFare = newFareDouble;
            });
            _showFareIncreaseDialog(amount, newFareDouble);
          }
        }
      });

      _roadmapSubscription = ref.read(socketServiceProvider).roadmapUpdatedStream.listen((data) {
        if (data['rideId']?.toString() == widget.rideId.toString() && mounted) {
           final List segmentsList = data['segments'] ?? [];
           setState(() {
              _segments = segmentsList.map((s) => LogisticsSegment.fromJson(s)).toList();
              _updateDisplayedOtp();
           });
        }
      });
    });
  }

  bool _isPaying = false;

  void _navigateToRating() {
    if (_hasNavigatedToRating || !mounted) return;
    _hasNavigatedToRating = true;
    ref.read(chatProvider.notifier).clearChat();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RatingScreen(driver: _driver, bookingId: widget.rideId),
      ),
    );
  }

  Future<void> _processPayment(String method) async {
    final cleanMethod = method.toLowerCase();
    if (cleanMethod == 'online' || cleanMethod == 'card' || cleanMethod == 'upi') {
      try {
        final repo = ref.read(restApiRepositoryProvider);
        final cfgRes = await repo.getPaymentGatewayConfig();
        final isConfigured = cfgRes.success && cfgRes.data != null && 
          ((cfgRes.data!['configured'] == true) || 
           (cfgRes.data!['keyId'] != null && cfgRes.data!['keyId'].toString().trim().isNotEmpty));

        if (!isConfigured) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: context.theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text("Pay in Cash", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                content: Text(
                  "Online payment gateway is not yet enabled. Please pay in cash to the driver. We will enable online payment soon.",
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 15),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("Cancel", style: TextStyle(color: context.colors.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _processPayment('cash');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4A2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Pay Cash", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Error verifying gateway config: $e');
      }
    }

    setState(() => _isPaying = true);
    try {
      final repo = ref.read(restApiRepositoryProvider);
      await repo.payRide(widget.rideId, {
        'paymentMethod': method,
        'amount': _currentFare,
      });

      ref.read(socketServiceProvider).socket?.emit('ride_payment', {
        'rideId': widget.rideId,
        'bookingId': widget.rideId,
        'paymentStatus': 'paid',
        'paymentMethod': method,
        'amount': _currentFare,
      });

      setState(() {
        _paymentStatus = 'paid';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${_currentFare.toStringAsFixed(0)} via ${method.toUpperCase()} completed!'),
            backgroundColor: const Color(0xFF0F4A2C),
          ),
        );
        // After ride completed and payment done, redirect to home/rating
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _navigateToRating();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  Future<void> _fetchDriverAndRideDetails() async {
    if (!mounted) return;
    try {
      final repo = ref.read(restApiRepositoryProvider);

      final driverRes = await repo.getDriverDetailsForBooking(widget.rideId);
      if (driverRes.success && driverRes.data != null && mounted) {
        final driver = driverRes.data!['driver'];
        final booking = driverRes.data!['booking'];
        if (driver is Map) {
          _applyDriverFromMap(
            Map<String, dynamic>.from(driver),
            otp: booking is Map ? booking['otp']?.toString() : null,
            fare: booking is Map ? booking['fare'] : null,
          );
        }
        if (booking is Map) {
          if (booking['startOtp'] != null) _startOtp = booking['startOtp'].toString();
          if (booking['endOtp'] != null) _endOtp = booking['endOtp'].toString();
          if (booking['otp'] != null && _startOtp == null) _startOtp = booking['otp'].toString();
          if (booking['userId'] != null) {
            final uidStr = booking['userId'].toString();
            if (uidStr.isNotEmpty && uidStr != _bookingUserId) {
              setState(() {
                _bookingUserId = uidStr;
              });
              ref.read(socketServiceProvider).registerAdditionalRoom(uidStr, name: 'Guest User');
            }
          }
          if (booking['status'] != null) {
            final newStatus = booking['status'].toString().toLowerCase();
            final oldRawStatus = _rawStatus;
            setState(() {
              _rawStatus = newStatus;
              _rideStatus = _mapStatusLabel(_rawStatus);
              _updateDisplayedOtp();
            });
            if (_rawStatus != oldRawStatus) {
              _loadRoute();
            }
            if ((_rawStatus == 'completed' || _rawStatus == 'delivered') && !_hasNavigatedToRating) {
              _navigateToRating();
            }
          }
          if (booking['paymentStatus'] != null) {
            setState(() {
              _paymentStatus = booking['paymentStatus'].toString().toLowerCase();
            });
          }
        }
      } else if (!_driverDetailsLoaded && widget.driverData != null) {
        _applyDriverFromMap(Map<String, dynamic>.from(widget.driverData!));
      }

      final rideRes = await repo.getBookingDetails(widget.rideId);
      if (rideRes.success && rideRes.data != null && mounted) {
        final ride = rideRes.data!;
        final rawDriver = ride.rawJson['driver'];
        if (ride.rawJson['startOtp'] != null) _startOtp = ride.rawJson['startOtp'].toString();
        if (ride.rawJson['endOtp'] != null) _endOtp = ride.rawJson['endOtp'].toString();
        if (ride.rawJson['otp'] != null && _startOtp == null) _startOtp = ride.rawJson['otp'].toString();
        
        if (ride.userId.isNotEmpty && ride.userId != _bookingUserId) {
          setState(() {
            _bookingUserId = ride.userId;
          });
          ref.read(socketServiceProvider).registerAdditionalRoom(ride.userId, name: 'Guest User');
        }

        if (ride.driver != null) {
          _applyDriverFromMap({
            'name': ride.driver!.name,
            'phone': ride.driver!.phone,
            'vehicle_name': ride.driver!.vehicle,
            if (rawDriver is Map) ...Map<String, dynamic>.from(rawDriver),
          });
        }
        final oldRawStatus = _rawStatus;
        setState(() {
          _segments = ride.segments;
          _currentFare = ride.fare!;
          _rawStatus = ride.status.toLowerCase();
          _rideStatus = _mapStatusLabel(_rawStatus);
          _updateDisplayedOtp();
        });
        if (_rawStatus != oldRawStatus) {
          _loadRoute();
        }
        if ((_rawStatus == 'completed' || _rawStatus == 'delivered') && !_hasNavigatedToRating) {
          _navigateToRating();
        }
      }
    } catch (e) {
      debugPrint('Error fetching ride/driver details: $e');
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _locationSubscription?.cancel();
    _fareSubscription?.cancel();
    _roadmapSubscription?.cancel();
    _acceptedSubscription?.cancel();
    _negotiateSubscription?.cancel();
    _cancelByDriverSubscription?.cancel();
    _driverPollTimer?.cancel();
    _driverMarkerAnimController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final pLat = _coord(widget.pickup, true);
    final pLng = _coord(widget.pickup, false);
    final dLat = _coord(widget.dropoff, true);
    final dLng = _coord(widget.dropoff, false);

    LatLng startPos;
    LatLng endPos;

    if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
      // Driver to Pickup route
      startPos = _driverPos ?? LatLng(pLat, pLng);
      endPos = LatLng(pLat, pLng);
    } else {
      // Driver/Pickup to Dropoff route
      startPos = _driverPos ?? LatLng(pLat, pLng);
      endPos = LatLng(dLat, dLng);
    }

    // Avoid loading route between identical coordinates to prevent errors
    if (startPos.latitude == endPos.latitude && startPos.longitude == endPos.longitude) {
      if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
        // Fallback to showing full trip route if driver is already at pickup/unknown
        startPos = LatLng(pLat, pLng);
        endPos = LatLng(dLat, dLng);
      } else {
        return;
      }
    }

    try {
      final routeData = await LocationService.getRouteData(startPos, endPos);
      if (mounted) {
        setState(() {
          final List<dynamic> rawPoints = routeData['points'] ?? [];
          _routePoints = rawPoints.map((p) => LatLng(p[0], p[1])).toList();
        });
        _fitBounds();
      }
    } catch (e) {
      if (mounted) _fitBounds(); // Fallback to direct bounds
    }
  }

  void _fitBounds({bool centerOnDriver = false}) {
    if (!mounted) return;

    List<LatLng> boundsPoints = List<LatLng>.from(_routePoints);
    
    // Fallback bounds if route is empty
    if (boundsPoints.isEmpty || boundsPoints.length < 2) {
      boundsPoints = [
        LatLng(_coord(widget.pickup, true), _coord(widget.pickup, false)),
        LatLng(_coord(widget.dropoff, true), _coord(widget.dropoff, false)),
      ];
    }

    if (_driverPos != null) {
      boundsPoints.add(_driverPos!);
    }
    
    try {
      final validPoints = boundsPoints.where((p) => 
        p.latitude >= -90 && p.latitude <= 90 && 
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) {
        if (validPoints.isNotEmpty) {
          _animatedMapMove(validPoints.first, 15.0);
        }
        return;
      }

      final bounds = LatLngBounds.fromPoints(validPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 150,
            bottom: 450,
            left: 50,
            right: 50,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_mapController.camera.center.latitude.isFinite) return;

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  bool get _isBusBooking {
    final vName = widget.vehicle['name']?.toString().toLowerCase() ?? '';
    final vType = widget.vehicle['type']?.toString().toLowerCase() ?? '';
    final rawType = widget.vehicle['category']?.toString().toLowerCase() ?? '';
    return vName.contains('bus') || vType.contains('bus') || vName.contains('shuttle') || 
           rawType.contains('shuttle');
  }

  String _mapStatusLabel(String status) {
    if (_isBusBooking) {
      switch (status.toLowerCase()) {
        case 'pending':
          return 'Bus Booking Confirmed (Driver Assignment)';
        case 'accepted':
          return 'Bus Driver Assigned (Tracking Active)';
        case 'on_the_way':
          return 'Bus On The Way • 30m Live Tracking';
        case 'arrived':
          return 'Bus Arrived at Boarding Point';
        case 'ongoing':
          return 'Bus Trip in Progress';
        case 'completed':
          return 'Bus Trip Completed';
        case 'cancelled':
          return 'Bus Booking Cancelled';
      }
    }
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Driver Accepted';
      case 'on_the_way':
        return 'Driver on the way';
      case 'arrived':
        return 'Driver has arrived';
      case 'ongoing':
        return 'Trip in progress';
      case 'completed':
        return 'Trip Completed';
      case 'cancelled':
        return 'Ride Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _calculateEstimatedTime(LatLng start, LatLng end) {
    final distanceInMeters = const Distance().as(LengthUnit.Meter, start, end);
    final distanceInKm = distanceInMeters / 1000.0;
    // Assume average speed of 30 km/h in city traffic (500 meters per minute)
    final minutes = (distanceInMeters / 500).ceil();
    
    String distanceStr = distanceInKm < 0.1 
        ? "${distanceInMeters.toStringAsFixed(0)} m" 
        : "${distanceInKm.toStringAsFixed(1)} km";

    if (distanceInMeters < 100) return "Arriving now ($distanceStr)";
    return "$distanceStr away ($minutes ${minutes == 1 ? 'min' : 'mins'})";
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showFareIncreaseDialog(dynamic amount, double newFare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text("Fare Increased", style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Driver has increased the fare by ₹$amount.",
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "New Estimated Fare: ₹${newFare.toStringAsFixed(0)}",
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDriverCancelledDialog([String? customMessage]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text("Ride Cancelled", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          customMessage ?? "Driver cancelled the ride. Please make a booking again.",
          style: TextStyle(color: context.colors.textSecondary, fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Make a Booking Again", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNegotiationPopup(Map<String, dynamic> data) {
    final extraFare = _parseDouble(data['extraFare'] ?? data['amount'] ?? 0);
    final newFare = _parseDouble(data['newFare'] ?? (_currentFare + extraFare));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.monetization_on_outlined, color: Colors.green),
            const SizedBox(width: 8),
            Text("Driver Fare Offer", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Driver proposes a fare adjustment of +₹${extraFare.toStringAsFixed(0)}.",
              style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("New Total Fare:", style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    "₹${newFare.toStringAsFixed(0)}",
                    style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(socketServiceProvider).sendNegotiateResponse(
                widget.rideId,
                false,
                extraFare: extraFare,
                newFare: _currentFare,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Negotiation declined.')),
              );
            },
            child: const Text("Deny", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(socketServiceProvider).sendNegotiateResponse(
                widget.rideId,
                true,
                extraFare: extraFare,
                newFare: newFare,
              );
              setState(() {
                _currentFare = newFare;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fare accepted: ₹${newFare.toStringAsFixed(0)}'),
                  backgroundColor: const Color(0xFF0F4A2C),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4A2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Accept", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    try {
      final wasOngoing = (_rawStatus == 'ongoing' || _rawStatus == 'in_transit');
      final repo = ref.read(restApiRepositoryProvider);
      final response = await repo.cancelBooking(
        bookingId: widget.rideId, 
        reason: 'User cancelled via app',
      );
      
      if (mounted) {
        if (response.success) {
          final rideData = response.data;
          setState(() {
            _rawStatus = 'cancelled';
            _rideStatus = _mapStatusLabel(_rawStatus);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride cancelled successfully.')),
          );
          if (wasOngoing && rideData != null) {
            _showCancellationSummaryDialog(rideData);
          } else {
            Navigator.pop(context); // Pop the tracking screen
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel ride: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling ride: $e')),
        );
      }
    }
  }

  void _showCancellationSummaryDialog(Map<String, dynamic> rideData) {
    final reason = rideData['cancelReason'] ?? 'User cancelled';
    final distance = rideData['distanceTravelled'] ?? 0.0;
    final fare = (rideData['status'] == 'cancelled')
        ? (rideData['cancellationFare'] ?? rideData['cancellationCharge'] ?? rideData['fare'] ?? rideData['totalPrice'] ?? 0)
        : (rideData['fare'] ?? rideData['totalPrice'] ?? 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text("Ride Cancelled Mid-Way", style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The ride has been cancelled during transit.",
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _summaryItem("Reason", reason.toString()),
            _summaryItem("Distance reached", "$distance km"),
            _summaryItem("Amount charged", "₹$fare"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          Text(label, style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showPaymentModeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Fare: ₹${_currentFare.toStringAsFixed(0)}',
              style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _paymentModeItem(
              icon: Icons.money,
              title: 'Cash to Driver',
              subtitle: 'Pay directly using cash',
              onTap: () {
                Navigator.pop(context);
                _processPayment('Cash');
              },
            ),
            const Divider(height: 20),
            _paymentModeItem(
              icon: Icons.qr_code_scanner,
              title: 'UPI / QR Scan',
              subtitle: 'Pay using PhonePe, GPay, Paytm etc.',
              onTap: () {
                Navigator.pop(context);
                _processPayment('UPI');
              },
            ),
            const Divider(height: 20),
            _paymentModeItem(
              icon: Icons.credit_card,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, MasterCard, Rupay etc.',
              onTap: () {
                Navigator.pop(context);
                _processPayment('Card');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentModeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.theme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("Cancel Ride?", style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel this ride? This action cannot be undone.",
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No", style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _cancelRide();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(_coord(widget.pickup, true), _coord(widget.pickup, false));
    final dropoffPos = LatLng(_coord(widget.dropoff, true), _coord(widget.dropoff, false));

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: LeafletMap(
              mapController: _mapController,
              location: {'lat': pickupPos.latitude, 'lng': pickupPos.longitude},
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 4.0,
                  color: Colors.black,
                  strokeCap: StrokeCap.round,
                ),
              ],
              markers: [
                Marker(
                  point: pickupPos,
                  width: 40,
                  height: 40,
                  child: _buildMapLabel(widget.pickup['name'] ?? 'Pickup', true),
                ),
                Marker(
                  point: dropoffPos,
                  width: 40,
                  height: 40,
                  child: _buildMapLabel(widget.dropoff['name'] ?? 'Drop-off', false),
                ),
                if (_driverPos != null)
                  Marker(
                    point: _driverPos!,
                    width: 52,
                    height: 52,
                    child: Transform.rotate(
                      angle: (_driverHeading * (3.14159 / 180)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _vehicleMarkerIcon,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Top App Bar Area & Status Banner with solid card background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopAppBar(),
                    _buildStatusBanner(),
                  ],
                ),
              ),
            ),
          ),

          // Map Controls
          Positioned(
            right: 16,
            top: 240,
            child: _buildMapControls(),
          ),

// Bottom Sheet (Draggable & Controllable)
DraggableScrollableSheet(
  controller: _sheetController,
  initialChildSize: _driverDetailsLoaded ? 0.42 : 0.12,
  minChildSize: 0.12,
  maxChildSize: 0.55,
  snap: true,
  snapSizes: const [0.12, 0.55],
  builder: (context, scrollController) {
    return _buildDriverBottomSheet(scrollController);
  },
),

          // Bottom Sheet (Persistent)
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: _buildDriverBottomSheet(),
          // ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: context.colors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              "Ride Tracking",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: context.theme.primaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ride Status: $_rideStatus",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _driverETA,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOverlaySearch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.search, color: context.colors.textSecondary),
          ),
          Expanded(
            child: Text(
              "Search destination...",
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.near_me, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBottomSheet(ScrollController scrollController) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          GestureDetector(
  onTap: () async {
    if (_isSheetOpen) {
      await _sheetController.animateTo(
        0.12,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _sheetController.animateTo(
        0.55,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      _isSheetOpen = !_isSheetOpen;
    });
  },
  child: Container(
    width: 48,
    height: 6,
    decoration: BoxDecoration(
      color: context.theme.dividerColor.withOpacity(0.3),
      borderRadius: BorderRadius.circular(3),
    ),
  ),
),
          // Container(
          //   width: 48,
          //   height: 6,
          //   decoration: BoxDecoration(
          //     color: context.theme.dividerColor.withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(3),
          //   ),
          // ),
          Expanded(
            child: SingleChildScrollView(
                controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                // Driver Info
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(
                            (_driver['image'] != null && _driver['image'].toString().trim().startsWith('http'))
                                ? _driver['image'].toString().trim()
                                : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                          ),
                          backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driver['name'],
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _driver['vehicle'],
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _driver['plate'],
                            style: TextStyle(
                              color: context.theme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _driver['phone'],
                            style: TextStyle(
                              color: context.colors.textSecondary?.withOpacity(0.7) ?? Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildCallButton(_driver['phone']),
                        const SizedBox(width: 8),
                        _buildChatButton(),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                
                 if (_shouldShowOtp)
                 Container(
                   width: double.infinity,
                   margin: const EdgeInsets.only(top: 16),
                   padding: const EdgeInsets.symmetric(vertical: 20),
                   decoration: BoxDecoration(
                     color: context.theme.primaryColor.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: context.theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                   ),
                   child: Column(
                     children: [
                       Text(
                         ['ongoing', 'in_transit'].contains(_rawStatus)
                             ? "SHARE OTP TO COMPLETE DELIVERY"
                             : "SHARE OTP TO START RIDE",
                         style: TextStyle(
                           color: context.theme.primaryColor.withValues(alpha: 0.7),
                           fontSize: 11,
                           fontWeight: FontWeight.w900,
                           letterSpacing: 1.5,
                         ),
                       ),
                       const SizedBox(height: 12),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           ..._driver['otp'].toString().split('').map((char) => Container(
                             margin: const EdgeInsets.symmetric(horizontal: 6),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                             decoration: BoxDecoration(
                               color: context.theme.primaryColor.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(
                               char,
                               style: TextStyle(
                                 color: context.colors.textPrimary,
                                 fontSize: 36,
                                 fontWeight: FontWeight.w900,
                               ),
                             ),
                           )),
                         ],
                       ),
                       const SizedBox(height: 12),
                       Text(
                         ['ongoing', 'in_transit'].contains(_rawStatus)
                             ? "Ask the delivery driver to enter this code"
                             : "Ask the driver to enter this code",
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                       ),
                       if (_endOtp != null && _endOtp!.isNotEmpty && !['ongoing', 'in_transit'].contains(_rawStatus)) ...[
                         const Divider(height: 24),
                         Text(
                           "DELIVERY OTP (KEEP SAFE FOR FINAL DROP)",
                           style: TextStyle(
                             color: Colors.amber.withOpacity(0.9),
                             fontSize: 11,
                             fontWeight: FontWeight.w900,
                             letterSpacing: 1.2,
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           _endOtp!,
                           style: TextStyle(
                             color: context.colors.textPrimary,
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             letterSpacing: 4,
                           ),
                         ),
                       ],
                     ],
                   ),
                 ),

                if (_segments.isEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trip Fare:",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${_currentFare.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_paymentStatus == 'paid')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade600, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Payment Received • ₹${_currentFare.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Make Payment",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "WAITING PAYMENT",
                                  style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isPaying ? null : () => _processPayment('online'),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text("Pay Online"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F4A2C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isPaying ? null : () => _processPayment('cash'),
                                  icon: const Icon(Icons.money, size: 16),
                                  label: const Text("Pay Cash"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.colors.textPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 20),


                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomActionButton(
                        label: "Message",
                        icon: Icons.chat_bubble_outline,
                        color: context.theme.cardColor,
                        textColor: context.colors.textPrimary ?? Colors.white,
                        onTap: () {
                          // In a real app, widget.driverData?['uid'] or similar would be needed.
                          // Based on previous fixes, some drivers have 'id' (ObjectId) or 'uid' (Firebase).
                          // Here _driver is local and we'll use whatever ID we can find.
                          final driverId = _driver['id'] ?? widget.driverData?['_id'] ?? widget.driverData?['uid'] ?? widget.driverData?['driver_id'];
                          if (driverId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: const RouteSettings(name: '/chat'),
                                builder: (_) => ChatScreen(
                                  receiverId: driverId.toString(),
                                  receiverName: _driver['name'] ?? 'Driver',
                                  senderId: _bookingUserId,
                                  vehicleNumber: _driver['plate'] ?? _driver['vehicleNumber'] ?? _driver['vehicle'],
                                  driverPhone: _driver['phone'],
                                  bookingId: widget.rideId,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Driver information not available for chat')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBottomActionButton(
                        label: "Call Driver",
                        icon: Icons.call,
                        color: context.theme.primaryColor,
                        textColor: Colors.white,
                        isPrimary: true,
                        onTap: () => _makeCall(_driver['phone']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_rawStatus == 'cancelled') {
                      Navigator.pop(context);
                      return;
                    }
                    final isTripComplete = _rawStatus == 'completed' || _rawStatus == 'delivered';
                    if (!isTripComplete) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment will be available once the driver completes the ride.')),
                      );
                      return;
                    }
                    if (_paymentStatus == 'unpaid') {
                      _showPaymentModeSelection(context);
                    } else {
                      if (!_hasNavigatedToRating) {
                        _hasNavigatedToRating = true;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RatingScreen(driver: _driver, bookingId: widget.rideId),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rawStatus == 'cancelled'
                        ? Colors.red.withOpacity(0.2)
                        : ((_rawStatus == 'completed' || _rawStatus == 'delivered')
                            ? (_paymentStatus == 'unpaid' ? context.theme.primaryColor : Colors.green)
                            : context.theme.cardColor),
                    foregroundColor: _rawStatus == 'cancelled'
                        ? Colors.red
                        : ((_rawStatus == 'completed' || _rawStatus == 'delivered')
                            ? Colors.white
                            : (context.colors.textSecondary ?? Colors.grey)),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: (_rawStatus != 'cancelled' && _paymentStatus == 'unpaid' && _segments.isEmpty) ? 8 : 0,
                    shadowColor: context.theme.primaryColor.withOpacity(0.4),
                  ),
                  child: Text(
                    _rawStatus == 'cancelled'
                        ? "Ride Cancelled (Go Back)"
                        : ((_rawStatus != 'completed' && _rawStatus != 'delivered')
                            ? (_segments.isNotEmpty ? "Delivery in Progress" : "Ride in Progress - Driver Driving")
                            : (_paymentStatus == 'unpaid'
                                ? "Pay ₹${_currentFare.toStringAsFixed(0)}"
                                : "Trip Completed (Rate Driver)")),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (_rawStatus == 'accepted' || _rawStatus == 'on_the_way' || _rawStatus == 'arrived')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => _showCancelDialog(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Cancel Ride",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: context.theme.dividerColor.withOpacity(0.1)),
                const SizedBox(height: 16),

                if (_segments.isNotEmpty) ...[
                  _buildRoadmapTimeline(),
                  const Divider(height: 48),
                ],

                // Pickup/Dropoff
                _buildLocationDetail(
                  type: "PICKUP",
                  address:
                      widget.pickup['name'] ?? widget.pickup['address'] ?? "Pickup Location",
                  color: context.theme.primaryColor,
                  isFirst: true,
                ),
                const SizedBox(height: 8),
                _buildLocationDetail(
                  type: "DROPOFF",
                  address:
                      widget.dropoff['name'] ?? widget.dropoff['address'] ?? "Drop-off Location",
                   color: Colors.red,
                  isFirst: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCallButton(String phone) {
    return GestureDetector(
      onTap: () => _makeCall(phone),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.phone, color: context.theme.primaryColor, size: 24),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () {
        // Preference: Use the ID we have in _driver first, then fallback to widget data
        final driverId = _driver['id'] ?? widget.driverData?['_id'] ?? widget.driverData?['driver_id'] ?? widget.driverData?['uid'];
        if (driverId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/chat'),
              builder: (_) => ChatScreen(
                receiverId: driverId.toString(),
                receiverName: _driver['name'] ?? 'Driver',
                senderId: _bookingUserId,
                vehicleNumber: _driver['plate'] ?? _driver['vehicleNumber'] ?? _driver['vehicle'],
                driverPhone: _driver['phone'],
                bookingId: widget.rideId,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chat_outlined, color: Colors.blue, size: 24),
      ),
    );
  }


  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetail({
    required String type,
    required String address,
    required Color color,
    required bool isFirst,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (isFirst)
              Container(
                width: 2,
                height: 24,
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapLabel(String name, bool isPickup) {
    if (isPickup) {
      return Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "A",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "B",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildRoadmapTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SHIPMENT ROADMAP",
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_segments.length} SEGMENTS",
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _segments.length,
          itemBuilder: (context, index) {
            final segment = _segments[index];
            final isCompleted = segment.status == 'completed';
            final isCurrent = segment.status == 'ongoing';
            final isLast = index == _segments.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : (isCurrent ? context.theme.primaryColor : Colors.grey[800]),
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : _getSegmentIcon(segment.mode),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isCompleted ? Colors.green : Colors.grey[800],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                segment.mode.toUpperCase(),
                                style: TextStyle(
                                  color: isCurrent ? context.theme.primaryColor : context.colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(segment.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  segment.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(segment.status),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${segment.start['name'] ?? segment.start['address'] ?? ''} → ${segment.end['name'] ?? segment.end['address'] ?? ''}",
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (segment.transportName != null && segment.transportName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "${segment.transportName} ${segment.transportNumber ?? ''}",
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            //  if (segment.price != null && segment.price! > 0)
                            // Padding(
                            //   padding: const EdgeInsets.only(top: 4),
                            //   child: Text(
                            //     "Price: ₹${segment.price!.toStringAsFixed(0)}",
                            //     style: const TextStyle(
                            //       color: Colors.green,
                            //       fontSize: 11,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                          if (segment.driverName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.colors.button,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.colors.textPrimary!.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    if (segment.driverPhoto != null && segment.driverPhoto!.isNotEmpty)
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundImage: NetworkImage(segment.driverPhoto!),
                                      )
                                    else
                                      const CircleAvatar(
                                        radius: 12,
                                        child: Icon(Icons.person, size: 12),
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            segment.driverName!,
                                            style: TextStyle(
                                              color: context.colors.textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (segment.vehicleNumber != null || segment.vehicleModel != null)
                                            Text(
                                              "${segment.vehicleModel ?? ''} (${segment.vehicleNumber ?? ''})",
                                              style: TextStyle(
                                                color: context.colors.textSecondary,
                                                fontSize: 9,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getSegmentIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'road': return Icons.local_shipping;
      case 'train': return Icons.train;
      case 'flight': return Icons.flight;
      case 'sea': return Icons.directions_boat;
      default: return Icons.local_shipping;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'ongoing': return Colors.blue;
      case 'pending': return Colors.amber;
      default: return Colors.grey;
    }
  }
}
