import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/api_state_providers.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // Premium colors list to style coupons dynamically
  final List<Color> _colors = [
    Colors.purple,
    Colors.blue,
    Colors.indigo,
    Colors.green,
    Colors.teal,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(couponsProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Offers & Coupons',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: couponsAsync.when(
        data: (coupons) {
          // Filter to show only active coupons
          final activeCoupons = coupons.where((c) {
            final val = c['value'];
            if (val == null) return false;
            final status = val['status']?.toString().toLowerCase() ?? 'active';
            return status == 'active';
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Apply Coupon Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.theme.dividerColor.withOpacity(0.1),
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a coupon code?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: context.colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              hintStyle: TextStyle(
                                color: context.colors.textSecondary?.withOpacity(0.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.theme.dividerColor.withOpacity(0.1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.theme.primaryColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final codeEntered = _couponController.text.trim().toUpperCase();
                            if (codeEntered.isNotEmpty) {
                              // Verify if code exists in activeCoupons
                              final found = activeCoupons.any((c) {
                                final val = c['value'] ?? {};
                                final code = (val['title'] ?? c['key'] ?? '').toString().toUpperCase();
                                return code == codeEntered;
                              });

                              if (found) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon "$codeEntered" is valid! Discount will be applied at booking.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon "$codeEntered" is invalid or expired.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              _couponController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.theme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Available Offers
              Text(
                'Available Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              if (activeCoupons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.discount_outlined, size: 48, color: context.colors.textSecondary?.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No available coupons at the moment.',
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(activeCoupons.length, (index) {
                  final c = activeCoupons[index];
                  final val = c['value'] ?? {};
                  final code = (val['title'] ?? c['key'] ?? '').toString();
                  final description = (val['description'] ?? '').toString();
                  final color = _colors[index % _colors.length];

                  // Parse discount text if possible or just use a nice representation
                  String discountText = '%';
                  if (description.contains('%')) {
                    final match = RegExp(r'(\d+)\s*%').firstMatch(description);
                    if (match != null) discountText = '${match.group(1)}%';
                  } else {
                    final match = RegExp(r'(?:₹|Rs\.?)\s*(\d+)').firstMatch(description);
                    if (match != null) {
                      discountText = '₹${match.group(1)}';
                    } else {
                      discountText = 'OFF';
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.theme.dividerColor.withOpacity(0.1),
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        // Offer Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.8),
                                color,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  discountText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Offer Footer
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Code: $code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Valid till: Active',
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Code $code copied!'),
                                      backgroundColor: color,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: color),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Copy Code',
                                  style: TextStyle(color: color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
    );
  }
}
