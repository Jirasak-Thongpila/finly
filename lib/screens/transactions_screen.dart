import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

/// หน้าประวัติรายการธุรกรรม (TransactionsScreen) ดีไซน์ใหม่:
/// - แถบเลือกตัวกรอง 3 สถานะ (ทั้งหมด, รายรับ, รายจ่าย) แบบ Pill Segment
/// - ช่องค้นหาค้นจากชื่อรายการ/หมวดหมู่
/// - จัดกลุ่มรายการแบ่งตามวัน (วันนี้, เมื่อวาน, วันที่ประทับเวลา)
/// - สไลด์เพื่อลบการ์ด + ปุ่มเพิ่มรายการใหม่ (+) ด้านล่างขวา
class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const TransactionsScreen({super.key, this.onMenuTap});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _typeFilter; // null = ทั้งหมด, 'income' = รายรับ, 'expense' = รายจ่าย
  String _searchQuery = '';
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
        _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
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
          content: Text('ลบรายการเรียบร้อยแล้ว'),
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

  void _showAddSheet() {
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
                  _openAddScreen('income');
                },
              ),
              const SizedBox(height: 10),
              _AddOption(
                icon: Icons.remove_circle_outline,
                label: 'บันทึกรายจ่าย',
                color: AppColors.expense,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAddScreen('expense');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddScreen(String type) {
    final screen =
        type == 'income' ? const AddIncomeScreen() : const AddExpenseScreen();
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => screen))
        .then((changed) {
      if (changed == true && mounted) _load();
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> rawList) {
    if (_searchQuery.trim().isEmpty) return rawList;
    final query = _searchQuery.trim().toLowerCase();
    return rawList.where((t) {
      final desc = t.description.toLowerCase();
      final cat = t.category.toLowerCase();
      return desc.contains(query) || cat.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.subject_rounded, color: AppColors.textPrimary),
          tooltip: 'เปิดเมนู',
          onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text(
          'ประวัติรายการธุรกรรม',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.limeAccent,
        foregroundColor: AppColors.textPrimary,
        elevation: 3,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Column(
        children: [
          // 1. แถบเลือกประเภทตัวกรอง (ทั้งหมด / รายรับ / รายจ่าย)
          _SegmentFilterBar(
            selected: _typeFilter,
            onChanged: (type) {
              setState(() => _typeFilter = type);
              _load();
            },
          ),

          // 2. ช่องค้นหาจากชื่อรายการ/หมวดหมู่
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
              vertical: 4,
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ค้นหาจากชื่อรายการ หรือหมวดหมู่…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 3. รายการธุรกรรมแบ่งกลุ่มตามวันที่
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _page == null) {
      return const TransactionsSkeletonView();
    }
    if (_error != null && _page == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final rawTransactions = _page?.transactions ?? const <Transaction>[];
    final filtered = _filterTransactions(rawTransactions);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'ยังไม่มีรายการธุรกรรม',
              subtitle: _searchQuery.isNotEmpty
                  ? 'ไม่พบรายการที่ค้นหา "$_searchQuery"'
                  : _typeFilter == null
                      ? 'คุณสามารถเพิ่มรายการรายรับหรือรายจ่ายใหม่ได้ทันที'
                      : 'ไม่พบรายการในหมวด $_typeFilter',
              actionLabel: 'เพิ่มรายการ',
              onAction: _showAddSheet,
            ),
          ],
        ),
      );
    }

    // จัดกลุ่มตามวันที่
    final grouped = _groupTransactions(filtered);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 4, AppConstants.pagePadding, 80,
        ),
        itemCount: grouped.length,
        itemBuilder: (context, dateIndex) {
          final dateKey = grouped.keys.elementAt(dateIndex);
          final items = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อวันที่
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Text(
                  _formatDateHeader(dateKey),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              // การ์ดรายการในวันนั้นๆ
              ...items.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'ลบรายการ',
                              style: TextStyle(
                                color: AppColors.expenseRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context, t),
                      onDismissed: (_) => _delete(t),
                      child: TransactionCard(
                        transaction: t,
                        onTap: () => _edit(t),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<Transaction>> _groupTransactions(List<Transaction> list) {
    final Map<String, List<Transaction>> groups = {};
    for (final t in list) {
      final key = t.date;
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  String _formatDateHeader(String dateStr) {
    try {
      final now = DateTime.now();
      final todayStr = Formatters.apiDate(now);
      final yesterdayStr = Formatters.apiDate(now.subtract(const Duration(days: 1)));

      if (dateStr == todayStr) return 'วันนี้';
      if (dateStr == yesterdayStr) return 'เมื่อวาน';

      final dt = DateTime.parse(dateStr);
      const thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      return '${dt.day} ${thaiMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Transaction t) async {
    final title = t.description.isNotEmpty ? t.description : t.category;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ยืนยันการลบรายการ?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('คุณต้องการลบรายการ "$title" ใช่หรือไม่?'),
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
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ============================================================================
// SEGMENT FILTER BAR: ตัวกรองแบบ Pill Segment (ทั้งหมด / รายรับ / รายจ่าย)
// ============================================================================
class _SegmentFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SegmentFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding, 8, AppConstants.pagePadding, 8,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'ทั้งหมด',
              isSelected: selected == null,
              onTap: () => onChanged(null),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: 'รายรับ (+)',
              isSelected: selected == 'income',
              activeColor: AppColors.income,
              onTap: () => onChanged('income'),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: 'รายจ่าย (-)',
              isSelected: selected == 'expense',
              activeColor: AppColors.expenseRed,
              onTap: () => onChanged('expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.label,
    required this.isSelected,
    this.activeColor = AppColors.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (activeColor == AppColors.textPrimary ? AppColors.limeAccent : activeColor.withValues(alpha: 0.12)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (activeColor == AppColors.textPrimary ? AppColors.textPrimary : activeColor) : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Inter',
          ),
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