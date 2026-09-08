class RideTypeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double baseFare;
  final double pricePerKm;
  final String waitingTime;
  final bool status;

  RideTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.baseFare,
    required this.pricePerKm,
    required this.waitingTime,
    this.status = true,
  });

  factory RideTypeModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return RideTypeModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      baseFare: parseDouble(json['baseFare']),
      pricePerKm: parseDouble(json['pricePerKm']),
      waitingTime: json['waitingTime'] ?? '',
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'waitingTime': waitingTime,
      'status': status,
    };
  }
}
