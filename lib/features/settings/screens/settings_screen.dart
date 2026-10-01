import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!SupabaseService().isReady) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final authUser = context.read<AuthProvider>().currentUser;
      final user = await SupabaseService().fetchUserProfile(authUser?.id);
      if (mounted) {
        setState(() {
          _userProfile = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProvider.currentUser ?? _userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile hero card loaded from Supabase users table
          _buildProfileCard(isDark, user),
          const SizedBox(height: 8),

          _buildSection(
            context,
            'Account',
            isDark,
            [
              _buildTile(
                context,
                Icons.person_outline,
                'Full Name',
                user?.fullName ?? 'Not set',
                isDark,
              ),
              _buildTile(
                context,
                Icons.fingerprint,
                'User ID',
                user?.displayId ?? 'Not set',
                isDark,
              ),
              _buildTile(
                context,
                Icons.email_outlined,
                'Email',
                user?.email ?? 'Not set',
                isDark,
              ),
            ],
          ),

          _buildSection(
            context,
            'Database & Sync',
            isDark,
            [
              ListTile(
                leading: _iconBox(Icons.cloud_sync_outlined, isDark),
                title: Text(
                  'Cloud Sync',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  SupabaseConfig.isConfigured
                      ? 'Connected'
                      : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: SupabaseConfig.isConfigured
                        ? AppColors.normalStatus
                        : Colors.orange,
                  ),
                ),
                trailing: Icon(
                  SupabaseConfig.isConfigured
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: SupabaseConfig.isConfigured
                      ? AppColors.normalStatus
                      : Colors.orange,
                ),
              ),
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
                'Receive health alerts when limits breach',
                true,
                isDark,
                (val) {},
              ),
              _buildSwitchTile(
                context,
                Icons.dark_mode_outlined,
                'Dark Mode',
                'Easy on the eyes in low light',
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
                  'Hardware pairing & scan instructions', isDark),
              _buildTile(context, Icons.info_outline, 'About Vital Track',
                  'Version 1.0.0 (Production Architecture)', isDark),
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
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Vital Track?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.severeStatus,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, UserProfile? user) {
    final name = user?.fullName ?? (_isLoading ? 'Loading...' : 'Vital Track User');
    final email = user?.email ?? (_isLoading ? 'Loading...' : 'user@vitaltrack.app');

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadUser,
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh, color: Colors.white70),
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
