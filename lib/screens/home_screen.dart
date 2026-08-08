import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/summary.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/drawer_actions.dart';
import '../utils/formatters.dart';
import '../widgets/app_drawer.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';

/// Dashboard (ภาษาไทย)
/// - ส่วนหัว: ปุ่มเมนู, หัวข้อ "บัญชีของฉัน", ปุ่มแจ้งเตือน
/// - ป้ายแสดงประเภทบัญชี/กระเป๋าเงิน ( wallet badge )
/// - แสดงยอดเงินคงเหลือ "ยอดเงินคงเหลือ" พร้อมป้ายประหยัดเงินสีม่วง
/// - 4 ปุ่มทางลัด: รายรับ, รายจ่าย, สถิติ, ประวัติ
/// - ส่วนประวัติรายการล่าสุด (วันนี้)
/// - แถบเมนูด้านล่าง 5 ปุ่มภาษาไทย (หน้าหลัก, สถิติ, ปุ่มเพิ่มรายการตรงกลาง, รายการ, โปรไฟล์)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TransactionPage? _page;
  ReportSummary? _report;
  bool _loading = true;
  String? _error;
  int _activeNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<SessionManager>().token;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final monthStart = Formatters.apiDate(DateTime(now.year, now.month, 1));
      final monthEnd = Formatters.apiDate(DateTime(now.year, now.month, now.day));
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final results = await Future.wait([
        TransactionService.list(token: token, startDate: monthStart, endDate: monthEnd),
        TransactionService.report(token: token, month: Formatters.monthKey(lastMonth)),
      ]);
      if (!mounted) return;
      setState(() {
        _page = results[0] as TransactionPage;
        _report = results[1] as ReportSummary;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) {
        await context.read<SessionManager>().handleUnauthorized();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.userMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
        _loading = false;
      });
    }
  }

  Future<void> _openAdd(String type) async {
    final screen = type == 'income' ? const AddIncomeScreen() : const AddExpenseScreen();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (saved == true && mounted) {
      _load();
    }
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'เพิ่มรายการ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              _AddOption(
                icon: Icons.add_circle_outline,
                label: 'บันทึกรายรับ',
                color: AppColors.income,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAdd('income');
                },
              ),
              const SizedBox(height: 10),
              _AddOption(
                icon: Icons.remove_circle_outline,
                label: 'บันทึกรายจ่าย',
                color: AppColors.expense,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAdd('expense');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDrawerAction(DrawerAction action) {
    Navigator.of(context).pop();
    switch (action) {
      case DrawerAction.home:
        setState(() => _activeNavIndex = 0);
      case DrawerAction.transactions:
        _navigateToTransactions();
      case DrawerAction.statistics:
        _navigateToStatistics();
      case DrawerAction.settings:
        _navigateToSettings();
    }
  }

  void _navigateToTransactions() {
    setState(() => _activeNavIndex = 3);
  }

  void _navigateToStatistics() {
    setState(() => _activeNavIndex = 1);
  }

  void _navigateToSettings() {
    setState(() => _activeNavIndex = 4);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        user: user,
        onNavigate: _handleDrawerAction,
        onAddTransaction: (type) {
          Navigator.of(context).pop();
          _openAdd(type);
        },
        onLogout: () => session.logout(),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _activeNavIndex,
          children: [
            _buildHomeBody(user),
            StatisticsScreen(onMenuTap: _openDrawer),
            const SizedBox.shrink(),
            TransactionsScreen(onMenuTap: _openDrawer),
            SettingsScreen(onMenuTap: _openDrawer),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _activeNavIndex,
        onItemTapped: (index) {
          if (index == 2) {
            _openAddSheet();
          } else {
            setState(() => _activeNavIndex = index);
          }
        },
      ),
    );
  }

  int _unreadNotificationCount = 2;

  void _openNotificationsSheet(User? user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(
        user: user,
        onNavigateToStats: _navigateToStatistics,
        onNavigateToTransactions: _navigateToTransactions,
        onUnreadCountChanged: (count) {
          setState(() {
            _unreadNotificationCount = count;
          });
        },
      ),
    );
  }

  Widget _buildHomeBody(User? user) {
    if (_loading && _page == null) {
      return const HomeSkeletonView();
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final balance = _page?.summary.balance ?? 0;
    final lastMonthIncome = _report?.summary.totalIncome ?? 0;
    final lastMonthExpense = _report?.summary.totalExpense ?? 0;
    final lastMonthSavings = lastMonthIncome - lastMonthExpense;

    final String savingsText;
    if (lastMonthSavings > 0) {
      savingsText = 'เดือนที่แล้วคุณประหยัดได้ ${Formatters.money(lastMonthSavings)} >';
    } else if (lastMonthExpense > 0) {
      savingsText = 'เดือนที่แล้วคุณใช้จ่ายไป ${Formatters.money(lastMonthExpense)} >';
    } else {
      savingsText = 'ดูสรุปรายงานการเงินเดือนที่แล้ว >';
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 24,
        ),
        children: [
          // ส่วนหัว: ปุ่มเมนู, "บัญชีของฉัน", ปุ่มแจ้งเตือน
          _TopHeaderBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onNotificationTap: () => _openNotificationsSheet(user),
            unreadCount: _unreadNotificationCount,
          ),
          const SizedBox(height: 16),

          // ส่วนแสดงยอดเงินคงเหลือ (ยอดเงินคงเหลือ + ฿86,290.49 + ป้ายไฮไลท์ออมเงิน)
          _BalanceSection(
            balance: balance,
            savingsText: savingsText,
            onSavingsTap: _navigateToStatistics,
          ),
          const SizedBox(height: 24),

          // ปุ่มทางลัด 4 ปุ่ม: รายรับ, รายจ่าย, สถิติ, ประวัติ
          _QuickActionsRow(
            onSendTap: () => _openAdd('income'),
            onRequestTap: () => _openAdd('expense'),
            onExchangeTap: _navigateToStatistics,
            onMoreTap: _navigateToTransactions,
          ),
          const SizedBox(height: 28),

          // ส่วนประวัติรายการ
          _SectionHeader(
            title: 'ประวัติรายการ',
            onViewAll: _navigateToTransactions,
          ),
          const SizedBox(height: 12),
          const Text(
            'วันนี้',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_page == null || _page!.transactions.isEmpty)
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'ยังไม่มีรายการ',
              subtitle: 'เพิ่มรายรับหรือรายจ่ายแรกของคุณเพื่อเริ่มต้น',
              actionLabel: 'เพิ่มรายการ',
              onAction: _openAddSheet,
            )
          else
            ..._page!.transactions.take(6).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TransactionCard(
                      transaction: t,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (_) => t.isIncome
                                ? AddIncomeScreen(transaction: t)
                                : AddExpenseScreen(transaction: t),
                          ))
                          .then((changed) {
                        if (changed == true && mounted) _load();
                      }),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP HEADER BAR: ปุ่มเมนู, หัวข้อ "บัญชีของฉัน", ปุ่มแจ้งเตือน
