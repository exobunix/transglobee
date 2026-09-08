import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';

class LogisticsVehicle {
  final String id;
  final String name;
  final String capacity;
  final double basePrice;
  final double pricePerKm;
  final double pricePerPiece;
  final String imageUrl;
  final List<String> routes;
  final double helperCostRate;

  LogisticsVehicle({
    required this.id,
    required this.name,
    required this.capacity,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerPiece,
    required this.imageUrl,
    this.routes = const [],
    required this.helperCostRate,
  });

  factory LogisticsVehicle.fromJson(Map<String, dynamic> json) {
    return LogisticsVehicle(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      pricePerPiece: (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      routes: (json['routes'] as List?)?.map((e) => (e is Map ? (e['_id'] ?? e['id']) : e).toString()).toList() ?? [],
      helperCostRate: (json['helperCostRate'] as num?)?.toDouble() ?? (json['pricing']?['loadingUnloadingCharges'] as num?)?.toDouble() ?? 800.0,
    );
  }
}

final logisticsVehiclesProvider = FutureProvider<List<LogisticsVehicle>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final userAsync = ref.watch(fullUserProfileProvider);
  final isLoggedIn = userAsync.value != null;

  if (isLoggedIn) {
    // Logged in user: Fetch assigned route vehicles
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/transglobe/vehicles?type=truck'),
      headers: await authService.buildAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'] ?? [];
        return data.map((jsonVal) {
          final double dynamicHelperRate = (jsonVal['pricing']?['loadingUnloadingCharges'] as num?)?.toDouble() ?? 
                                           (jsonVal['pricing']?['helperCost'] as num?)?.toDouble() ?? 
                                           800.0;
          return LogisticsVehicle(
            id: jsonVal['_id'] ?? '',
            name: jsonVal['vehicleName'] ?? '',
            capacity: (jsonVal['truckLoadCapacity'] ?? 0).toString() + ' tons',
            basePrice: (jsonVal['pricing']?['fixedPrice'] as num?)?.toDouble() != 0
                ? (jsonVal['pricing']?['fixedPrice'] as num?)?.toDouble() ?? 0.0
                : (jsonVal['pricing']?['pricePerKm'] as num?)?.toDouble() ?? 0.0,
            pricePerKm: (jsonVal['pricing']?['pricePerKm'] as num?)?.toDouble() ?? 0.0,
            pricePerPiece: 0.0,
            imageUrl: (jsonVal['photos'] != null && jsonVal['photos'].isNotEmpty) ? jsonVal['photos'][0] : '',
            routes: (jsonVal['routes'] as List?)?.map((e) => (e is Map ? (e['_id'] ?? e['id']) : e).toString()).toList() ?? [],
            helperCostRate: dynamicHelperRate,
          );
        }).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load logistics vehicles');
    }
  } else {
    // Guest user: Fetch generic logistics vehicles
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/logistics-vehicles'),
      headers: await authService.buildAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => LogisticsVehicle.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load logistics vehicles');
    }
  }
});
