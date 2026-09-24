import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile hero card
          _buildProfileCard(isDark),
          const SizedBox(height: 8),

          _buildSection(
            context,
            'Account',
            isDark,
            [
              _buildTile(context, Icons.person_outline, 'Profile Information',
                  'Update your personal data', isDark),
              _buildTile(context, Icons.security_outlined, 'Privacy & Security',
                  'Manage passwords & access', isDark),
            ],
          ),

          _buildSection(
            context,
            'Preferences',
            isDark,
            [
              _buildSwitchTile(
                context,
                Icons.notifications_outlined,
                'Push Notifications',
                'Receive health alerts',
                true,
                isDark,
                (val) {},
              ),
              _buildSwitchTile(
                context,
                Icons.dark_mode_outlined,
                'Dark Mode',
                'Easy on the eyes at night',
                themeProvider.isDarkMode,
                isDark,
                (val) => themeProvider.toggleTheme(val),
              ),
            ],
          ),

          _buildSection(
            context,
            'Support',
            isDark,
            [
              _buildTile(context, Icons.help_outline, 'Help Center',
                  'FAQs and user guide', isDark),
              _buildTile(context, Icons.info_outline, 'About Vital Track',
                  'Version 1.0.0', isDark),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[300]!),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A0A16), const Color(0xFF3D1020)]
              : [AppColors.primary, const Color(0xFFB5274B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withAlpha(30),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 4),
              Text('user@vitaltrack.app',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, bool isDark, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : AppColors.primary.withAlpha(150),
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(60)
                    : AppColors.accent.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title,
      String subtitle, bool isDark) {
    return ListTile(
      leading: _iconBox(icon, isDark),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
      trailing: Icon(Icons.chevron_right,
          color: isDark ? Colors.grey[600] : Colors.grey[400]),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    bool isDark,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: _iconBox(icon, isDark),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
      value: value,
      activeColor: AppColors.primary,
      activeTrackColor: AppColors.accent.withAlpha(100),
      onChanged: onChanged,
    );
  }

  Widget _iconBox(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary.withAlpha(40) : AppColors.accent.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon,
          color: isDark ? AppColors.accent : AppColors.primary, size: 20),
    );
  }
}
