import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/api_state_providers.dart';

class CouponBottomSheet extends ConsumerWidget {
  final double basePrice;
  final String? appliedCoupon;
  final Function(String? code, double discount) onCouponApplied;

  const CouponBottomSheet({
    super.key,
    required this.basePrice,
    required this.appliedCoupon,
    required this.onCouponApplied,
  });

  double _calculateCouponDiscount(
    String code,
    String description,
    double basePrice,
  ) {
    final upperCode = code.toUpperCase();
    final upperDesc = description.toUpperCase();

    double? percentage;
    final pctRegExp = RegExp(r'(\d+)\s*%');
    final pctMatch =
        pctRegExp.firstMatch(upperDesc) ?? pctRegExp.firstMatch(upperCode);
    if (pctMatch != null) {
      percentage = double.tryParse(pctMatch.group(1) ?? '');
    }

    double? limitAmount;
    final rupeeRegExp = RegExp(
      r'(?:₹|RS\.?|UP\s*TO\s*₹?|SAVE\s*₹?)\s*(\d+)',
      caseSensitive: false,
    );
    final matches = rupeeRegExp.allMatches(upperDesc);
    if (matches.isNotEmpty) {
      final upToRegExp = RegExp(
        r'(?:UP\s*TO|MAX|MAXIMUM)\s*(?:₹|RS\.?)?\s*(\d+)',
        caseSensitive: false,
      );
      final upToMatch = upToRegExp.firstMatch(upperDesc);
      if (upToMatch != null) {
        limitAmount = double.tryParse(upToMatch.group(1) ?? '');
      } else {
        limitAmount = double.tryParse(matches.first.group(1) ?? '');
      }
    }

    if (limitAmount == null) {
      final genericNumberRegExp = RegExp(r'(\d+)');
      final genericMatches = genericNumberRegExp.allMatches(upperDesc);
      for (final match in genericMatches) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          if (percentage != null && val == percentage) {
            continue;
          }
          limitAmount = val;
          break;
        }
      }
    }

    if (limitAmount == null) {
      final codeNumRegExp = RegExp(r'(\d+)');
      final codeMatch = codeNumRegExp.firstMatch(upperCode);
      if (codeMatch != null) {
        final codeVal = double.tryParse(codeMatch.group(1) ?? '');
        if (codeVal != null) {
          if (upperCode.contains('PCT') ||
              upperCode.contains('PERCENT') ||
              upperCode.contains('OFF') && codeVal <= 100) {
            percentage = codeVal;
          } else {
            limitAmount = codeVal;
          }
        }
      }
    }

    if (percentage == null && limitAmount == null) {
      return 50.0;
    }

    if (percentage != null) {
      final calcDiscount = basePrice * (percentage / 100.0);
      if (limitAmount != null) {
        return calcDiscount > limitAmount ? limitAmount : calcDiscount;
      }
      return calcDiscount;
    }

    return limitAmount ?? 50.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Coupons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              if (appliedCoupon != null)
                TextButton(
                  onPressed: () {
                    onCouponApplied(null, 0.0);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          couponsAsync.when(
            data: (coupons) {
              final activeCoupons = coupons.where((c) {
                final val = c['value'];
                if (val == null) return false;
                final status =
                    val['status']?.toString().toLowerCase() ?? 'active';
                return status == 'active';
              }).toList();

              if (activeCoupons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No coupons available at the moment.',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeCoupons.length,
                  itemBuilder: (context, index) {
                    final c = activeCoupons[index];
                    final val = c['value'] ?? {};
                    final code = (val['title'] ?? c['key'] ?? '').toString();
                    final desc = (val['description'] ?? '').toString();
                    final discount = _calculateCouponDiscount(
                      code,
                      desc,
                      basePrice,
                    );

                    return _buildCouponItem(context, code, desc, discount);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Failed to load coupons: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCouponItem(
    BuildContext context,
    String code,
    String desc,
    double discount,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.confirmation_number,
          color: context.theme.primaryColor,
        ),
      ),
      title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      trailing: ElevatedButton(
        onPressed: () {
          onCouponApplied(code, discount);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Apply'),
      ),
    );
  }
}
