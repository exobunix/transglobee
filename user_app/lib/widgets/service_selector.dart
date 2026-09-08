import 'package:flutter/material.dart';
import '../core/theme.dart';

class ServiceSelector extends StatelessWidget {
  final String selectedService;
  final Function(String) onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
          _buildServiceOption(context, 'cab', 'Cab', Icons.local_taxi_rounded),
          _buildServiceOption(
            context,
            'truck',
            'Truck',
            Icons.local_shipping_rounded,
          ),
          _buildServiceOption(
            context,
            'bus',
            'Bus',
            Icons.directions_bus_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOption(
    BuildContext context,
    String serviceId,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedService == serviceId;

    return Expanded(
      child: GestureDetector(
        onTap: () => onServiceSelected(serviceId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      context.theme.primaryColor,
                      context.theme.primaryColor.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : context.colors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : context.colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
