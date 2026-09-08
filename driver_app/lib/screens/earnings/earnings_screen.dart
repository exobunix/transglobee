import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/network/api_state.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../features/driver/models/response/earnings_pagination_model.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});
  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _period = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEarnings());
  }

  void _loadEarnings() {
    ref.read(earningsControllerProvider.notifier).getDriverEarnings();
  }

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
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsControllerProvider);
    final earnings = earningsState.data;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: RefreshIndicator(
        color: AppTheme.earningsAmber,
        onRefresh: () async => _loadEarnings(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.darkSurface,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.darkTextSecondary),
                  onPressed: _loadEarnings,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.earningsAmber.withValues(alpha: 0.2),
                        AppTheme.darkSurface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earnings',
                            style: TextStyle(
                              color: AppTheme.darkTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (earningsState.status == ApiStatus.loading &&
                              earnings == null)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.earningsAmber,
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryCard(
                                  'Today',
                                  _formatCurrency(earnings?.todayEarnings ?? 0),
                                  AppTheme.neonGreen,
                                ),
                                _buildSummaryCard(
                                  'Week',
                                  _formatCurrency(earnings?.weeklyEarnings ?? 0),
                                  AppTheme.cabBlue,
                                ),
                                _buildSummaryCard(
                                  'Month',
                                  _formatCurrency(earnings?.monthlyEarnings ?? 0),
                                  AppTheme.earningsAmber,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (earningsState.status == ApiStatus.error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    earningsState.message ?? 'Failed to load earnings',
                    style: const TextStyle(color: AppTheme.offlineRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(earnings),
                    const SizedBox(height: 20),
                    _buildBarChart(earnings),
                    const SizedBox(height: 20),
                    _buildIncentiveCard(earnings),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Trips',
                      style: TextStyle(
                        color: AppTheme.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final trips = earnings?.records ?? [];
                  if (trips.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No completed trips yet',
                          style: TextStyle(color: AppTheme.darkTextSecondary),
                        ),
                      ),
                    );
                  }
                  return _buildTripRow(trips[i]);
                },
                childCount: (earnings?.records.isEmpty ?? true)
                    ? 1
                    : (earnings!.records.length > 6 ? 6 : earnings.records.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(EarningsPaginationModel? earnings) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Today', 'Week', 'Month'].map((p) {
          final sel = _period == p;
          final amount = earnings?.earningsForPeriod(p) ?? 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.earningsGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      p,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: sel ? Colors.white : AppTheme.darkTextSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (sel) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(amount),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(EarningsPaginationModel? earnings) {
    final breakdown = earnings?.dailyBreakdown ?? [];
    final weekTotal = earnings?.weeklyEarnings ?? 0;
    final maxEarnings = breakdown.isEmpty
        ? 1.0
        : breakdown.map((d) => d.earnings).reduce((a, b) => a > b ? a : b);
    final chartMax = maxEarnings > 0 ? maxEarnings : 1.0;
    final todayLabel = _weekdayLabel(DateTime.now().weekday % 7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Overview',
                style: TextStyle(
                  color: AppTheme.darkTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatCurrency(weekTotal),
                style: const TextStyle(
                  color: AppTheme.earningsAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: breakdown.isEmpty
                ? const Center(
                    child: Text(
                      'No earnings this week',
                      style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: breakdown.map((day) {
                      final ratio = day.earnings / chartMax;
                      final isToday = day.label == todayLabel;
                      return Expanded(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 70 * v,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isToday
                                          ? [
                                              AppTheme.earningsAmber,
                                              AppTheme.truckOrange,
                                            ]
                                          : [
                                              AppTheme.earningsAmber
                                                  .withValues(alpha: 0.5),
                                              AppTheme.earningsAmber
                                                  .withValues(alpha: 0.2),
                                            ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  day.label,
                                  style: TextStyle(
                                    color: isToday
                                        ? AppTheme.earningsAmber
                                        : AppTheme.darkTextSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'];
    return labels[weekday];
  }

  Widget _buildIncentiveCard(EarningsPaginationModel? earnings) {
    final target = earnings?.bonusTarget ?? 15;
    final completed = earnings?.weeklyCompletedRides ?? 0;
    final bonus = earnings?.bonusAmount ?? 1000;
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - completed).clamp(0, target);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.busPurple.withValues(alpha: 0.15),
            AppTheme.cabBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.busPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.earningsAmber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete $target rides, earn ₹${bonus.toStringAsFixed(0)} bonus!',
                  style: const TextStyle(
                    color: AppTheme.darkTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.darkDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.earningsAmber),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed of $target rides completed',
                style: const TextStyle(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                remaining > 0 ? '$remaining more to go!' : 'Bonus unlocked!',
                style: const TextStyle(
                  color: AppTheme.earningsAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripRow(EarningsRecordModel trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.earningsAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppTheme.earningsAmber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.userName,
                    style: const TextStyle(
                      color: AppTheme.darkTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${trip.tripDistance.toStringAsFixed(1)} km • ${trip.vehicleType.toUpperCase()}',
                    style: const TextStyle(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+₹${trip.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
