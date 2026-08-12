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
  bool _hideBalance = false;
  int _unreadNotificationCount = 2;

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
      final monthEnd = Formatters.apiDate(
        DateTime(now.year, now.month, now.day),
      );
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final results = await Future.wait([
        TransactionService.list(
          token: token,
          startDate: monthStart,
          endDate: monthEnd,
        ),
        TransactionService.report(
          token: token,
          month: Formatters.monthKey(lastMonth),
        ),
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
    final screen = type == 'income'
        ? const AddIncomeScreen()
        : const AddExpenseScreen();
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => screen));
    if (saved == true && mounted) {
      _load();
    }
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'เพิ่มรายการใหม่',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 20),
                _AddOption(
                  icon: Icons.arrow_downward_rounded,
                  label: 'บันทึกรายรับ (Income)',
                  color: AppColors.income,
                  accentColor: AppColors.limeAccent,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openAdd('income');
                  },
                ),
                const SizedBox(height: 12),
                _AddOption(
                  icon: Icons.arrow_upward_rounded,
                  label: 'บันทึกรายจ่าย (Expense)',
                  color: AppColors.expenseRed,
                  accentColor: const Color(0xFFFEE2E2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openAdd('expense');
                  },
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        user: user,
        onNavigate: _handleDrawerAction,
        onAddTransaction: (type) {
          Navigator.of(context).pop();
          _openAdd(type);
        },
        onLogout: () => session.logout(),
      ),
      body: IndexedStack(
        index: _activeNavIndex,
        children: [
          SafeArea(bottom: false, child: _buildHomeBody(user)),
          StatisticsScreen(onMenuTap: _openDrawer),
          const SizedBox.shrink(),
          TransactionsScreen(onMenuTap: _openDrawer),
          SettingsScreen(onMenuTap: _openDrawer),
        ],
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

  Widget _buildHomeBody(User? user) {
    if (_loading && _page == null) {
      return const HomeSkeletonView();
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final balance = _page?.summary.balance ?? 0;
    final totalIncome = _page?.summary.totalIncome ?? 0;
    final totalExpense = _page?.summary.totalExpense ?? 0;
    final lastMonthIncome = _report?.summary.totalIncome ?? 0;
    final lastMonthExpense = _report?.summary.totalExpense ?? 0;
    final lastMonthSavings = lastMonthIncome - lastMonthExpense;

    final String savingsText;
    if (lastMonthSavings > 0) {
      savingsText =
          'เดือนที่แล้วประหยัดได้ ${Formatters.money(lastMonthSavings)}';
    } else if (lastMonthExpense > 0) {
      savingsText = 'เดือนที่แล้วใช้จ่าย ${Formatters.money(lastMonthExpense)}';
    } else {
      savingsText = 'ดูสรุปรายงานการเงินเดือนที่แล้ว';
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.limeAccentDark,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          10,
          AppConstants.pagePadding,
          28,
        ),
        children: [
          // ส่วนหัว: Avatar + ทักทาย + ปุ่มแจ้งเตือน/เมนู
          _TopHeaderBar(
            user: user,
            onMenuTap: _openDrawer,
            onNotificationTap: () => _openNotificationsSheet(user),
            unreadCount: _unreadNotificationCount,
          ),
          const SizedBox(height: 18),

          // การ์ดยอดเงินคงเหลือ Hero Balance Card ในธีม Lime Accent
          _BalanceSection(
            balance: balance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            hideBalance: _hideBalance,
            onToggleHideBalance: () {
              setState(() => _hideBalance = !_hideBalance);
            },
            savingsText: savingsText,
            onSavingsTap: _navigateToStatistics,
          ),
          const SizedBox(height: 22),

          // 4 ปุ่มทางลัด (รายรับ, รายจ่าย, สถิติ, ประวัติ)
          _QuickActionsRow(
            onIncomeTap: () => _openAdd('income'),
            onExpenseTap: () => _openAdd('expense'),
            onStatsTap: _navigateToStatistics,
            onHistoryTap: _navigateToTransactions,
          ),
          const SizedBox(height: 26),

          // ส่วนประวัติรายการล่าสุด
          _SectionHeader(
            title: 'ประวัติรายการล่าสุด',
            onViewAll: _navigateToTransactions,
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.limeAccentDark,
                ),
              ),
            )
          else if (_page == null || _page!.transactions.isEmpty)
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'ยังไม่มีรายการในเดือนนี้',
              subtitle: 'เพิ่มรายรับหรือรายจ่ายแรกของคุณเพื่อเริ่มต้นบันทึก',
              actionLabel: 'เพิ่มรายการ',
              onAction: _openAddSheet,
            )
          else
            ..._page!.transactions
                .take(6)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TransactionCard(
                      transaction: t,
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => t.isIncome
                                  ? AddIncomeScreen(transaction: t)
                                  : AddExpenseScreen(transaction: t),
                            ),
                          )
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
// TOP HEADER BAR: Avatar + ทักทาย + ปุ่มเมนู & แจ้งเตือน
// ============================================================================
class _TopHeaderBar extends StatelessWidget {
  final User? user;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final int unreadCount;

