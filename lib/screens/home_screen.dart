import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../widgets/balance_card.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';

/// Dashboard shown after login.
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
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TransactionsScreen()))
            .then((changed) {
          if (changed == true && mounted) _load();
        });
      case DrawerAction.statistics:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
      case DrawerAction.settings:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
            .then((changed) {
          if (changed == true && mounted) _load();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.user;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        user: user,
        onNavigate: _handleDrawerAction,
        onAddTransaction: (type) {
          Navigator.of(context).pop();
          _openAdd(type);
        },
        onLogout: () => session.logout(),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: _Greeting(user: user),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _page == null) {
      return const LoadingView(message: 'Loading your finances…');
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 96,
        ),
        children: [
          BalanceCard(
            balance: _page?.summary.balance ?? 0,
            totalIncome: _page?.summary.totalIncome ?? 0,
            totalExpense: _page?.summary.totalExpense ?? 0,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'This Month'),
          const SizedBox(height: 12),
          _MonthlySummary(report: _report),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Transactions',
            trailing: _page?.pagination.totalItems != null &&
                    _page!.pagination.totalItems > 0
                ? TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const TransactionsScreen()))
                        .then((changed) {
                      if (changed == true && mounted) _load();
                    }),
                    child: const Text('View all'),
                  )
                : null,
          ),
          const SizedBox(height: 4),
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

class _Greeting extends StatelessWidget {
  final User? user;

  const _Greeting({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fname;
    final time = DateTime.now();
    final greeting = time.hour < 12
        ? 'Good morning'
        : time.hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting${name != null && name.isNotEmpty ? ', $name' : ''} 👋',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          DateFormat('EEEE, d MMMM').format(time),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final ReportSummary? report;

  const _MonthlySummary({this.report});

  @override
  Widget build(BuildContext context) {
    final income = report?.summary.totalIncome ?? 0;
    final expense = report?.summary.totalExpense ?? 0;
    final total = income + expense;
    final incomePct = total > 0 ? income / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Income',
                  value: Formatters.money(income),
                  color: AppColors.income,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Expense',
                  value: Formatters.money(expense),
                  color: AppColors.expense,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (incomePct * 1000).round().clamp(0, 1000),
                  child: Container(
                      height: 8, color: AppColors.income),
                ),
                Expanded(
                  flex: ((1 - incomePct) * 1000).round().clamp(0, 1000),
                  child: Container(
                      height: 8, color: AppColors.expense),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}