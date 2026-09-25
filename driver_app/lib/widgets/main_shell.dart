import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_router.dart';
import '../core/theme.dart';
import '../providers/notification_provider.dart';
import '../services/driver_service.dart';
import '../screens/driver_home_screen.dart';
import '../screens/booking/bookings_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../providers/booking_provider.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../screens/auth/pending_approval_screen.dart';
import 'status_chip.dart';

class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}

final _currentTabProvider = NotifierProvider<CurrentTabNotifier, int>(CurrentTabNotifier.new);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_currentTabProvider);
    final unread = ref.watch(unreadCountProvider);
    final chatUnread = ref.watch(chatUnreadCountProvider);

    final driverProfileAsync = ref.watch(driverProfileProvider);
    
    return driverProfileAsync.when(
      data: (driverProfile) {
        if (driverProfile == null) return _buildProfileNotLoaded(context, ref);
        
        // Show pending screen only if account is explicitly suspended
        if (driverProfile.status == 'suspended') {
          return const PendingApprovalScreen();
        }

        final driverId = driverProfile.id;

        // Connect socket as soon as we have a profile
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(socketServiceProvider).connect(driverId);
        });

        final activeBooking = ref.watch(currentActiveBookingProvider);
        final Widget chatScreenWidget;
        if (activeBooking != null &&
            ['accepted', 'on_the_way', 'arrived', 'ongoing', 'confirmed', 'in_transit'].contains(activeBooking.status.toLowerCase())) {
          chatScreenWidget = ChatScreen(
            receiverId: activeBooking.userId?.isNotEmpty == true ? activeBooking.userId! : activeBooking.id,
            receiverName: activeBooking.userName.trim().isNotEmpty ? activeBooking.userName : 'Customer',
            receiverPhone: activeBooking.userPhone,
            driverId: driverId,
            bookingId: activeBooking.id,
          );
        } else {
          chatScreenWidget = const NoActiveChatPlaceholder();
        }

        final screens = [
          const DriverHomeScreen(),
          const BookingsScreen(),
          const EarningsScreen(),
          chatScreenWidget,
          const ProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: currentTab == 3 
            ? null // Hide main app bar for Chat to show specialized chat header
            : AppBar(
                backgroundColor: AppTheme.darkSurface,
                elevation: 0,
                title: currentTab == 0
                    ? Row(
                        children: [
                          const Text(
                            'Home',
                            style: TextStyle(
                              color: AppTheme.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          StatusChip(
                            status: ref.watch(driverStatusProvider),
                            onTap: () => toggleDriverOnlineStatus(context, ref),
                          ),
                        ],
                      )
                    : Text(_getTitle(currentTab)),
                centerTitle: currentTab != 0,
                actions: [
                  // Manual Sync / Alarm Button
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync_problem_outlined, color: AppTheme.neonGreen),
                        tooltip: 'Sync Bookings', 
                        onPressed: () {
                          ref.read(bookingProvider.notifier).fetchBookings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshing bookings...'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.neonGreen, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Badge(
                      label: Text('$unread'),
                      isLabelVisible: unread > 0,
                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
          body: IndexedStack(
            index: currentTab,
            children: screens,
          ),
          bottomNavigationBar: _buildNavBar(currentTab, chatUnread, ref),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRouter.auth, (r) => false);
                }
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRouter.auth, (r) => false);
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.offlineRed, size: 60),
                const SizedBox(height: 16),
                Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverProfileProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: AppTheme.darkBg),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(int currentTab, int unread, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: AppTheme.darkDivider.withValues(alpha: 0.5), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Home', index: 0, currentIndex: currentTab, onTap: (i) => ref.read(_currentTabProvider.notifier).set(i)),
              _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Bookings', index: 1, currentIndex: currentTab, onTap: (i) => ref.read(_currentTabProvider.notifier).set(i)),
              _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Earnings', index: 2, currentIndex: currentTab, onTap: (i) => ref.read(_currentTabProvider.notifier).set(i)),
              _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat', index: 3, currentIndex: currentTab, badge: unread, onTap: (i) => ref.read(_currentTabProvider.notifier).set(i)),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 4, currentIndex: currentTab, onTap: (i) => ref.read(_currentTabProvider.notifier).set(i)),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'Bookings';
      case 2: return 'Earnings';
      case 3: return 'Chat';
      case 4: return 'Profile';
      default: return 'RideShare';
    }
  }



  Widget _buildProfileNotLoaded(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  color: AppTheme.neonGreen, size: 72),
              const SizedBox(height: 24),
              const Text('Profile Not Loaded',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Unable to fetch your driver profile.\nPlease check your internet connection and try again.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.invalidate(driverProfileProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRouter.auth, (r) => false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final int badge;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive ? AppTheme.neonGreen : AppTheme.darkTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isActive ? activeIcon : icon, color: color, size: 22),
                    if (badge > 0)
                      Positioned(
                        top: -4, right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: AppTheme.offlineRed, shape: BoxShape.circle, border: Border.all(color: AppTheme.darkSurface, width: 1.5)),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(color: color, fontSize: isActive ? 10 : 9, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400),
                child: Text(label),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: isActive ? 20 : 0,
                decoration: BoxDecoration(color: AppTheme.neonGreen, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoActiveChatPlaceholder extends StatelessWidget {
  const NoActiveChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text(
          'Live Chat',
          style: TextStyle(
            color: AppTheme.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.neonGreen.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 44,
                  color: AppTheme.neonGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Active Chat',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Once a ride or delivery booking is confirmed, real-time chat with the customer will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

