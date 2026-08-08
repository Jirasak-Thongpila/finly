import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

/// Full transaction list with income/expense filter, edit (tap) and
/// delete (swipe / confirm dialog). Refreshes from the API after changes.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _typeFilter; // null = all, 'income' | 'expense'
  TransactionPage? _page;
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
      final page = await TransactionService.list(
        token: token,
        type: _typeFilter,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
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

  Future<void> _delete(Transaction t) async {
    final token = context.read<SessionManager>().token;
    if (token == null) return;
    try {
      await TransactionService.delete(token: token, id: t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.userMessage)));
      _load();
    }
  }

  void _edit(Transaction t) {
    final screen = t.isIncome
        ? AddIncomeScreen(transaction: t)
        : AddExpenseScreen(transaction: t);
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => screen))
        .then((changed) {
      if (changed == true && mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          _FilterBar(
            selected: _typeFilter,
            onChanged: (type) {
              setState(() => _typeFilter = type);
              _load();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _page == null) {
      return const LoadingView(message: 'Loading transactions…');
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final transactions = _page?.transactions ?? const <Transaction>[];
    if (transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle:
                  _typeFilter == null
                      ? 'Add transactions from the home screen.'
                      : 'No $_typeFilter transactions found.',
              actionLabel: 'Add Income or Expense',
              onAction: () => _showAddSheet(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: DismissibleList(
        children: [...transactions],
        onDelete: _delete,
        onEdit: _edit,
        loading: _loading,
      ),
    );
  }

  void _showAddSheet() {
    final context = this.context;
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
              _Option(
                icon: Icons.add_circle_outline,
                label: 'Add Income',
                color: AppColors.income,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _editLike('income');
                },
              ),
              const SizedBox(height: 10),
              _Option(
                icon: Icons.remove_circle_outline,
                label: 'Add Expense',
                color: AppColors.expense,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _editLike('expense');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editLike(String type) {
    final screen =
        type == 'income' ? const AddIncomeScreen() : const AddExpenseScreen();
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => screen))
        .then((changed) {
      if (changed == true && mounted) _load();
    });
  }
}

/// Dismissible list wrapper to keep delete/refresh handling near the data.
class DismissibleList extends StatelessWidget {
  final List<Transaction> children;
  final Future<void> Function(Transaction) onDelete;
  final void Function(Transaction) onEdit;
  final bool loading;

  const DismissibleList({
    super.key,
    required this.children,
    required this.onDelete,
    required this.onEdit,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 24),
      itemCount: children.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= children.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final t = children[index];
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.expenseRed,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, t),
          onDismissed: (_) => onDelete(t),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TransactionCard(transaction: t, onTap: () => onEdit(t)),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
            'This will permanently remove "${t.description.isNotEmpty ? t.description : t.category}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _FilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 4, AppConstants.pagePadding, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Income',
            selected: selected == 'income',
            onTap: () => onChanged('income'),
            color: AppColors.income,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Expense',
            selected: selected == 'expense',
            onTap: () => onChanged('expense'),
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? color : AppColors.divider),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Option({
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}