import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/app_router.dart';

class DriverSupportScreen extends StatelessWidget {
  const DriverSupportScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=TransGlobe Driver Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
          'Driver Support & Help',
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
          // Emergency 24/7 Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '24/7 On-Road Emergency SOS',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Immediate police, ambulance, or safety response for active on-trip emergencies.',
                  style: GoogleFonts.notoSans(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _makeCall('112'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[800],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text('Dial Emergency (112)', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Quick Support Channels',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Action cards
          _buildActionCard(
            context,
            icon: Icons.phone_in_talk_outlined,
            iconColor: AppTheme.neonGreen,
            title: 'Partner Dedicated Helpline',
            subtitle: '1800-890-7890 (Toll-Free, 24x7)',
            onTap: () => _makeCall('18008907890'),
            cardBg: cardBg,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildActionCard(
            context,
            icon: Icons.mail_outline_rounded,
            iconColor: AppTheme.cabBlue,
            title: 'Email Driver Operations',
            subtitle: 'driver-support@transglobe.com',
            onTap: () => _sendEmail('driver-support@transglobe.com'),
            cardBg: cardBg,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildActionCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppTheme.earningsAmber,
            title: 'Payout & Wallet Issues',
            subtitle: 'Raise a ticket for delayed earnings or adjustments',
            onTap: () => Navigator.pushNamed(context, AppRouter.wallet),
            cardBg: cardBg,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          const SizedBox(height: 24),
          Text(
            'Legal & Compliance',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppTheme.cabBlue),
                  title: Text('Terms & Conditions', style: GoogleFonts.lexend(fontSize: 14, color: textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, AppRouter.terms),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Icon(Icons.policy_outlined, color: AppTheme.neonGreen),
                  title: Text('Privacy Policy', style: GoogleFonts.lexend(fontSize: 14, color: textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, AppRouter.privacy),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.earningsAmber),
                  title: Text('About TransGlobe Partner', style: GoogleFonts.lexend(fontSize: 14, color: textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, AppRouter.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}
