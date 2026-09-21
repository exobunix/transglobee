import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = '/privacy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.theme.scaffoldBackgroundColor;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardBgColor,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.emeraldGreen.withValues(alpha: 0.12),
                  AppTheme.forestGreen.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: AppTheme.forestGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Privacy Matters',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Effective Date: January 1, 2026\nLast Updated: March 2026',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'At TransGlobe, we take your personal data privacy seriously. This Privacy Policy outlines what information we collect, how we protect it, and your privacy choices.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Section 1
          _buildSection(
            context,
            icon: Icons.person_search_outlined,
            title: '1. Information We Collect',
            content:
                '• Profile Information: Name, phone number, email address, profile picture.\n'
                '• Location Data: Real-time precise GPS coordinates when booking, during transit, and while tracking rides/logistics.\n'
                '• Transaction Data: Trip history, pickup/drop locations, payment receipts, and wallet balances.\n'
                '• Device Data: Device model, operating system, unique device identifiers, and network information.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 2
          _buildSection(
            context,
            icon: Icons.alt_route_rounded,
            title: '2. How We Use Your Data',
            content:
                '• Providing Services: To match you with nearby drivers, calculate accurate upfront fares, and navigate pickup/drop destinations.\n'
                '• Safety & Security: To monitor trip routes, enable live sharing with trusted contacts, and power in-app SOS emergency assistance.\n'
                '• Communications: To send ride updates, booking confirmations, OTP verifications, and customer support messages.\n'
                '• Platform Optimization: To detect fraud, improve map routing, and refine service reliability.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 3
          _buildSection(
            context,
            icon: Icons.my_location_rounded,
            title: '3. Location Permission & Tracking',
            content:
                'TransGlobe collects location data to enable trip dispatching, live vehicle tracking, and precise pickup points. Location is collected when the app is in use. If enabled by you, background location assists in tracking your trip even when the screen is locked or another app is active.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 4
          _buildSection(
            context,
            icon: Icons.share_outlined,
            title: '4. Information Sharing & Disclosure',
            content:
                '• With Drivers & Delivery Partners: Your pickup and drop coordinates, first name, and phone call bridging (masked numbers where supported).\n'
                '• Service Providers: Secure payment gateway providers, cloud hosting, and SMS notification vendors.\n'
                '• Legal Authorities: When required by applicable law, court subpoenas, or to prevent immediate physical harm.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 5
          _buildSection(
            context,
            icon: Icons.lock_outline_rounded,
            title: '5. Data Security & Storage',
            content:
                'All sensitive data is encrypted in transit via TLS 1.3 and stored securely in certified cloud environments. We implement rigorous access controls, vulnerability audits, and monitoring to protect your information from unauthorized access.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 6
          _buildSection(
            context,
            icon: Icons.manage_accounts_outlined,
            title: '6. Your Rights & Choices',
            content:
                'You have the right to view and update your profile information, manage app permissions (location, notifications), download your ride history, or request full account and data deletion at any time via Settings > Account Actions.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          const SizedBox(height: 16),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Protection & Grievance Contact',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If you have privacy inquiries or wish to contact our Grievance Officer, please email privacy@transglobe.com.',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.forestGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
