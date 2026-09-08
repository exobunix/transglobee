import 'package:flutter/material.dart';
import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // App Logo & Version
          Container(
            padding: const EdgeInsets.all(40),
            color: context.theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_taxi,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transglobal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Up to date',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          Container(
            color: context.theme.cardColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Transglobal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Transglobal is your trusted ride-hailing partner, connecting you with safe and reliable transportation across the city. Whether you need a quick ride to work, a comfortable trip to the airport, or efficient logistics solutions, we\'ve got you covered.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Links Section
          Container(
            color: context.theme.cardColor,
            child: Column(
              children: [
                _buildLinkTile(
                  context,
                  Icons.description_outlined,
                  'Terms of Service',
                  Colors.blue,
                ),
                Divider(
                  height: 1,
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
                _buildLinkTile(
                  context,
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  Colors.green,
                ),
                Divider(
                  height: 1,
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
                _buildLinkTile(
                  context,
                  Icons.gavel_outlined,
                  'Licenses',
                  Colors.orange,
                ),
                Divider(
                  height: 1,
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
                _buildLinkTile(
                  context,
                  Icons.language,
                  'Visit Website',
                  Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Social Links
          Container(
            color: context.theme.cardColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow Us',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(Icons.facebook, Colors.blue[700]!),
                    _buildSocialButton(Icons.camera_alt, Colors.pink),
                    _buildSocialButton(Icons.alternate_email, Colors.lightBlue),
                    _buildSocialButton(Icons.play_circle_filled, Colors.red),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Developer Info
          Container(
            color: AppTheme.backgroundColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code,
                      color: context.colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Made with ❤️ in India',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 Transglobal. All rights reserved.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
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

  Widget _buildLinkTile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(color: context.colors.textPrimary)),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: context.colors.textSecondary,
      ),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening $title...')));
      },
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
