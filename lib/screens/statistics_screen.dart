import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/summary.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/state_views.dart';

/// Monthly statistics from `GET /api/reports/summary?month=YYYY-MM` with
/// category breakdown bars.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _month = DateTime.now();
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
      final report =
          await TransactionService.report(token: token, month: Formatters.monthKey(_month));
      if (!mounted) return;
      setState(() {
        _report = report;
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select month',
    );
    if (picked != null) {
      setState(() => _month = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Change month',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _report == null) {
      return const LoadingView(message: 'Loading statistics…');
    }
    if (_error != null && _report == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final report = _report!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 32,
        ),
        children: [
          _MonthHeader(month: report.month, onTap: _pickMonth),
          const SizedBox(height: 16),
          BalanceCard(
            balance: report.summary.balance,
            totalIncome: report.summary.totalIncome,
            totalExpense: report.summary.totalExpense,
          ),
          const SizedBox(height: 24),
          const Text(
            'Spending by category',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          if (report.categoryBreakdown.isEmpty)
            const EmptyView(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No data for this month',
              subtitle: 'Add some transactions to see insights.',
            )
          else
            ..._breakdownBars(),
        ],
      ),
    );
  }

  List<Widget> _breakdownBars() {
    final total = _report!.summary.totalExpense;
    final items = _report!.categoryBreakdown
        .where((c) => c.type == 'expense')
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return items.map((item) {
      final pct = total > 0 ? item.total / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${Formatters.money(item.total)} · ${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _MonthHeader extends StatelessWidget {
  final String month;
  final VoidCallback onTap;

  const _MonthHeader({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String label;
    try {
      label = Formatters.formatMonth(Formatters.parseDate('$month-01'));
    } catch (_) {
      label = 'All time';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('Change'),
        ),
      ],
    );
  }
}