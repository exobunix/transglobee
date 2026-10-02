import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme.dart';

class LogisticsModeItem {
  final String key;
  final String name;
  final String tagline;
  final IconData icon;
  final double baseFare;
  final double perKmRate;
  final int helperCost;

  const LogisticsModeItem({
    required this.key,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.baseFare,
    required this.perKmRate,
    required this.helperCost,
  });
}

class LogisticsModeSelector extends StatelessWidget {
  final String selectedMode;
  final double distanceKm;
  final ValueChanged<LogisticsModeItem> onModeSelected;

  static const List<LogisticsModeItem> modes = [
    LogisticsModeItem(
      key: 'logistics_truck',
      name: 'Truck',
      tagline: 'Surface Road Freight',
      icon: Icons.local_shipping_outlined,
      baseFare: 500,
      perKmRate: 25,
      helperCost: 300,
    ),
    LogisticsModeItem(
      key: 'logistics_train',
      name: 'Train',
      tagline: 'Railway Cargo Transport',
      icon: Icons.train_outlined,
      baseFare: 1200,
      perKmRate: 12,
      helperCost: 600,
    ),
    LogisticsModeItem(
      key: 'logistics_sea',
      name: 'Sea Cargo',
      tagline: 'Ocean Port Shipping',
      icon: Icons.directions_boat_outlined,
      baseFare: 2500,
      perKmRate: 8,
      helperCost: 1200,
    ),
    LogisticsModeItem(
      key: 'logistics_flight',
      name: 'Flight',
      tagline: 'High-speed Air Freight',
      icon: Icons.flight_takeoff_outlined,
      baseFare: 1500,
      perKmRate: 60,
      helperCost: 500,
    ),
  ];

  const LogisticsModeSelector({
    super.key,
    required this.selectedMode,
    required this.distanceKm,
    required this.onModeSelected,
  });

  double _estimatePrice(LogisticsModeItem item) {
    if (distanceKm > 0) {
      return item.baseFare + (item.perKmRate * distanceKm);
    }
    return item.baseFare;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.category_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Logistics Transport Mode',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '4 Modes Available',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = modes[index];
              final isSelected = selectedMode == item.key ||
                  (selectedMode == 'truck' && item.key == 'logistics_truck') ||
                  (selectedMode == 'train' && item.key == 'logistics_train') ||
                  (selectedMode == 'sea' && item.key == 'logistics_sea') ||
                  (selectedMode == 'flight' && item.key == 'logistics_flight');

              final estimatedFare = _estimatePrice(item);

              return GestureDetector(
                onTap: () => onModeSelected(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.08)
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: primaryColor,
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryColor
                                  : context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Est: ₹${estimatedFare.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? primaryColor
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
