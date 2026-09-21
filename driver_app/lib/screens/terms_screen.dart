import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class DriverTermsScreen extends StatelessWidget {
  const DriverTermsScreen({super.key});

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
          'Partner Terms & Conditions',
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
          // Header Badge
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
                    Icons.description_outlined,
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
                        'Driver Partner Agreement',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 2.4 • Effective: Jan 2026',
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
            'This Partner Agreement governs your relationship with TransGlobe as an independent transportation or logistics service provider.',
            style: GoogleFonts.notoSans(fontSize: 13, color: textSecondary, height: 1.6),
          ),
          const SizedBox(height: 20),

          _buildSection(
            number: '1',
            title: 'Independent Contractor Status',
            content:
                'You acknowledge and agree that your relationship with TransGlobe is solely that of an independent contractor. Nothing in this agreement creates an employment, joint venture, or agency relationship. You retain full autonomy over your hours, driving schedules, and route choices.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '2',
            title: 'Driver Licensing & Vehicle Compliance',
            content:
                'You agree to maintain a valid commercial driving license, active vehicle registration certificate (RC), fitness certificate, comprehensive third-party insurance, and all mandated statutory road permits. You must notify TransGlobe immediately of any license suspension or vehicle changes.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '3',
            title: 'Fares, Commission & Payouts',
            content:
                'Trip fares are calculated automatically by the TransGlobe platform algorithm. Platform commission fees are deducted transparently from total gross earnings. Net driver earnings are credited to your registered bank account or TransGlobe Driver Wallet according to settlement cycles.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '4',
            title: 'Code of Conduct & Zero Tolerance',
            content:
                'Partners must uphold the highest standards of safety, courtesy, and professionalism. Driving under the influence of alcohol or drugs, passenger harassment, fare tampering, asking for off-platform cash rides, or dangerous driving results in immediate and permanent blacklist from the network.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '5',
            title: 'Trip Cancellations & Acceptance Rates',
            content:
                'While you are free to go online or offline at your convenience, frequent cancellations after accepting bookings or refusing rides based on destination discrimination may impact your driver rating and platform incentive eligibility.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '6',
            title: 'Insurance & Road Accidents',
            content:
                'Drivers must maintain active vehicle insurance. TransGlobe may facilitate supplementary group personal accident coverage during active trip hours as per applicable platform safety policies.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          _buildSection(
            number: '7',
            title: 'Termination & Deactivation',
            content:
                'Either party may terminate this agreement at any time. TransGlobe reserves the right to suspend or deactivate partner accounts in cases of fraudulent documentation, safety complaints, low driver ratings, or violation of these terms.',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          const SizedBox(height: 16),
          // Footer
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
                  'Partner Grievance & Compliance Desk',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For legal clarifications or driver disputes, please contact driver-legal@transglobe.com or visit your regional driver support hub.',
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
    required String number,
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonGreen,
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
