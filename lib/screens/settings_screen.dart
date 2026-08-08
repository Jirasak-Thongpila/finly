import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../utils/constants.dart';

/// Settings: profile card (refreshed from `GET /api/auth/me`) and logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;

  Future<void> _refreshProfile() async {
    setState(() => _saving = true);
    try {
      await context.read<SessionManager>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile refreshed'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<SessionManager>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Member since',
                  subtitle: _memberSince(user),
                  onTap: null,
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh profile',
                  subtitle: 'Sync your account details from the server',
                  onTap: _saving ? null : _refreshProfile,
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'Sign out from this device',
                  iconColor: AppColors.expenseRed,
                  titleColor: AppColors.expenseRed,
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Finly',
                  subtitle: 'Personal finance manager · v1.0.0',
                  onTap: null,
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.cloud_outlined,
                  title: 'API',
                  subtitle: AppConstants.apiBaseUrl,
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _memberSince(User? user) {
    final raw = user?.createdAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw).toLocal();
      return DateFormat('d MMMM yyyy').format(d);
    } catch (_) {
      return '—';
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final User? user;

  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              user?.initials ?? 'U',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor = AppColors.textPrimary,
    this.titleColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary)
          : null,
      onTap: onTap,
    );
  }
}