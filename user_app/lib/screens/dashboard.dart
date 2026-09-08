import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/api_state_providers.dart';
import 'home_screen.dart';
import 'activity_tab.dart';
import 'account_tab.dart';
import 'wallet_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'offers_screen.dart';
import 'support_screen.dart';
import 'logistics_booking/logistics_booking_screen.dart';
import 'bus_booking_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      const ActivityTab(),
      const WalletScreen(),
      AccountTab(
        onTabChange: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: tabs[_currentIndex],
      backgroundColor: context.theme.scaffoldBackgroundColor,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        height: 70,
        surfaceTintColor: Colors.transparent,
        indicatorColor: context.theme.primaryColor.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(Icons.home, color: context.theme.primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.history,
              color: context.theme.primaryColor,
            ),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: context.theme.primaryColor,
            ),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.settings,
              color: context.theme.primaryColor,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const Color transPurple = Color(0xFF8B7DBE);
    final userAsync = ref.watch(fullUserProfileProvider);
    final isLoggedIn = userAsync.value != null;

    return Drawer(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.theme.primaryColor,
                  context.theme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: transPurple.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userAsync.when(
                          data: (user) => Text(
                            user?.name ?? (isLoggedIn ? "User" : "Guest User"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const Text(
                            "Loading...",
                            style: TextStyle(color: Colors.white70),
                          ),
                          error: (_, __) => Text(
                            isLoggedIn ? "User" : "Guest User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          isLoggedIn
                              ? "4.8 ★ Gold Member"
                              : "Welcome to Transglobe",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vehicle Modes (Services)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "OUR SERVICES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _drawerServiceItem(
            context,
            icon: Icons.directions_car_rounded,
            title: "Transglobe (Cabs)",
            subtitle: "Comfortable city rides",
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              // Already on home screen which shows Cabs by default
            },
          ),
          if (isLoggedIn) ...[
            _drawerServiceItem(
              context,
              icon: Icons.local_shipping_rounded,
              title: "Logistics (Trucks)",
              subtitle: "Deliver heavy goods",
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogisticsBookingScreen(),
                  ),
                );
              },
            ),
            _drawerServiceItem(
              context,
              icon: Icons.directions_bus_rounded,
              title: "Shuttle (Buses)",
              subtitle: "Smart daily commute",
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusBookingScreen(),
                  ),
                );
              },
            ),
          ],

          const Divider(height: 32),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerMenuItem(Icons.history, "My Trips", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                }),
                _drawerMenuItem(
                  Icons.account_balance_wallet_outlined,
                  "Wallet",
                  () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),
                _drawerMenuItem(Icons.local_offer_outlined, "Offers", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OffersScreen(),
                    ),
                  );
                }),
                _drawerMenuItem(Icons.settings_outlined, "Settings", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                }),
                _drawerMenuItem(Icons.help_outline, "Support", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportScreen(),
                    ),
                  );
                }),
                const Divider(),
                if (isLoggedIn)
                  _drawerMenuItem(Icons.logout, "Logout", () async {
                    final authService = ref.read(authServiceProvider);
                    final authCtrl = ref.read(authControllerProvider.notifier);
                    // We could get real device ID here, using generic for now
                    await authCtrl.logout(
                      'user-device-id',
                      authService: authService,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }, isDestructive: true)
                else
                  _drawerMenuItem(Icons.login, "Login", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerServiceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: context.colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: context.colors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: context.colors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _drawerMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final defaultColor = context.colors.textPrimary ?? Colors.black87;
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : defaultColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : defaultColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