// ============================================================================
class _TopHeaderBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final int unreadCount;

  const _TopHeaderBar({
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ปุ่มเมนู
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.subject_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        // หัวข้อหน้า
        const Text(
          'บัญชีของฉัน',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        // ปุ่มแจ้งเตือนพร้อม Badge ตามจำนวนจริง
        InkWell(
          onTap: onNotificationTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: AppColors.limeAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



// ============================================================================
// BALANCE SECTION: ยอดเงินคงเหลือ, ฿86,290.49, ป้ายไฮไลท์ออมเงินสีม่วง
// ============================================================================
class _BalanceSection extends StatelessWidget {
  final double balance;
  final String savingsText;
  final VoidCallback onSavingsTap;

  const _BalanceSection({
    required this.balance,
    required this.savingsText,
    required this.onSavingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? AppColors.income : AppColors.expenseRed;
    final balancePrefix = isPositive ? '+' : '-';

    return Column(
      children: [
        const Text(
          'ยอดเงินคงเหลือ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$balancePrefix${Formatters.money(balance.abs())}',
          style: TextStyle(
            color: balanceColor,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        // ป้ายประหยัดเงินสีม่วง
        InkWell(
          onTap: onSavingsTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.purpleBadgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.purpleBadgeText,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  savingsText,
                  style: const TextStyle(
                    color: AppColors.purpleBadgeText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ACTIONS ROW: 4 ปุ่มทางลัด (รายรับ, รายจ่าย, สถิติ, ประวัติ)
// ============================================================================
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onSendTap;
  final VoidCallback onRequestTap;
  final VoidCallback onExchangeTap;
  final VoidCallback onMoreTap;

  const _QuickActionsRow({
    required this.onSendTap,
    required this.onRequestTap,
    required this.onExchangeTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.north_east_rounded,
            label: 'รายรับ',
            backgroundColor: AppColors.limeAccent,
            iconColor: AppColors.textPrimary,
            onTap: onSendTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.south_west_rounded,
            label: 'รายจ่าย',
            backgroundColor: Colors.white,
            iconColor: AppColors.textPrimary,
            onTap: onRequestTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.bar_chart_rounded,
            label: 'สถิติ',
            backgroundColor: Colors.white,
            iconColor: AppColors.textPrimary,
            onTap: onExchangeTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_rounded,
            label: 'ประวัติ',
            backgroundColor: Colors.white,
            iconColor: AppColors.textPrimary,
            onTap: onMoreTap,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = backgroundColor == Colors.white;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      elevation: isWhite ? 0.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isWhite ? AppColors.background : Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

// ============================================================================
// SECTION HEADER: หัวข้อส่วน & ลิงก์ดูทั้งหมด >
// ============================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            children: [
              Text(
                'ดูทั้งหมด',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOTTOM NAVIGATION BAR: 5 เมนูภาษาไทย พร้อมปุ่มสีเขียวตรงกลาง
// ============================================================================
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'หน้าหลัก',
            selected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'สถิติ',
            selected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          // ปุ่มตรงกลางสีเขียวสว่างสำหรับเพิ่มรายการ
          GestureDetector(
            onTap: () => onItemTapped(2),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.limeAccent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'รายการ',
            selected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'โปรไฟล์',
            selected: selectedIndex == 4,
            onTap: () => onItemTapped(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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