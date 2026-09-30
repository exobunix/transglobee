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

  factory LogisticsVehicle.fromJson(Map<String, dynamic> json, {double? fallbackHelperCost}) {
    final num? pKm = (json['pricing']?['pricePerKm'] as num?) ?? (json['pricePerKm'] as num?);
    final double pricePerKm = (pKm != null && pKm.toDouble() > 0) ? pKm.toDouble() : 25.0;

    final num? rawHelperRate = (json['pricing']?['loadingUnloadingCharges'] as num?) ??
                               (json['pricing']?['helperCost'] as num?) ??
                               (json['helperCostRate'] as num?) ??
                               (json['helperCost'] as num?);
    final double dynamicHelperRate = (rawHelperRate != null && rawHelperRate.toDouble() > 0)
        ? rawHelperRate.toDouble()
        : (fallbackHelperCost ?? 800.0);

    return LogisticsVehicle(
      id: json['_id'] ?? '',
      name: json['name'] ?? json['vehicleName'] ?? '',
      capacity: json['capacity'] ?? ((json['truckLoadCapacity'] ?? 0).toString() + ' tons'),
      basePrice: (json['pricing']?['fixedPrice'] as num?)?.toDouble() ?? (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      pricePerKm: pricePerKm,
      pricePerPiece: (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      imageUrl: (json['photos'] != null && json['photos'] is List && json['photos'].isNotEmpty)
          ? json['photos'][0]
          : (json['imageUrl'] ?? ''),
      routes: (json['routes'] as List?)?.map((e) => (e is Map ? (e['_id'] ?? e['id']) : e).toString()).toList() ?? [],
      helperCostRate: dynamicHelperRate,
    );
  }
}

final logisticsVehiclesProvider = FutureProvider<List<LogisticsVehicle>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final userAsync = ref.watch(fullUserProfileProvider);
  final isLoggedIn = userAsync.value != null;

  // Fetch admin configured helper cost
  double globalHelperCost = 800.0;
  try {
    final helperRes = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/pricing/helper-cost'),
      headers: await authService.buildAuthHeaders(),
    ).timeout(const Duration(seconds: 3));
    if (helperRes.statusCode == 200) {
      final helperJson = json.decode(helperRes.body);
      if (helperJson['helperCost'] != null && (helperJson['helperCost'] as num) > 0) {
        globalHelperCost = (helperJson['helperCost'] as num).toDouble();
      }
    }
  } catch (_) {}

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
          final num? pKm = (jsonVal['pricing']?['pricePerKm'] as num?) ?? (jsonVal['pricePerKm'] as num?);
          final double pricePerKm = (pKm != null && pKm.toDouble() > 0) ? pKm.toDouble() : 25.0;

          final num? rawHelperRate = (jsonVal['pricing']?['loadingUnloadingCharges'] as num?) ??
                                     (jsonVal['pricing']?['helperCost'] as num?) ??
                                     (jsonVal['helperCost'] as num?);
          final double dynamicHelperRate = (rawHelperRate != null && rawHelperRate.toDouble() > 0)
              ? rawHelperRate.toDouble()
              : globalHelperCost;

          return LogisticsVehicle(
            id: jsonVal['_id'] ?? '',
            name: jsonVal['vehicleName'] ?? '',
            capacity: (jsonVal['truckLoadCapacity'] ?? 0).toString() + ' tons',
            basePrice: (jsonVal['pricing']?['fixedPrice'] as num?)?.toDouble() ?? 0.0,
            pricePerKm: pricePerKm,
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
      return data.map((item) => LogisticsVehicle.fromJson(item, fallbackHelperCost: globalHelperCost)).toList();
    } else {
      throw Exception('Failed to load logistics vehicles');
    }
  }
});
