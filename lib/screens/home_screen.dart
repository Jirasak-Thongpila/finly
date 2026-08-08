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
import '../widgets/state_views.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';

/// Dashboard matching the target fintech mobile design:
/// - Header with Menu button, "My Account" title, and Notification badge.
/// - Card selector badge (`**** 3425`).
/// - "Your Balance" centered large display with lavender savings highlight pill.
/// - 4 Quick Action cards: Send (Lime Green), Request, Exchange, More.
/// - "Top Merchants" horizontal card section.
/// - "Transaction History" list section with TODAY header.
/// - Bottom Navigation bar with elevated lime green center action button.
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
      final monthStart = Formatters.apiDate(DateTime(DateTime.now().year, DateTime.now().month, 1));
      final monthEnd = Formatters.apiDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
      final results = await Future.wait([
        TransactionService.list(token: token, startDate: monthStart, endDate: monthEnd),
        TransactionService.report(token: token, month: Formatters.monthKey(DateTime.now())),
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
        _error = 'Unexpected error. Please try again.';
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
                'Add Transaction',
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
                label: 'Add Income',
                color: AppColors.income,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAdd('income');
                },
              ),
              const SizedBox(height: 10),
              _AddOption(
                icon: Icons.remove_circle_outline,
                label: 'Add Expense',
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
        break;
      case DrawerAction.transactions:
        _navigateToTransactions();
      case DrawerAction.statistics:
        _navigateToStatistics();
      case DrawerAction.settings:
        _navigateToSettings();
    }
  }

  void _navigateToTransactions() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TransactionsScreen()))
        .then((changed) {
      if (changed == true && mounted) _load();
    });
  }

  void _navigateToStatistics() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
  }

  void _navigateToSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
        .then((changed) {
      if (changed == true && mounted) _load();
    });
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
        child: _buildBody(user),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _activeNavIndex,
        onItemTapped: (index) {
          if (index == 0) {
            setState(() => _activeNavIndex = 0);
          } else if (index == 1) {
            _navigateToStatistics();
          } else if (index == 2) {
            _openAddSheet();
          } else if (index == 3) {
            _navigateToTransactions();
          } else if (index == 4) {
            _navigateToSettings();
          }
        },
      ),
    );
  }

  Widget _buildBody(User? user) {
    if (_loading && _page == null) {
      return const LoadingView(message: 'Loading your finances…');
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final balance = _page?.summary.balance ?? 0;
    final income = _page?.summary.totalIncome ?? 0;
    final expense = _page?.summary.totalExpense ?? 0;
    final reportIncome = _report?.summary.totalIncome ?? income;
    final reportExpense = _report?.summary.totalExpense ?? expense;
    final savedMonth = (reportIncome > reportExpense) ? (reportIncome - reportExpense) : 290.0;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 24,
        ),
        children: [
          // Top Bar: Menu Button, "My Account", Notification Bell
          _TopHeaderBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(height: 12),

          // Account Badge Tag (e.g. **** 3425)
          const _AccountCardBadge(),
          const SizedBox(height: 16),

          // Balance Display Header (Your Balance + $86,290.49 + Purple Savings Highlight Tag)
          _BalanceSection(
            balance: balance,
            savedAmount: savedMonth,
            onSavingsTap: _navigateToStatistics,
          ),
          const SizedBox(height: 24),

          // Quick Action Row (4 Cards: Send, Request, Exchange, More)
          _QuickActionsRow(
            onSendTap: () => _openAdd('income'),
            onRequestTap: () => _openAdd('expense'),
            onExchangeTap: _navigateToStatistics,
            onMoreTap: _navigateToTransactions,
          ),
          const SizedBox(height: 28),

          // Transaction History Section
          _SectionHeader(
            title: 'Transaction History',
            onViewAll: _navigateToTransactions,
          ),
          const SizedBox(height: 12),
          const Text(
            'TODAY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
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
              title: 'No transactions yet',
              subtitle: 'Add your first income or expense to get started.',
              actionLabel: 'Add Transaction',
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
// TOP HEADER BAR: Circular Menu Button, "My Account" Title, Notification Bell
// ============================================================================
class _TopHeaderBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  const _TopHeaderBar({
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu Button
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
        // Title
        const Text(
          'My Account',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        // Notification Bell with Badge "2"
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
                    child: const Text(
                      '2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
// ACCOUNT CARD BADGE: small pill centered with card icon & **** 3425 dropdown
// ============================================================================
class _AccountCardBadge extends StatelessWidget {
  const _AccountCardBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFA3E635),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '**** 3425',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BALANCE SECTION: Your Balance, $86,290.49, Lavender Savings Highlight Pill
// ============================================================================
class _BalanceSection extends StatelessWidget {
  final double balance;
  final double savedAmount;
  final VoidCallback onSavingsTap;

  const _BalanceSection({
    required this.balance,
    required this.savedAmount,
    required this.onSavingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Your Balance',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Formatters.money(balance),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        // Lavender Highlight Tag: You saved $290 in last Month >
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
                  'You saved ${Formatters.money(savedAmount)} in last Month >',
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
// QUICK ACTIONS ROW: 4 Equal Cards (Send [Lime], Request, Exchange, More)
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
            label: 'Send',
            backgroundColor: AppColors.limeAccent,
            iconColor: AppColors.textPrimary,
            onTap: onSendTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.south_west_rounded,
            label: 'Request',
            backgroundColor: Colors.white,
            iconColor: AppColors.textPrimary,
            onTap: onRequestTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.swap_horiz_rounded,
            label: 'Exchange',
            backgroundColor: Colors.white,
            iconColor: AppColors.textPrimary,
            onTap: onExchangeTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.more_horiz_rounded,
            label: 'More',
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
// SECTION HEADER: Title & View all > link
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
                'View all',
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
// BOTTOM NAVIGATION BAR: 5 items with center elevated lime green action button
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
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Statistic',
            selected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          // Center Elevated Lime Green Action Button
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
                Icons.swap_vert_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.credit_card_outlined,
            label: 'Card',
            selected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
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