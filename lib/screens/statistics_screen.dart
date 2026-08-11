import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/summary.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/state_views.dart';

const List<String> _thaiMonths = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
  'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
  'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
];

/// สีพาเลตต์สำหรับแต่ละหมวดหมู่ เพื่อแยกแยะด้วยสายตาอย่างเด่นชัด
const List<Color> _categoryColors = [
  Color(0xFFEA580C), // ส้ม
  Color(0xFF2563EB), // น้ำเงิน
  Color(0xFF7C3AED), // ม่วง
  Color(0xFF059669), // เขียวมรกต
  Color(0xFFD97706), // เหลืองอำพัน
  Color(0xFFDC2626), // แดง
  Color(0xFF0891B2), // ฟ้า
  Color(0xFF4F46E5), // คราม
];

/// หน้าสถิติการเงิน (StatisticsScreen):
/// - แถบเลื่อนเปลี่ยนเดือนด้านบนของการ์ด Total Balance (ปุ่มลูกศร + ปุ่มเลือกวันที่)
/// - การ์ดแสดงสรุปยอดเงินคงเหลือ รายรับ รายจ่าย
/// - ปุ่มสลับสถิติระหว่างหมวดหมู่รายรับ (+) และ รายจ่าย (-)
/// - การ์ดภาพรวมสัดส่วนรายรับ/รายจ่ายพร้อมไอคอนหมวดหมู่และแถบสีแยกชัดเจน
class StatisticsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const StatisticsScreen({super.key, this.onMenuTap});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _month = DateTime.now();
  ReportSummary? _report;
  bool _loading = true;
  String? _error;
  String _breakdownType = 'expense'; // 'expense' | 'income'

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
      final report = await TransactionService.report(
        token: token,
        month: Formatters.monthKey(_month),
      );
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
        _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
        _loading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
    });
    _load();
  }

  void _selectMonth(DateTime selected) {
    setState(() {
      _month = DateTime(selected.year, selected.month, 1);
    });
    _load();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'เลือกเดือน',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) {
      _selectMonth(picked);
    }
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
          'สถิติการเงิน',
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
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'เลือกเดือน',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _report == null) {
      return const StatisticsSkeletonView();
    }
    if (_error != null && _report == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final report = _report!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding, 8, AppConstants.pagePadding, 32,
        ),
        children: [
          // 1. แถบเลื่อนเปลี่ยนเดือนด้านบนของการ์ด Total Balance (ปุ่มลูกศร + ปุ่มเลือกวันที่)
          _MonthSelectorBar(
            currentMonth: _month,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            onSelect: _pickMonth,
          ),
          const SizedBox(height: 14),

          // 2. การ์ดสรุปยอดเงินคงเหลือ Total Balance
          BalanceCard(
            balance: report.summary.balance,
            totalIncome: report.summary.totalIncome,
            totalExpense: report.summary.totalExpense,
          ),
          const SizedBox(height: 24),

          // 3. ปุ่มสลับประเภทหมวดหมู่ (รายจ่าย (-) / รายรับ (+))
          _CategoryTypeToggleBar(
            selectedType: _breakdownType,
            onChanged: (type) => setState(() => _breakdownType = type),
          ),
          const SizedBox(height: 16),

          if (report.categoryBreakdown.isEmpty)
            const EmptyView(
              icon: Icons.pie_chart_outline_rounded,
              title: 'ไม่มีข้อมูลในเดือนนี้',
              subtitle: 'ลองเพิ่มรายการธุรกรรมเพื่อดูสถิติและข้อมูลเชิงลึก',
            )
          else ...[
            // การ์ดรวมสัดส่วนแบบหลายสี (Multi-Color Segmented Overview Card)
            _CategoryOverviewCard(
              breakdown: report.categoryBreakdown,
              totalAmount: _breakdownType == 'income'
                  ? report.summary.totalIncome
                  : report.summary.totalExpense,
              type: _breakdownType,
            ),
            const SizedBox(height: 16),

            // รายการแต่ละหมวดหมู่พร้อมไอคอน แถบสี และเปอร์เซ็นต์
            ..._buildCategoryList(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList() {
    final isIncome = _breakdownType == 'income';
    final total = isIncome
        ? _report!.summary.totalIncome
        : _report!.summary.totalExpense;
    final items = _report!.categoryBreakdown
        .where((c) => c.type == _breakdownType)
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    if (items.isEmpty) {
      final typeText = isIncome ? 'รายรับ' : 'รายจ่าย';
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'ไม่มีรายการ$typeTextในเดือนนี้',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      ];
    }

    return List.generate(items.length, (index) {
      final item = items[index];
      final pct = total > 0 ? item.total / total : 0.0;
      final categoryColor = _categoryColors[index % _categoryColors.length];
      final amountColor = isIncome ? AppColors.income : AppColors.expenseRed;
      final amountPrefix = isIncome ? '+' : '-';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // ไอคอนหมวดหมู่พร้อมกล่องสีพาสเทล
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      CategoryIcons.from(item.category),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ชื่อหมวดหมู่ & จำนวนรายการ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.count} รายการ',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // จำนวนเงิน & ป้ายสัดส่วน %
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix${Formatters.money(item.total)}',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // แถบสัดส่วนสีเฉพาะของหมวดหมู่นั้นๆ
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ============================================================================
// CATEGORY TYPE TOGGLE BAR: แถบสลับ รายจ่าย (-) vs รายรับ (+)
// ============================================================================
class _CategoryTypeToggleBar extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _CategoryTypeToggleBar({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'หมวดหมู่รายจ่าย (-)',
              isSelected: selectedType == 'expense',
              activeColor: AppColors.expenseRed,
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'หมวดหมู่รายรับ (+)',
              isSelected: selectedType == 'income',
              activeColor: AppColors.income,
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
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
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CATEGORY OVERVIEW CARD: การ์ดรวมแถบสัดส่วนรายรับ/รายจ่ายหลายสี
// ============================================================================
class _CategoryOverviewCard extends StatelessWidget {
  final List<CategoryBreakdown> breakdown;
  final double totalAmount;
  final String type; // 'expense' | 'income'

  const _CategoryOverviewCard({
    required this.breakdown,
    required this.totalAmount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'income';
    final items = breakdown.where((c) => c.type == type).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    if (items.isEmpty || totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    final titleLabel = isIncome ? 'สัดส่วนรายรับทั้งหมด' : 'สัดส่วนรายจ่ายทั้งหมด';
    final amountColor = isIncome ? AppColors.income : AppColors.expenseRed;
    final amountPrefix = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '$amountPrefix${Formatters.money(totalAmount)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // แถบหลากสีแบ่งสัดส่วนหมวดหมู่
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final pct = item.total / totalAmount;
                  final color = _categoryColors[index % _categoryColors.length];

                  return Expanded(
                    flex: (pct * 1000).round().clamp(1, 1000),
                    child: Container(color: color),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // สรุป 3 หมวดหมู่หลักพร้อมจุดสี
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(items.take(3).length, (index) {
              final item = items[index];
              final pct = (item.total / totalAmount * 100).toStringAsFixed(0);
              final color = _categoryColors[index % _categoryColors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.category} ($pct%)',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MONTH SELECTOR BAR: แถบเลือกเดือน/ปี ด้านบนของการ์ด Balance (ลูกศรซ้าย-ขวา)
// ============================================================================
class _MonthSelectorBar extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  const _MonthSelectorBar({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = _thaiMonths[currentMonth.month - 1];
    final year = currentMonth.year;
    final labelText = '$monthName $year';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ปุ่มเดือนก่อนหน้า
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppColors.textPrimary,
            onPressed: onPrevious,
            tooltip: 'เดือนก่อนหน้า',
          ),

          // แสดงชื่อเดือนและปฏิทิน (กดเพื่อเปิด DatePicker)
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labelText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ปุ่มเดือนถัดไป
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: AppColors.textPrimary,
            onPressed: onNext,
            tooltip: 'เดือนถัดไป',
          ),
        ],
      ),
    );
  }
}
