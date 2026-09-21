import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';

  const TermsScreen({super.key});

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
          'Terms & Conditions',
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
                    Icons.description_outlined,
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
                        'TransGlobe User Agreement',
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
            'Please read these Terms and Conditions carefully before using the TransGlobe platform, mobile applications, and mobility/logistics services.',
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
            number: '1',
            title: 'Acceptance of Terms',
            content:
                'By downloading, accessing, or using the TransGlobe application, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 2
          _buildSection(
            context,
            number: '2',
            title: 'User Accounts & Verification',
            content:
                'You must register with a valid mobile phone number and verify your identity via OTP to access our services. You are responsible for all activities occurring under your account. You agree to provide accurate and updated information at all times.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 3
          _buildSection(
            context,
            number: '3',
            title: 'Ride-Hailing & Mobility Services',
            content:
                'TransGlobe acts as a technology platform connecting riders with independent third-party transport operators. We do not own vehicles or operate direct transport services. Fares are calculated based on base fare, distance, estimated travel time, and dynamic demand pricing.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 4
          _buildSection(
            context,
            number: '4',
            title: 'Freight & Logistics Bookings',
            content:
                'Users sending packages or freight must ensure that shipments do not contain hazardous, illegal, inflammable, or restricted items. Senders are responsible for proper packaging. TransGlobe reserves the right to refuse transport of undeclared or prohibited goods.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 5
          _buildSection(
            context,
            number: '5',
            title: 'Cancellations & Refund Policy',
            content:
                'Cancellation fees may apply if a ride or shipment is cancelled after a driver has been dispatched or after a designated waiting period. Refunds for valid claims or failed bookings will be credited back to the original payment method or TransGlobe Wallet within 5-7 business days.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 6
          _buildSection(
            context,
            number: '6',
            title: 'Safety & Code of Conduct',
            content:
                'We maintain a zero-tolerance policy against discrimination, harassment, abusive language, physical violence, and vehicle damage. Violation of our safety guidelines may result in immediate suspension or permanent termination of account privileges.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 7
          _buildSection(
            context,
            number: '7',
            title: 'Limitation of Liability',
            content:
                'To the maximum extent permitted by law, TransGlobe shall not be liable for indirect, incidental, special, exemplary, punitive, or consequential damages, including personal injury or property damage arising out of any trip or logistics transaction.',
            cardBg: cardBgColor,
            border: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Section 8
          _buildSection(
            context,
            number: '8',
            title: 'Governing Law & Disputes',
            content:
                'These Terms shall be governed by and construed in accordance with the laws of India. Any disputes arising in connection with these Terms shall be subject to the exclusive jurisdiction of the competent courts in India.',
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
                  'Questions regarding our Terms?',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reach out to our legal and support team at support@transglobe.com or via the in-app Help & Support section.',
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
    required String number,
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestGreen,
                  ),
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
