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
        const SnackBar(
          content: Text('อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ออกจากระบบ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        ),
        content: const Text('คุณต้องการออกจากระบบจากอุปกรณ์นี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 40),
            ),
            child: const Text('ออกจากระบบ'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.subject_rounded, color: AppColors.textPrimary),
          tooltip: 'เปิดเมนู',
          onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'อัปเดตข้อมูล',
            onPressed: _saving ? null : _refreshProfile,
          ),
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
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  label: 'วันที่สมัครสมาชิก',
                  value: _memberSince(user),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoMiniCard(
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.income,
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
          const SizedBox(height: 10),
          _ProfileSettingTile(
            icon: Icons.sync_rounded,
            iconBgColor: const Color(0xFFF3F4F6),
            iconColor: AppColors.textPrimary,
            title: 'ซิงค์ข้อมูลโปรไฟล์',
            subtitle: 'อัปเดตข้อมูลบัญชีล่าสุดจากเซิร์ฟเวอร์',
            onTap: _saving ? null : _refreshProfile,
          ),
          const SizedBox(height: 8),
          _ProfileSettingTile(
            icon: Icons.language_rounded,
            iconBgColor: const Color(0xFFF3E8FF),
            iconColor: AppColors.purpleBadgeText,
            title: 'ภาษาของแอปพลิเคชัน',
            subtitle: 'ภาษาไทย (Thai)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('แอปพลิเคชันเปิดใช้งานภาษาไทยเป็นหลักแล้ว')),
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. เกี่ยวกับแอปพลิเคชัน (About Finly)
          const _SectionTitle(title: 'เกี่ยวกับ Finly'),
          const SizedBox(height: 10),
          _ProfileSettingTile(
            icon: Icons.info_outline_rounded,
            iconBgColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'เวอร์ชันแอปพลิเคชัน',
            subtitle: 'Finly Personal Finance · v1.0.0',
            onTap: null,
          ),
          const SizedBox(height: 8),
          _ProfileSettingTile(
            icon: Icons.cloud_done_rounded,
            iconBgColor: const Color(0xFFDCFCE7),
            iconColor: AppColors.income,
            title: 'สถานะการเชื่อมต่อ API',
            subtitle: 'เชื่อมต่อเซิร์ฟเวอร์สำเร็จ',
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
// PROFILE HERO CARD: การ์ดโปรไฟล์หลักสีเข้มพร้อมวงแหวนสีเขียว Lime
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16251C), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // อวตารตัวอักษรย่อ พร้อมวงแหวนสีเขียว Lime
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.limeAccent,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xFF16251C),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ชื่อผู้ใช้
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),

          // อีเมล
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),

          // ป้ายสมาชิก Verified
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.limeAccent,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'สมาชิก Finly Verified',
                  style: TextStyle(
                    color: AppColors.limeAccent,
                    fontSize: 12,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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
// SECTION TITLE: หัวข้อกลุ่มการตั้งค่า
// ============================================================================
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
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
  final VoidCallback? onTap;

  const _ProfileSettingTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
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
// LOGOUT BUTTON: ปุ่มออกจากระบบสีแดงอ่อนทรงมน
// ============================================================================
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}