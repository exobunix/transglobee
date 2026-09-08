import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../core/network/api_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationControllerProvider);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationState.status == ApiStatus.initial) {
        ref.read(notificationControllerProvider.notifier).getNotifications();
      }
    });

    final notifications = notificationState.data?.notifications ?? [];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {}, // Mark all read - placeholder for now
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.neonGreen, fontSize: 13)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none, size: 56, color: AppTheme.darkDivider),
              SizedBox(height: 12),
              Text('No notifications', style: TextStyle(color: AppTheme.darkTextSecondary)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {}, // Placeholder
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppTheme.offlineRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline, color: AppTheme.offlineRed),
                  ),
                  child: GestureDetector(
                    onTap: () {}, // Placeholder
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppTheme.darkCard : AppTheme.darkCardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: n.isRead ? AppTheme.darkDivider.withValues(alpha: 0.3) : _catColor(n.category).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _catColor(n.category).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_catIcon(n.category), color: _catColor(n.category), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(n.title, style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13))),
                                    if (!n.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: _catColor(n.category), shape: BoxShape.circle)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(n.body, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_formatTime(n.time), style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _catColor(String cat) {
    return switch(cat) { 
      'booking' => AppTheme.neonGreen, 
      'earning' => AppTheme.earningsAmber, 
      'chat' => AppTheme.cabBlue,
      _ => AppTheme.cabBlue 
    };
  }

  IconData _catIcon(String cat) {
    return switch(cat) { 
      'booking' => Icons.directions_car, 
      'earning' => Icons.account_balance_wallet, 
      'chat' => Icons.chat_bubble_outline,
      _ => Icons.info_outline 
    };
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
