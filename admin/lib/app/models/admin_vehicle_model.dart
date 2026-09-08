import 'dart:convert';

class AdminVehicleModel {
  String? id;
  String? vehicleType;
  String? vehicleName;
  String? brand;
  String? model;
  String? year;
  String? numberPlate;
  int? passengerCapacity;
  int? luggageCapacity;
  double? truckLoadCapacity;
  String? driverId;
  String? driverName;
  String? status;
  bool? isEnabled;
  String? vehicleImage;

  List<AdminVehicleRoute>? routes;

  AdminVehicleModel({
    this.id,
    this.vehicleType,
    this.vehicleName,
    this.brand,
    this.model,
    this.year,
    this.numberPlate,
    this.passengerCapacity,
    this.luggageCapacity,
    this.truckLoadCapacity,
    this.driverId,
    this.driverName,
    this.status,
    this.isEnabled,
    this.vehicleImage,
    this.routes,
  });

  factory AdminVehicleModel.fromJson(Map<String, dynamic> json) {
    String? dId;
    String? dName;
    if (json['driverId'] is Map) {
      dId = json['driverId']['_id']?.toString() ?? json['driverId']['id']?.toString();
      dName = json['driverId']['name']?.toString();
    } else {
      dId = json['driverId']?.toString();
    }

    List<AdminVehicleRoute>? routesList;
    if (json['routes'] != null && json['routes'] is List) {
      routesList = (json['routes'] as List).map((e) {
        if (e is Map) {
          return AdminVehicleRoute.fromJson(Map<String, dynamic>.from(e));
        } else {
          return AdminVehicleRoute(id: e.toString());
        }
      }).toList();
    }

    return AdminVehicleModel(
      id: json['id'] ?? json['_id']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      vehicleName: json['vehicleName']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      year: json['year']?.toString(),
      numberPlate: json['numberPlate']?.toString(),
      passengerCapacity: json['passengerCapacity'] is int ? json['passengerCapacity'] : int.tryParse(json['passengerCapacity']?.toString() ?? ''),
      luggageCapacity: json['luggageCapacity'] is int ? json['luggageCapacity'] : int.tryParse(json['luggageCapacity']?.toString() ?? ''),
      truckLoadCapacity: json['truckLoadCapacity'] is num ? (json['truckLoadCapacity'] as num).toDouble() : double.tryParse(json['truckLoadCapacity']?.toString() ?? ''),
      driverId: dId,
      driverName: dName,
      status: json['status']?.toString(),
      isEnabled: json['isEnabled'] is bool ? json['isEnabled'] : (json['isEnabled']?.toString() == 'true'),
      vehicleImage: json['vehicleImage']?.toString(),
      routes: routesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'brand': brand,
      'model': model,
      'year': year,
      'numberPlate': numberPlate,
      'passengerCapacity': passengerCapacity,
      'luggageCapacity': luggageCapacity,
      'truckLoadCapacity': truckLoadCapacity,
      'driverId': driverId,
      'status': status,
      'isEnabled': isEnabled,
      'vehicleImage': vehicleImage,
    };
  }
}

class AdminVehicleRoute {
  String? id;
  String? name;
  String? source;
  String? destination;
  double? distance;
  double? startLat;
  double? startLng;
  double? endLat;
  double? endLng;

  AdminVehicleRoute({
    this.id,
    this.name,
    this.source,
    this.destination,
    this.distance,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  factory AdminVehicleRoute.fromJson(Map<String, dynamic> json) {
    return AdminVehicleRoute(
      id: json['id'] ?? json['_id']?.toString(),
      name: json['name']?.toString(),
      source: json['source']?.toString(),
      destination: json['destination']?.toString(),
      distance: double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      startLat: double.tryParse(json['startLat']?.toString() ?? '') ?? 0.0,
      startLng: double.tryParse(json['startLng']?.toString() ?? '') ?? 0.0,
      endLat: double.tryParse(json['endLat']?.toString() ?? '') ?? 0.0,
      endLng: double.tryParse(json['endLng']?.toString() ?? '') ?? 0.0,
    );
  }
}
