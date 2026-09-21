import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_router.dart';

class DriverAboutScreen extends StatelessWidget {
  const DriverAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA);
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkDivider : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About TransGlobe Partner',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Logo & Version
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.neonGreen, Color(0xFF00B0FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonGreen.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.drive_eta_rounded,
                      color: Colors.black87,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'TransGlobe Driver Partner',
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Driver Edition v1.0.0+4',
                  style: GoogleFonts.notoSans(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: AppTheme.neonGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Partner Network',
                        style: GoogleFonts.lexend(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empowering Mobility & Logistics Partners',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'TransGlobe Partner app enables drivers and fleet owners to earn on their own terms. Whether driving cabs, operating transport freight, or navigating intercity buses, our platform provides real-time demand matching, instant fare estimates, daily payout settlements, and 24/7 on-road emergency assistance.',
                  style: GoogleFonts.notoSans(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Links
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildLinkTile(
                  context,
                  Icons.description_outlined,
                  'Partner Terms & Conditions',
                  AppTheme.cabBlue,
                  onTap: () => Navigator.pushNamed(context, AppRouter.terms),
                  textPrimary: textPrimary,
                ),
                Divider(height: 1, color: borderColor),
                _buildLinkTile(
                  context,
                  Icons.policy_outlined,
                  'Driver Privacy Policy',
                  AppTheme.neonGreen,
                  onTap: () => Navigator.pushNamed(context, AppRouter.privacy),
                  textPrimary: textPrimary,
                ),
                Divider(height: 1, color: borderColor),
                _buildLinkTile(
                  context,
                  Icons.headset_mic_outlined,
                  'Partner Support & Helpdesk',
                  AppTheme.earningsAmber,
                  onTap: () => Navigator.pushNamed(context, AppRouter.support),
                  textPrimary: textPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              '© 2026 Transglobal Technologies Pvt. Ltd.\nMade with pride in India',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor, {
    required VoidCallback onTap,
    required Color textPrimary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
