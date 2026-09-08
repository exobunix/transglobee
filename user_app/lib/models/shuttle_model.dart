class ShuttleRoute {
  final String routeId;
  final String from;
  final String to;
  final double fare;
  final List<String> timings;

  ShuttleRoute({
    required this.routeId,
    required this.from,
    required this.to,
    required this.fare,
    required this.timings,
  });

  factory ShuttleRoute.fromJson(Map<String, dynamic> json) {
    return ShuttleRoute(
      routeId: json['routeId'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      fare: (json['fare'] ?? 0.0).toDouble(),
      timings: List<String>.from(json['timings'] ?? []),
    );
  }
}

class ShuttleTracking {
  final String bookingId;
  final double lat;
  final double lng;
  final String eta;
  final String status;

  ShuttleTracking({
    required this.bookingId,
    required this.lat,
    required this.lng,
    required this.eta,
    required this.status,
  });

  factory ShuttleTracking.fromJson(Map<String, dynamic> json) {
    final location = json['currentLocation'] ?? {};
    return ShuttleTracking(
      bookingId: json['bookingId'] ?? '',
      lat: (location['lat'] ?? 0.0).toDouble(),
      lng: (location['lng'] ?? 0.0).toDouble(),
      eta: json['eta'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
