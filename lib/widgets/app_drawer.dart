import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/drawer_actions.dart';

/// Redesigned AppDrawer - Lime Accent Fintech Theme (Safe Version)
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
      backgroundColor: const Color(0xFFF8FAF8), // Soft Light Greenish-Gray
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 1. Profile Header with Lime Gradient Glow & Glass Badge
              _DrawerProfileHeader(user: user),
              const SizedBox(height: 20),

              // 2. Menu Items Container
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.grid_view_rounded,
                      label: 'หน้าหลัก',
                      badgeColor: AppColors.limeAccent,
                      iconColor: const Color(0xFF1E293B),
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(DrawerAction.home);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DrawerMenuItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'ประวัติรายการ',
                      badgeColor: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(DrawerAction.transactions);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DrawerMenuItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'เพิ่มรายรับ',
                      badgeColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      onTap: () {
                        Navigator.pop(context);
                        onAddTransaction('income');
                      },
                    ),
                    const SizedBox(height: 10),
                    _DrawerMenuItem(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'เพิ่มรายจ่าย',
                      badgeColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      onTap: () {
                        Navigator.pop(context);
                        onAddTransaction('expense');
                      },
                    ),
                    const SizedBox(height: 10),
                    _DrawerMenuItem(
                      icon: Icons.insights_rounded,
                      label: 'สถิติการเงิน',
                      badgeColor: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(DrawerAction.statistics);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DrawerMenuItem(
                      icon: Icons.tune_rounded,
                      label: 'ตั้งค่า',
                      badgeColor: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF64748B),
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(DrawerAction.settings);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Logout Button Card
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
// PROFILE HEADER: การ์ดโปรไฟล์พื้นหลังเข้ม ตัดกับวงแหวน Lime Green
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18221B), Color(0xFF0F1713)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18221B).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar พร้อม Lime Glow Ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.limeAccent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.limeAccent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0F1713),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.limeAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tag Badge สี Lime Accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.limeAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.limeAccent, size: 13),
                SizedBox(width: 6),
                Text(
                  'Finly Member',
                  style: TextStyle(
                    color: AppColors.limeAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
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
// DRAWER MENU ITEM: การ์ดเมนูทรงมน
// ============================================================================
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color badgeColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.badgeColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOGOUT CARD: การ์ดปุ่มออกจากระบบ
// ============================================================================
class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE11D48),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFE11D48),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
