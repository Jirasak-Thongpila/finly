import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../utils/constants.dart';
import '../widgets/skeleton_loaders.dart';

/// หน้าโปรไฟล์ผู้ใช้งาน (SettingsScreen / ProfileScreen) ดีไซน์ใหม่:
/// - การ์ดฮีโร่สีเข้ม Deep Charcoal พร้อมวงแหวนสีเขียว Lime ล้อมรอบอวตาร
/// - การ์ดสรุปข้อมูลสมาชิกและสถานะบัญชี
/// - เมนูการจัดการบัญชี ภาษา การเชื่อมต่อเซิร์ฟเวอร์ และการตั้งค่าระบบ
/// - ปุ่มออกจากระบบสีแดงอ่อนปลอดภัย
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const SettingsScreen({super.key, this.onMenuTap});

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
        SnackBar(
          content: const Text('อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว'),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: AppColors.expenseRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.expenseRed, size: 24),
            SizedBox(width: 10),
            Text(
              'ออกจากระบบ?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        content: const Text(
          'คุณต้องการออกจากระบบจากอุปกรณ์นี้ใช่หรือไม่?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SessionManager>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.subject_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          tooltip: 'เปิดเมนู',
          onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text(
          'โปรไฟล์ & ตั้งค่า',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.limeAccentDark,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
            ),
            tooltip: 'อัปเดตข้อมูล',
            onPressed: _saving ? null : _refreshProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? const ProfileSkeletonView()
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 8, AppConstants.pagePadding, 40,
              ),
              children: [
                // 1. การ์ดฮีโร่โปรไฟล์ (Profile Hero Card)
                _ProfileHeroCard(user: user),
                const SizedBox(height: 16),

                // 2. การ์ดคู่แสดงสรุปข้อมูลสมาชิก & สถานะบัญชี
                Row(
                  children: [
                    Expanded(
                      child: _InfoMiniCard(
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF4D7C0F),
                        iconBgColor: AppColors.limeAccent.withValues(alpha: 0.2),
                        label: 'วันที่สมัครสมาชิก',
                        value: _memberSince(user),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoMiniCard(
                        icon: Icons.verified_user_rounded,
                        iconColor: const Color(0xFF16A34A),
                        iconBgColor: const Color(0xFFDCFCE7),
                        label: 'สถานะบัญชี',
                        value: 'ใช้งานปกติ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. ส่วนการจัดการบัญชี (Account Settings)
                const _SectionTitle(title: 'การจัดการบัญชี'),
                const SizedBox(height: 12),
                _ProfileSettingTile(
                  icon: Icons.sync_rounded,
                  iconBgColor: AppColors.limeAccent.withValues(alpha: 0.18),
                  iconColor: const Color(0xFF4D7C0F),
                  title: 'ซิงค์ข้อมูลโปรไฟล์',
                  subtitle: 'อัปเดตข้อมูลบัญชีล่าสุดจากเซิร์ฟเวอร์',
                  onTap: _saving ? null : _refreshProfile,
                ),
                const SizedBox(height: 10),
                _ProfileSettingTile(
                  icon: Icons.language_rounded,
                  iconBgColor: const Color(0xFFF3E8FF),
                  iconColor: AppColors.purpleBadgeText,
                  title: 'ภาษาของแอปพลิเคชัน',
                  subtitle: 'ภาษาไทย (Thai)',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TH',
                      style: TextStyle(
                        color: Color(0xFF3F6212),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('แอปพลิเคชันเปิดใช้งานภาษาไทยเป็นภาษาหลัก'),
                        backgroundColor: const Color(0xFF111827),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 4. เกี่ยวกับแอปพลิเคชัน (About Finly)
                const _SectionTitle(title: 'เกี่ยวกับ Finly'),
                const SizedBox(height: 12),
                const _ProfileSettingTile(
                  icon: Icons.info_outline_rounded,
                  iconBgColor: Color(0xFFEFF6FF),
                  iconColor: Color(0xFF2563EB),
                  title: 'เวอร์ชันแอปพลิเคชัน',
                  subtitle: 'Finly Personal Finance',
                  trailing: Text(
                    'v${AppConstants.appVersion}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 10),
                _ProfileSettingTile(
                  icon: Icons.cloud_done_rounded,
                  iconBgColor: const Color(0xFFDCFCE7),
                  iconColor: AppColors.income,
                  title: 'สถานะการเชื่อมต่อ API',
                  subtitle: 'เชื่อมต่อเซิร์ฟเวอร์เสถียร',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 28),

                // 5. ปุ่มออกจากระบบ (Logout Card)
                _LogoutButton(onTap: _logout),
              ],
            ),
    );
  }

  String _memberSince(User? user) {
    final raw = user?.createdAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw).toLocal();
      const thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      return '${d.day} ${thaiMonths[d.month - 1]} ${d.year}';
    } catch (_) {
      return '—';
    }
  }
}

// ============================================================================
// PROFILE HERO CARD: การ์ดโปรไฟล์หลักสี Obsidian Dark พร้อม Radial Lime Glow
// ============================================================================
class _ProfileHeroCard extends StatelessWidget {
  final User? user;

  const _ProfileHeroCard({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'ผู้ใช้งาน Finly';
    final email = user?.email ?? 'user@finly.app';
    final initials = user?.initials ?? 'U';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Obsidian dark background
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient lime glow centered
          Positioned(
            top: -25,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.limeAccent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // อวตารตัวอักษรย่อ พร้อมวงแหวนสีเขียว Lime Gradient
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.limeAccent,
                          AppColors.limeAccentDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ชื่อผู้ใช้
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),

                // อีเมล
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),

                // ป้ายสมาชิก Verified สไตล์ Lime Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.limeAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.limeAccent,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'สมาชิก Finly Verified',
                          style: TextStyle(
                            color: AppColors.limeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
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
// INFO MINI CARD: การ์ดเล็กสรุปวันที่สมาชิก & สถานะบัญชี
// ============================================================================
class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;

  const _InfoMiniCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
// SECTION TITLE: หัวข้อกลุ่มการตั้งค่า พร้อมแถบสี Lime
// ============================================================================
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.limeAccentDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROFILE SETTING TILE: แถบรายการเมนูการตั้งค่าแบบการ์ดทรงมน
// ============================================================================
class _ProfileSettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileSettingTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing!,
                  if (onTap != null) const SizedBox(width: 6),
                ],
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
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
// LOGOUT BUTTON: ปุ่มออกจากระบบสีแดงอ่อนทรงมน
// ============================================================================
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.expenseRed,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    color: AppColors.expenseRed,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}