import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/constants.dart';

/// Notification Data model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  bool isRead;
  final VoidCallback? onTap;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.isRead = false,
    this.onTap,
  });
}

/// Modal Bottom Sheet สำหรับแสดงการแจ้งเตือนของแอป Finly
class NotificationsSheet extends StatefulWidget {
  final User? user;
  final VoidCallback? onNavigateToStats;
  final VoidCallback? onNavigateToTransactions;
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationsSheet({
    super.key,
    this.user,
    this.onNavigateToStats,
    this.onNavigateToTransactions,
    this.onUnreadCountChanged,
  });

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    final name = widget.user?.fullName ?? 'ผู้ใช้งาน';
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'ยินดีต้อนรับสู่ Finly',
        message: 'ยินดีต้อนรับคุณ $name เข้าสู่ระบบการเงินออนไลน์ Finly',
        time: '10 นาทีที่แล้ว',
        icon: Icons.auto_awesome,
        iconBgColor: AppColors.limeAccent,
        iconColor: AppColors.textPrimary,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'สรุปการเงินประจำเดือน',
        message: 'รายงานสรุปสัดส่วนการใช้จ่ายประจำเดือนพร้อมให้คุณตรวจสอบแล้ว',
        time: '1 ชั่วโมงที่แล้ว',
        icon: Icons.pie_chart_rounded,
        iconBgColor: const Color(0xFFF3E8FF),
        iconColor: AppColors.purpleBadgeText,
        isRead: false,
        onTap: () {
          Navigator.of(context).pop();
          widget.onNavigateToStats?.call();
        },
      ),
      NotificationItem(
        id: '3',
        title: 'ความปลอดภัยของบัญชี',
        message: 'เข้าสู่ระบบสำเร็จอย่างปลอดภัยจากอุปกรณ์ของคุณ',
        time: 'วันนี้',
        icon: Icons.shield_outlined,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
        isRead: true,
      ),
    ];
  }

  void _notifyUnreadCount() {
    final count = _notifications.where((n) => !n.isRead).length;
    widget.onUnreadCountChanged?.call(count);
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    _notifyUnreadCount();
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    _notifyUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'การแจ้งเตือน',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount ใหม่',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_notifications.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) {
                      if (val == 'read') _markAllAsRead();
                      if (val == 'clear') _clearAll();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expenseRed),
                            SizedBox(width: 8),
                            Text('ล้างการแจ้งเตือนทั้งหมด', style: TextStyle(color: AppColors.expenseRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List or Empty View
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              color: AppColors.textSecondary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'ไม่มีการแจ้งเตือน',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'คุณได้อ่านการแจ้งเตือนทั้งหมดแล้ว',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Material(
                        color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        elevation: 0.5,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              item.isRead = true;
                            });
                            _notifyUnreadCount();
                            item.onTap?.call();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: item.iconBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item.icon, color: item.iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14.5,
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item.time,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                          fontSize: 12.5,
                                          height: 1.3,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.income,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
