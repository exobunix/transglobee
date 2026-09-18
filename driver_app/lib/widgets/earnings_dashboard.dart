import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../providers/vehicle_type_provider.dart';
import '../features/driver/controllers/driver_providers.dart';

class EarningsDashboard extends ConsumerWidget {
  const EarningsDashboard({super.key});

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleType = ref.watch(vehicleTypeProvider);
    final selectedSub = ref.watch(selectedSubVehicleProvider);
    final earningsState = ref.watch(earningsControllerProvider);
    final driverProfileState = ref.watch(driverProfileControllerProvider);
    
    final earningsData = earningsState.data;
    final todayEarnings = earningsData?.todayEarnings ?? 0.0;
    final totalTrips = driverProfileState.data?.totalRides ?? (earningsData?.records.length ?? 0);
    
    final currentOption = vehicleType.subOptions.where((o) => o.id == selectedSub).firstOrNull ?? 
                         (vehicleType.subOptions.isNotEmpty ? vehicleType.subOptions.first : vehicleType.subOptions.firstWhere((_) => true, orElse: () => vehicleType.subOptions.isEmpty ? const VehicleOption(id: 'default', name: 'Standard', description: '', icon: Icons.minor_crash, basefare: '', perKm: '', color: Colors.blue) : vehicleType.subOptions.first));
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.95),
                  AppTheme.darkSurface.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: vehicleType.accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.earningsAmber.withValues(alpha: 0.2),
                            AppTheme.earningsAmber.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.earningsAmber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Today's ${vehicleType.earningsLabel}",
                              style: const TextStyle(
                                color: AppTheme.darkTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${currentOption.name} Mode',
                              style: TextStyle(
                                color: currentOption.color.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3-stat row
                Row(
                  children: [
                    _buildStatCard(
                      'Earnings',
                      _formatCurrency(todayEarnings),
                      Icons.currency_rupee,
                      AppTheme.earningsAmber,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      vehicleType.tripLabel,
                      '$totalTrips',
                      vehicleType.icon,
                      vehicleType.accentColor,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Status',
                      'Active',
                      Icons.check_circle_outline,
                      const Color(0xFF64FFDA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGreen.withValues(alpha: 0.15),
            AppTheme.neonGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neonGreen.withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: AppTheme.neonGreen, size: 13),
          SizedBox(width: 4),
          Text(
            '+18%',
            style: TextStyle(
              color: AppTheme.neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(VehicleType vehicleType) {
    final barData = [0.5, 0.7, 0.9, 0.6, 1.0, 0.45, 0.3];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.darkDivider.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '₹14,280',
                style: TextStyle(
                  color: AppTheme.darkTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == 4;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 600 + (i * 80)),
                          tween: Tween(begin: 0, end: barData[i]),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Container(
                              height: 20 * value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isToday
                                      ? [
                                          vehicleType.accentColor,
                                          vehicleType.accentColor
                                              .withValues(alpha: 0.7),
                                        ]
                                      : [
                                          vehicleType.accentColor
                                              .withValues(alpha: 0.4),
                                          vehicleType.accentColor
                                              .withValues(alpha: 0.15),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isToday
                                    ? [
                                        BoxShadow(
                                          color: vehicleType.accentColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 3),
                        Text(
                          days[i],
                          style: TextStyle(
                            color: isToday
                                ? vehicleType.accentColor
                                : AppTheme.darkTextSecondary,
                            fontSize: 8,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandHint(VehicleType vehicleType) {
    final hints = {
      VehicleType.cab: '🔥  High demand area nearby — surge 1.5x',
      VehicleType.truck: '📦  Freight demand high on NH-48 route',
      VehicleType.bus: '🚌  Peak hours — extra routes available',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.earningsAmber.withValues(alpha: 0.1),
            AppTheme.earningsAmber.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.earningsAmber.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hints[vehicleType]!,
              style: const TextStyle(
                color: AppTheme.earningsAmber,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
