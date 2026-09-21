import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class DriverPrivacyPolicyScreen extends StatelessWidget {
  const DriverPrivacyPolicyScreen({super.key});

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
          'Driver Privacy Policy',
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonGreen.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: AppTheme.neonGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Data Protection',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Updated: March 2026',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: textSecondary,
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
            'This Privacy Policy explains how TransGlobe collects, uses, and protects driver-partner information, including telematics, real-time geolocation, and payout details.',
            style: GoogleFonts.notoSans(fontSize: 13, color: textSecondary, height: 1.6),
          ),
          const SizedBox(height: 20),

          _buildSection(
            icon: Icons.badge_outlined,
            title: '1. Information We Collect from Drivers',
            content:
                '• Verification Documents: Driver’s license, national identity (Aadhaar/PAN), background verification checks, vehicle registration, and permits.\n'
                '• Telematics & Live Location: Continuous GPS coordinates while Online or engaged in trips to dispatch rides and ensure passenger safety.\n'
                '• Financial Data: Bank account details, IFSC code, payout logs, and tax identification for direct earnings transfers.\n'
                '• Driving Metrics: Accelerometer data, speed telemetry, completion rates, and rider ratings.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            icon: Icons.gps_fixed_rounded,
            title: '2. Real-Time & Background Location',
            content:
                'To match you with nearby pickups and display your arrival ETA to riders, TransGlobe tracks your precise location in foreground and background while your status is set to ONLINE or ON TRIP. Location tracking stops when you go OFFLINE.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            icon: Icons.share_location_outlined,
            title: '3. Data Sharing with Riders & Fleet Operators',
            content:
                'When you accept a booking, your first name, profile picture, vehicle model, vehicle plate number, and real-time map location are shared with the passenger until the trip concludes. Direct personal phone numbers are masked through platform call routing.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            icon: Icons.shield_outlined,
            title: '4. Security & Statutory Compliance',
            content:
                'Driver documentation is encrypted and securely stored. We comply with regulatory audits and traffic safety compliance guidelines. Data is never sold or shared with unauthorized commercial entities.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            icon: Icons.account_circle_outlined,
            title: '5. Accessing & Updating Your Information',
            content:
                'You can review and update vehicle details, bank account credentials, and contact details directly within the Profile & Wallet sections of the app.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Privacy Office',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For inquiries regarding driver data retention or telematics policies, contact driver-privacy@transglobe.com.',
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.neonGreen, size: 18),
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
