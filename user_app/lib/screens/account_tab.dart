import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../providers/api_state_providers.dart';
import '../providers/wallet_provider.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'login_screen.dart';

class AccountTab extends ConsumerWidget {
  final Function(int)? onTabChange;
  const AccountTab({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullProfileAsync = ref.watch(fullUserProfileProvider);
    final authService = ref.watch(authServiceProvider);
    final isLoggedIn = authService.currentUser != null || fullProfileAsync.value != null;
    final wallet = ref.watch(userWalletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Header Section (Profile info, bell, settings)
              fullProfileAsync.when(
                data: (user) {
                  final userName = user?.name ?? "Transglobal User";
                  final userPhone = user?.phoneNumber ?? "No Phone";
                  final avatarUrl = user?.profilePic ?? "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80";

                  return Row(
                    children: [
                      // Profile Image with pen overlay
                      Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF0F4A2C),
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              userPhone,
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Verified badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF19C37D).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF19C37D),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Verified Account",
                                    style: GoogleFonts.notoSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF19C37D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top Action Buttons
                      Row(
                        children: [
                          // _buildCircularTopButton(
                          //   Icons.notifications_none_outlined,
                          //   () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const SupportScreen(),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 8),
                          _buildCircularTopButton(
                            Icons.settings_outlined,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Text("Error loading profile"),
              ),
              const SizedBox(height: 20),

              // 2. Wallet Balance Card (Only shown when logged in)
              if (isLoggedIn) ...[
                _buildWalletCard(context, wallet.balance),
                const SizedBox(height: 12),
              ],

              // // 3. Rewards Card
              // _buildRewardsCard(context),
              // const SizedBox(height: 20),

              // 4. Horizontal Shortcut Icons Grid
              _buildShortcutsRow(context),
              const SizedBox(height: 24),

              // 5. Account & Preferences Section
              _buildPreferencesSection(context),
              const SizedBox(height: 16),

              // // 6. Refer & Earn Card
              // _buildReferEarnCard(context),
              // const SizedBox(height: 12),

              // // 7. TransGlobe Premium Card
              // _buildPremiumCard(context),
              // const SizedBox(height: 24),

              // 8. More Section
              _buildMoreSection(context, ref),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTopButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4A2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A2C).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Wallet Balance",
                    style: GoogleFonts.notoSans(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${balance.toStringAsFixed(2)}",
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => onTabChange?.call(2), // Switches to Wallet Tab
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F4A2C),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "+ Add Money",
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Add money to wallet for faster bookings",
            style: GoogleFonts.notoSans(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3C24),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C3C24).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_outline_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "TransGlobe Rewards",
                    style: GoogleFonts.notoSans(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "🏆 120 Points",
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Earn points with every booking",
            style: GoogleFonts.notoSans(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 4,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 4,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "180 points to unlock ₹250 discount",
                  style: GoogleFonts.notoSans(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C3C24),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "View Rewards",
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShortcutItem(context, Icons.insert_drive_file_outlined, "My Bookings", () => onTabChange?.call(1)),
        _buildShortcutItem(context, Icons.local_shipping_outlined, "My Shipments", () => onTabChange?.call(1)),
        _buildShortcutItem(context, Icons.location_on_outlined, "Saved Places", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        }),
        // _buildShortcutItem(context, Icons.payment_outlined, "Payment Methods", () {
        //   Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsScreen()));
        // }),
      ],
    );
  }

  Widget _buildShortcutItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF19C37D).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF0F4A2C), size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Account & Preferences",
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              _buildMenuRow(
                context,
                Icons.person_outline_rounded,
                "Personal Information",
                () => Navigator.pushNamed(context, '/profile'),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildMenuRow(
                context,
                Icons.location_on_outlined,
                "Address Book",
                () => Navigator.pushNamed(context, '/settings'),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildMenuRow(
                context,
                Icons.notifications_none_outlined,
                "Notification Preferences",
                () => Navigator.pushNamed(context, '/settings'),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildMenuRow(
                context,
                Icons.headset_mic_outlined,
                "Support & Help",
                () => Navigator.pushNamed(context, '/support'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferEarnCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // soft blue background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF1D4ED8), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Refer & Earn",
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Refer your friends and earn exciting rewards",
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF1D4ED8)),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // soft yellow/cream
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TransGlobe Premium",
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Unlock exclusive benefits and offers",
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Upgrade Now",
              style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildMoreSection(BuildContext context, WidgetRef ref) {
    final fullProfileAsync = ref.watch(fullUserProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "More",
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              _buildMenuRow(
                context,
                Icons.info_outline_rounded,
                "About TransGlobe",
                () => Navigator.pushNamed(context, AboutScreen.routeName),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildMenuRow(
                context,
                Icons.description_outlined,
                "Terms & Conditions",
                () => Navigator.pushNamed(context, TermsScreen.routeName),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildMenuRow(
                context,
                Icons.security_outlined,
                "Privacy Policy",
                () => Navigator.pushNamed(context, PrivacyPolicyScreen.routeName),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              fullProfileAsync.value != null
                  ? _buildMenuRow(
                      context,
                      Icons.logout_rounded,
                      "Logout",
                      () async {
                        final authService = ref.read(authServiceProvider);
                        final authCtrl = ref.read(authControllerProvider.notifier);

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Logout"),
                            content: const Text("Are you sure you want to exit?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authCtrl.logout(
                            'user-device-id',
                            authService: authService,
                          );
                        }
                      },
                      isDestructive: true,
                    )
                  : _buildMenuRow(
                      context,
                      Icons.login_rounded,
                      "Login",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      isDestructive: false,
                    ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Text(
            "v1.0.4 • TransGlobe Mobility",
            style: GoogleFonts.notoSans(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMenuRow(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF64748B),
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF334155),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
