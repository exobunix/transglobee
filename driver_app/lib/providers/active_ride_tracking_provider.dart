import 'package:flutter_riverpod/legacy.dart';

/// Active cab ride the driver is serving — used for live location streaming to the user.
class ActiveRideTracking {
  final String rideId;
  final String userId;

  const ActiveRideTracking({
    required this.rideId,
    required this.userId,
  });
}

final activeRideTrackingProvider =
    StateProvider<ActiveRideTracking?>((ref) => null);
