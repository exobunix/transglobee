import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';

enum VehicleType { cab, truck, bus }

// Sub-vehicle models for each type
class VehicleOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String basefare;
  final String perKm;
  final Color color;

  const VehicleOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.basefare,
    required this.perKm,
    required this.color,
  });
}

extension VehicleTypeExtension on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.cab:
        return 'Cab';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.bus:
        return 'Bus';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.cab:
        return Icons.local_taxi;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.bus:
        return Icons.directions_bus;
    }
  }

  Color get accentColor {
    switch (this) {
      case VehicleType.cab:
        return AppTheme.cabBlue;
      case VehicleType.truck:
        return AppTheme.truckOrange;
      case VehicleType.bus:
        return AppTheme.busPurple;
    }
  }

  String get tripLabel {
    switch (this) {
      case VehicleType.cab:
        return 'Rides';
      case VehicleType.truck:
        return 'Deliveries';
      case VehicleType.bus:
        return 'Routes';
    }
  }

  String get requestLabel {
    switch (this) {
      case VehicleType.cab:
        return 'New Ride Request';
      case VehicleType.truck:
        return 'New Shipment';
      case VehicleType.bus:
        return 'New Route Assignment';
    }
  }

  String get earningsLabel {
    switch (this) {
      case VehicleType.cab:
        return 'Ride Earnings';
      case VehicleType.truck:
        return 'Freight Earnings';
      case VehicleType.bus:
        return 'Route Earnings';
    }
  }

  String get demoTrips {
    switch (this) {
      case VehicleType.cab:
        return '12';
      case VehicleType.truck:
        return '5';
      case VehicleType.bus:
        return '8';
    }
  }

  String get demoEarnings {
    switch (this) {
      case VehicleType.cab:
        return '₹2,450';
      case VehicleType.truck:
        return '₹8,200';
      case VehicleType.bus:
        return '₹4,800';
    }
  }

  String get demoDistance {
    switch (this) {
      case VehicleType.cab:
        return '87 km';
      case VehicleType.truck:
        return '240 km';
      case VehicleType.bus:
        return '156 km';
    }
  }

  // Sub-categories for each vehicle type (like Ola's Mini/Sedan/SUV)
  List<VehicleOption> get subOptions {
    switch (this) {
      case VehicleType.cab:
        return const [
          VehicleOption(
            id: 'mini',
            name: 'Mini',
            description: 'Affordable rides',
            icon: Icons.minor_crash,
            basefare: '₹40',
            perKm: '₹8/km',
            color: Color(0xFF42A5F5),
          ),
          VehicleOption(
            id: 'sedan',
            name: 'Sedan',
            description: 'Comfortable rides',
            icon: Icons.directions_car,
            basefare: '₹70',
            perKm: '₹12/km',
            color: Color(0xFF66BB6A),
          ),
          VehicleOption(
            id: 'suv',
            name: 'SUV',
            description: 'Spacious premium',
            icon: Icons.airport_shuttle,
            basefare: '₹120',
            perKm: '₹18/km',
            color: Color(0xFFFFB74D),
          ),
          VehicleOption(
            id: 'premium',
            name: 'Premium',
            description: 'Luxury experience',
            icon: Icons.star,
            basefare: '₹200',
            perKm: '₹25/km',
            color: Color(0xFFCE93D8),
          ),
        ];
      case VehicleType.truck:
        return const [
          VehicleOption(
            id: 'pickup',
            name: 'Pickup',
            description: 'Small goods, 500kg',
            icon: Icons.fire_truck,
            basefare: '₹200',
            perKm: '₹15/km',
            color: Color(0xFFFF8A65),
          ),
          VehicleOption(
            id: 'mini_truck',
            name: 'Mini Truck',
            description: 'Medium load, 1.5T',
            icon: Icons.local_shipping,
            basefare: '₹400',
            perKm: '₹22/km',
            color: Color(0xFFFFB74D),
          ),
          VehicleOption(
            id: 'container',
            name: 'Container',
            description: 'Heavy goods, 5T',
            icon: Icons.rv_hookup,
            basefare: '₹800',
            perKm: '₹35/km',
            color: Color(0xFF4FC3F7),
          ),
          VehicleOption(
            id: 'flatbed',
            name: 'Flatbed',
            description: 'Oversize cargo, 10T',
            icon: Icons.view_in_ar,
            basefare: '₹1200',
            perKm: '₹50/km',
            color: Color(0xFFEF5350),
          ),
        ];
      case VehicleType.bus:
        return const [
          VehicleOption(
            id: 'mini_bus',
            name: 'Mini Bus',
            description: '12-seater shuttle',
            icon: Icons.airport_shuttle,
            basefare: '₹300',
            perKm: '₹20/km',
            color: Color(0xFFBA68C8),
          ),
          VehicleOption(
            id: 'standard',
            name: 'Standard',
            description: '30-seater bus',
            icon: Icons.directions_bus,
            basefare: '₹600',
            perKm: '₹30/km',
            color: Color(0xFF7986CB),
          ),
          VehicleOption(
            id: 'luxury',
            name: 'Luxury',
            description: 'AC Volvo, 40-seater',
            icon: Icons.directions_bus_filled,
            basefare: '₹1000',
            perKm: '₹45/km',
            color: Color(0xFFFFD54F),
          ),
          VehicleOption(
            id: 'sleeper',
            name: 'Sleeper',
            description: 'Night travel, 36-berth',
            icon: Icons.airline_seat_flat,
            basefare: '₹1500',
            perKm: '₹55/km',
            color: Color(0xFF4DB6AC),
          ),
        ];
    }
  }
}

class VehicleTypeNotifier extends Notifier<VehicleType> {
  @override
  VehicleType build() => VehicleType.cab;

  void select(VehicleType type) => state = type;
}

final vehicleTypeProvider = NotifierProvider<VehicleTypeNotifier, VehicleType>(
  VehicleTypeNotifier.new,
);

class SelectedSubVehicleNotifier extends Notifier<String> {
  @override
  String build() => 'sedan';

  void select(String id) => state = id;
}

final selectedSubVehicleProvider =
    NotifierProvider<SelectedSubVehicleNotifier, String>(
  SelectedSubVehicleNotifier.new,
);
