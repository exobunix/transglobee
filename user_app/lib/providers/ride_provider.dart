import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_type_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';

final rideTypesProvider = FutureProvider<List<RideTypeModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final userAsync = ref.watch(fullUserProfileProvider);
  final isLoggedIn = userAsync.value != null;

  if (isLoggedIn) {
    // Logged in user: Fetch assigned route vehicles
    final response = await apiService.getWithFallback(
      '/api/transglobe/vehicles?type=car',
      '/api/transglobe/vehicles?type=car',
    );

    if (response['success'] == true) {
      final List data = response['data'] ?? [];
      return data.map((json) {
        return RideTypeModel(
          id: json['_id'] ?? '',
          name: json['vehicleName'] ?? '',
          description: json['model'] ?? '',
          icon: (json['photos'] != null && json['photos'].isNotEmpty) ? json['photos'][0] : '',
          baseFare: (json['pricing']?['fixedPrice'] as num?)?.toDouble() ?? 0.0,
          pricePerKm: (json['pricing']?['pricePerKm'] as num?)?.toDouble() ?? 0.0,
          waitingTime: '',
          status: json['status'] == 'active',
        );
      }).toList();
    }
    return [];
  } else {
    // Guest user: Fetch generic ride types
    final response = await apiService.getWithFallback(
      '/api/rides/vehicles',
      '/api/ride/ride-types',
    );
    
    if (response['success'] == true) {
      final List data = response['data'] ?? [];
      return data.map((json) => RideTypeModel.fromJson(json)).toList();
    }
    return [];
  }
});
