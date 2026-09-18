import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../core/network/api_state.dart';
import '../../features/driver/models/response/earnings_pagination_model.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletControllerProvider);
    final earningsState = ref.watch(earningsControllerProvider);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (walletState.status == ApiStatus.initial) {
        ref.read(walletControllerProvider.notifier).getDriverWallet();
      }
      if (earningsState.status == ApiStatus.initial) {
        ref.read(earningsControllerProvider.notifier).getDriverEarnings();
      }
    });

    final wallet = walletState.data;
    final earnings = earningsState.data;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.darkSurface,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Wallet', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Balance card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.earningsAmber.withValues(alpha: 0.15), AppTheme.darkSurface],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppTheme.earningsAmber.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('₹${wallet?.balance.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildMiniStat('Total Earned', '₹${((earnings?.totalEarnings ?? 0.0) / 1000).toStringAsFixed(1)}k'),
                                const SizedBox(width: 24),
                                _buildMiniStat('Pending Payout', '₹${(wallet?.pendingPayout ?? 0.0).toStringAsFixed(0)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons: Add Money & Request Payout
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showTopUpSheet(context, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.15),
                                foregroundColor: AppTheme.neonGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, AppRouter.payout),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkCard,
                                foregroundColor: AppTheme.earningsAmber,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppTheme.earningsAmber.withValues(alpha: 0.3)),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.account_balance, size: 20),
                              label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        children: [
                          _buildStatBox('Total Trips', '${earnings?.records.length ?? 0}', AppTheme.neonGreen),
                          const SizedBox(width: 10),
                          _buildStatBox('Last Sync', wallet?.lastUpdated.split('T').first ?? 'Today', AppTheme.cabBlue),
                          const SizedBox(width: 10),
                          _buildStatBox('Currency', wallet?.currency ?? 'INR', AppTheme.busPurple),
                        ],
                      ),
                    ],
                  ),
                ),
                // Transactions header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transactions', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRouter.bankAccounts),
                        child: const Text('Manage Banks', style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (earningsState.status == ApiStatus.loading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
          
          if (earnings != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TransactionTile(record: earnings.records[i]),
                childCount: earnings.records.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Add Money to Wallet',
                    style: TextStyle(
                      color: AppTheme.darkTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Top-up request will be reviewed and approved by Admin before balance is credited.',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Preset chips
                  Wrap(
                    spacing: 10,
                    children: [200, 500, 1000, 2000].map((amt) {
                      final isSelected = amountController.text == amt.toString();
                      return ChoiceChip(
                        label: Text('₹$amt',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                        selected: isSelected,
                        selectedColor: AppTheme.neonGreen,
                        backgroundColor: AppTheme.darkCard,
                        onSelected: (selected) {
                          setModalState(() {
                            amountController.text = selected ? amt.toString() : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      hintText: 'Enter amount',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 18),
                      filled: true,
                      fillColor: AppTheme.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = amountController.text.trim();
                              final amt = double.tryParse(text);
                              if (amt == null || amt <= 0) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid amount'),
                                    backgroundColor: AppTheme.offlineRed,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final success = await ref
                                  .read(walletControllerProvider.notifier)
                                  .topupWallet(amt);

                              setModalState(() => isSubmitting = false);

                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Top-up request for ₹${amt.toStringAsFixed(0)} submitted! It will be added once approved by admin.'
                                          : 'Failed to submit top-up request. Please try again.',
                                    ),
                                    backgroundColor: success
                                        ? AppTheme.neonGreen
                                        : AppTheme.offlineRed,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final EarningsRecordModel record;
  const _TransactionTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCredit = record.amount > 0;
    const icon = Icons.directions_car;
    const color = AppTheme.neonGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ride Earnings #${record.bookingId.substring(0, 8)}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(record.date.split('T').first, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text('${isCredit ? '+' : ''}₹${record.amount.toStringAsFixed(0)}', style: TextStyle(color: isCredit ? AppTheme.neonGreen : AppTheme.offlineRed, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
