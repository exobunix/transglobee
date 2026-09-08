import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/logistics_vehicle_provider.dart';

class VehicleSelector extends StatelessWidget {
  final AsyncValue<List<LogisticsVehicle>> vehiclesAsync;
  final UserRoute? selectedRoute;
  final String? selectedVehicle;
  final Function(LogisticsVehicle vehicle) onVehicleSelected;

  const VehicleSelector({
    super.key,
    required this.vehiclesAsync,
    required this.selectedRoute,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return vehiclesAsync.when(
      data: (vehicles) {
        if (selectedRoute == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Please select an assigned route first to see available vehicles.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13.sp,
                ),
              ),
            ),
          );
        }

        final filteredVehicles = vehicles.where((v) {
          return v.routes.contains(selectedRoute!.id);
        }).toList();

        if (filteredVehicles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No vehicles assigned to the selected route.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: filteredVehicles.map((vehicle) {
              final isSelected = selectedVehicle == vehicle.name;
              return GestureDetector(
                onTap: () => onVehicleSelected(vehicle),
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      margin: const EdgeInsets.only(
                        right: 12,
                        top: 8,
                        bottom: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F5A3B).withValues(alpha: 0.05)
                            : context.theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F5A3B)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              vehicle.imageUrl,
                              height: 60,
                              width: 90,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                String defaultIcon = 'https://img.icons8.com/color/96/truck.png';
                                final lowerName = vehicle.name.toLowerCase();
                                if (lowerName.contains('bus')) {
                                  defaultIcon = 'https://img.icons8.com/color/96/bus.png';
                                } else if (lowerName.contains('car') ||
                                    lowerName.contains('dzire') ||
                                    lowerName.contains('cab')) {
                                  defaultIcon = 'https://img.icons8.com/color/96/car.png';
                                }
                                return Image.network(
                                  defaultIcon,
                                  height: 60,
                                  width: 90,
                                  fit: BoxFit.contain,
                                  errorBuilder: (___, ____, _____) => const Icon(
                                    Icons.local_shipping,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vehicle.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best for small shipments',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹${vehicle.basePrice.toInt()}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F5A3B),
                                  ),
                                ),
                                TextSpan(
                                  text: '/km',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F5A3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Load: Up to ${vehicle.capacity}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 12,
                        right: 18,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F5A3B),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
