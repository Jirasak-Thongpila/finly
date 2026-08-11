import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/drawer_actions.dart';

/// Redesigned AppDrawer matching the modern fintech design system:
/// - Dark Charcoal Header with Lime Green Avatar Ring and Finly Tag.
/// - Rounded floating menu items with colored icon badges and chevrons.
/// - Soft red bottom logout card.
class AppDrawer extends StatelessWidget {
  final User? user;
  final ValueChanged<DrawerAction> onNavigate;
  final ValueChanged<String> onAddTransaction;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.onAddTransaction,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 1. ส่วนหัวโปรไฟล์ดีไซน์การ์ดสีเข้ม (Dark Charcoal Profile Card)
              _DrawerProfileHeader(user: user),
              const SizedBox(height: 16),

              // 2. รายการเมนูหลัก (Modern Floating Menu Items)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.home_rounded,
                      label: 'หน้าหลัก',
                      iconBgColor: AppColors.limeAccent,
                      iconColor: AppColors.textPrimary,
                      onTap: () => onNavigate(DrawerAction.home),
                    ),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'ประวัติรายการ',
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      onTap: () => onNavigate(DrawerAction.transactions),
                    ),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'เพิ่มรายรับ',
                      iconBgColor: const Color(0xFFDCFCE7),
                      iconColor: AppColors.income,
                      onTap: () => onAddTransaction('income'),
                    ),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'เพิ่มรายจ่าย',
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: AppColors.expenseRed,
                      onTap: () => onAddTransaction('expense'),
                    ),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'สถิติการเงิน',
                      iconBgColor: const Color(0xFFF3E8FF),
                      iconColor: AppColors.purpleBadgeText,
                      onTap: () => onNavigate(DrawerAction.statistics),
                    ),
                    const SizedBox(height: 8),
                    _DrawerMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'ตั้งค่า',
                      iconBgColor: const Color(0xFFF3F4F6),
                      iconColor: AppColors.textPrimary,
                      onTap: () => onNavigate(DrawerAction.settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. ปุ่มออกจากระบบดีไซน์การ์ดสีแดงอ่อน (Logout Button)
              _LogoutCard(
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE HEADER: การ์ดสีเข้ม + อวตารขอบสีเขียว Lime + ป้าย Finly
// ============================================================================
class _DrawerProfileHeader extends StatelessWidget {
  final User? user;

  const _DrawerProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Finly User';
    final email = user?.email ?? 'user@finly.app';
    final initials = user?.initials ?? 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16251C), // Deep Charcoal Dark
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with Lime Green Ring
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: AppColors.limeAccent,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF16251C),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Finly Member Tag Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.limeAccent,
                  size: 13,
                ),
                SizedBox(width: 6),
                Text(
                  'Finly Member',
                  style: TextStyle(
                    color: AppColors.limeAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRAWER MENU ITEM: การ์ดเมนูทรงมนพร้อมไอคอนและลูกศร
// ============================================================================
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOGOUT CARD: การ์ดปุ่มออกจากระบบสีแดงอ่อน
// ============================================================================
class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF2F2), // Soft red background
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.expenseRed,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    color: AppColors.expenseRed,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.expenseRed,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}