import 'package:flutter/material.dart';

import 'package:sizer/sizer.dart';
import '../../../core/theme.dart';
import '../../../models/address_model.dart';

class AddressSelectorWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? instruction;
  final AddressEntry? selected;
  final VoidCallback onTap;

  const AddressSelectorWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.instruction,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected != null
                ? const Color(0xFF0F5A3B)
                : Colors.grey.shade300,
            width: selected != null ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F5A3B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected?.icon ?? Icons.location_on_rounded,
                color: const Color(0xFF0F5A3B),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instruction != null && instruction!.isNotEmpty) ...[
                    Text(
                      instruction!,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F5A3B),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    selected?.label ?? title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selected != null
                        ? "${selected!.fullAddress.isNotEmpty ? selected!.fullAddress : selected!.city} (Tap to change)"
                        : subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              selected != null
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 20,
              color: const Color(0xFF0F5A3B),
            ),
          ],
        ),
      ),
    );
  }
}