  const _TopHeaderBar({
    required this.user,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.fname.isNotEmpty == true ? user!.fname : 'คุณ';

    return Row(
      children: [
        // Avatar + ปุ่มเปิด Drawer
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.limeAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.initials ?? 'F',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ทักทายผู้ใช้ & กระเป๋าเงินหลัก
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'สวัสดี, $name 👋',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF84CC16),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'กระเป๋าเงินหลัก Finly',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ปุ่มแจ้งเตือน
        InkWell(
          onTap: onNotificationTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
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
                          color: Color(0xFF1E293B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
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
// BALANCE SECTION: Modern High-End Fintech Hero Card with Lime Accent
// ============================================================================
class _BalanceSection extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final bool hideBalance;
  final VoidCallback onToggleHideBalance;
  final String savingsText;
  final VoidCallback onSavingsTap;

  const _BalanceSection({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.hideBalance,
    required this.onToggleHideBalance,
    required this.savingsText,
    required this.onSavingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balancePrefix = isPositive ? '+' : '-';
    final formattedBalance = hideBalance
        ? '••••••••'
        : '$balancePrefix${Formatters.money(balance.abs())}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Sleek obsidian/slate dark background
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle lime gradient glow in the top right corner
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.limeAccent.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Top: Label + Wallet chip + Eye icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.limeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.limeAccent.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.limeAccent,
                                size: 12.5,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'ยอดเงินคงเหลือ',
                                style: TextStyle(
                                  color: AppColors.limeAccent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ตัวเลขยอดเงินคงเหลือขนาดใหญ่
                Text(
                  formattedBalance,
                  style: TextStyle(
                    color: hideBalance
                        ? Colors.white
                        : (isPositive
                            ? AppColors.limeAccent
                            : const Color(0xFFF87171)),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 18),

                // เส้นประ / แถบสรุปรายรับ - รายจ่ายเดือนนี้
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      // รายรับเดือนนี้
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.limeAccent.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: AppColors.limeAccent,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายรับ',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    hideBalance
                                        ? '•••'
                                        : '+${Formatters.money(totalIncome)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.limeAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 12),
                      // รายจ่ายเดือนนี้
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFF87171),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายจ่าย',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    hideBalance
                                        ? '•••'
                                        : '-${Formatters.money(totalExpense)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFF87171),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ป้ายไฮไลท์ออมเงิน / สรุปเดือนที่แล้ว
                InkWell(
                  onTap: onSavingsTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF1E293B),
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            savingsText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF1E293B),
                          size: 18,
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
// QUICK ACTIONS ROW: 4 ปุ่มทางลัด (รายรับ, รายจ่าย, สถิติ, ประวัติ)
// ============================================================================
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onStatsTap;
  final VoidCallback onHistoryTap;

  const _QuickActionsRow({
    required this.onIncomeTap,
    required this.onExpenseTap,
    required this.onStatsTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline_rounded,
            label: 'รายรับ',
            backgroundColor: AppColors.limeAccent,
            iconColor: const Color(0xFF111827),
            textColor: const Color(0xFF111827),
            isPrimary: true,
            onTap: onIncomeTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.remove_circle_outline_rounded,
            label: 'รายจ่าย',
            backgroundColor: Colors.white,
            iconColor: const Color(0xFFE11D48),
            textColor: AppColors.textPrimary,
            onTap: onExpenseTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.insights_rounded,
            label: 'สถิติ',
            backgroundColor: Colors.white,
            iconColor: const Color(0xFF2563EB),
            textColor: AppColors.textPrimary,
            onTap: onStatsTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_rounded,
            label: 'ประวัติ',
            backgroundColor: Colors.white,
            iconColor: const Color(0xFF0D9488),
            textColor: AppColors.textPrimary,
            onTap: onHistoryTap,
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
  final Color textColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      elevation: isPrimary ? 2 : 0,
      shadowColor: isPrimary
          ? AppColors.limeAccent.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isPrimary
                ? Border.all(
                    color: AppColors.limeAccentDark.withValues(alpha: 0.3),
                    width: 1,
                  )
                : Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.35)
                      : iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
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
        Row(
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: const Row(
              children: [
                Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 17,
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
// BOTTOM NAVIGATION BAR: 5 เมนู พร้อมปุ่ม Add เด่นตรงกลางธีม Lime Accent
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
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
              // ปุ่มตรงกลางสีเขียวสว่าง Lime Accent พร้อม Shadow อิ่มสวย
              GestureDetector(
                onTap: () => onItemTapped(2),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.limeAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeAccentDark.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF111827),
                    size: 30,
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
        ),
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
    final color = selected ? const Color(0xFF111827) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 3),
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.limeAccentDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
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
  final Color accentColor;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
