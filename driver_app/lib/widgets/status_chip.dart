import 'package:flutter/material.dart';
import '../core/theme.dart';

enum DriverStatus { available, busy, offline }

class StatusChip extends StatelessWidget {
  final DriverStatus status;
  final VoidCallback onTap;

  const StatusChip({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case DriverStatus.available:
        color = AppTheme.neonGreen;
        label = 'AVAILABLE';
        icon = Icons.check_circle;
        break;
      case DriverStatus.busy:
        color = AppTheme.earningsAmber;
        label = 'BUSY';
        icon = Icons.schedule;
        break;
      case DriverStatus.offline:
        color = AppTheme.offlineRed;
        label = 'OFFLINE';
        icon = Icons.power_settings_new;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
