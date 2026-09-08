import 'package:flutter/material.dart';
import '../core/theme.dart';

class DelayReasonSheet extends StatelessWidget {
  final Function(String) onReasonSelected;

  const DelayReasonSheet({
    super.key,
    required this.onReasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = [
      'Heavy Traffic',
      'Vehicle Issue',
      'Loading Delay',
      'Breakdown',
      'Police Check',
      'Road Block',
      'Weather Condition',
      'Other Reason',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Report Delay Reason',
                style: TextStyle(
                  color: AppTheme.darkTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.darkTextSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep the customer informed about the delay',
            style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: reasons.map((reason) => _reasonChip(context, reason)).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _reasonChip(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        onReasonSelected(label);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkDivider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
