import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/summary.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/state_views.dart';

const List<String> _thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// สีพาเลตต์สำหรับแต่ละหมวดหมู่ เพื่อแยกแยะด้วยสายตาอย่างเด่นชัดและกลมกลืนกับธีม
const List<Color> _categoryColors = [
  Color(0xFF10B981), // มรกต
  Color(0xFF6366F1), // อินดิโก
  Color(0xFFF59E0B), // อำพัน
  Color(0xFFEC4899), // ชมพูบานเย็น
  Color(0xFF06B6D4), // ไซแอน
  Color(0xFF8B5CF6), // ม่วงสว่าง
  Color(0xFFF97316), // ส้มคอรัล
  Color(0xFF14B8A6), // ทีล
];

/// หน้าสถิติการเงิน (StatisticsScreen):
/// - แถบเลื่อนเปลี่ยนเดือนด้านบนของการ์ด Total Balance (ปุ่มลูกศร + ปุ่มเลือกวันที่)
/// - การ์ดแสดงสรุปยอดเงินคงเหลือ รายรับ รายจ่าย พร้อม Ambient Lime Glow
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
      helpText: 'เลือกเดือนสำหรับดูสถิติ',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.subject_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          tooltip: 'เปิดเมนู',
          onPressed:
              widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text(
          'สถิติการเงิน',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            tooltip: 'เลือกเดือน',
            onPressed: _pickMonth,
          ),
          const SizedBox(width: 8),
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
      color: AppColors.limeAccentDark,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          8,
          AppConstants.pagePadding,
          32,
        ),
        children: [
          // 1. แถบเลื่อนเปลี่ยนเดือนด้านบนของการ์ด Total Balance (ปุ่มลูกศร + ปุ่มเลือกวันที่)
          _MonthSelectorBar(
            currentMonth: _month,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            onSelect: _pickMonth,
          ),
          const SizedBox(height: 16),

          // 2. การ์ดสรุปยอดเงินคงเหลือ Total Balance สไตล์ Dark Lime Glow
          _StatisticsBalanceHeroCard(
            balance: report.summary.balance,
            totalIncome: report.summary.totalIncome,
            totalExpense: report.summary.totalExpense,
          ),
          const SizedBox(height: 22),

          // 3. ปุ่มสลับประเภทหมวดหมู่ (รายจ่าย (-) / รายรับ (+))
          _CategoryTypeToggleBar(
            selectedType: _breakdownType,
            onChanged: (type) => setState(() => _breakdownType = type),
          ),
          const SizedBox(height: 18),

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
            const SizedBox(height: 18),

            // หัวข้อรายการแยกตามหมวดหมู่
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
                  _breakdownType == 'income'
                      ? 'หมวดหมู่รายรับ'
                      : 'หมวดหมู่รายจ่าย',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
    final items =
        _report!.categoryBreakdown
            .where((c) => c.type == _breakdownType)
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    if (items.isEmpty) {
      final typeText = isIncome ? 'รายรับ' : 'รายจ่าย';
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'ไม่มีรายการ$typeTextในเดือนนี้',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ];
    }

    return List.generate(items.length, (index) {
      final item = items[index];
      final pct = total > 0 ? item.total / total : 0.0;
      final categoryColor = _categoryColors[index % _categoryColors.length];
      final amountColor = isIncome
          ? const Color(0xFF16A34A)
          : const Color(0xFFE11D48);
      final amountPrefix = isIncome ? '+' : '-';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
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
                  const SizedBox(width: 14),

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
                            fontWeight: FontWeight.w500,
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
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // แถบสัดส่วนสีเฉพาะของหมวดหมู่นั้นๆ
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF1F5F9),
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
// STATISTICS BALANCE HERO CARD: การ์ดยอดเงินคงเหลือและกระแสเงินสดธีม Lime Accent
// ============================================================================
class _StatisticsBalanceHeroCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  const _StatisticsBalanceHeroCard({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balancePrefix = isPositive ? '+' : '-';
    final savingsRatio = totalIncome > 0
        ? (((totalIncome - totalExpense) / totalIncome) * 100).clamp(
            -100.0,
            100.0,
          )
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Obsidian dark background
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient lime glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.limeAccent.withValues(alpha: 0.22),
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
                // Top Header Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: AppColors.limeAccent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_rounded,
                            color: AppColors.limeAccent,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'สรุปยอดประจำเดือน',
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
                    if (savingsRatio != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          savingsRatio > 0
                              ? 'ออมได้ ${savingsRatio.toStringAsFixed(0)}%'
                              : 'เกินงบ ${savingsRatio.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: savingsRatio > 0
                                ? AppColors.limeAccent
                                : const Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ยอดคงเหลือสุทธิ
                Text(
                  '$balancePrefix${Formatters.money(balance.abs())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 18),

                // สรุปรายรับ - รายจ่าย 2 ฝั่ง
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
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
                      // รายรับ (+)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.limeAccent.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: AppColors.limeAccent,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายรับทั้งหมด',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    '+${Formatters.money(totalIncome)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
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
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 12),
                      // รายจ่าย (-)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFF87171),
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายจ่ายทั้งหมด',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    '-${Formatters.money(totalExpense)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
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
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              icon: Icons.arrow_upward_rounded,
              label: 'หมวดหมู่รายจ่าย (-)',
              isSelected: selectedType == 'expense',
              activeColor: const Color(0xFF111827),
              activeBgColor: const Color(0xFFFEE2E2),
              textColor: const Color(0xFFE11D48),
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              icon: Icons.arrow_downward_rounded,
              label: 'หมวดหมู่รายรับ (+)',
              isSelected: selectedType == 'income',
              activeColor: const Color(0xFF111827),
              activeBgColor: AppColors.limeAccent,
              textColor: const Color(0xFF111827),
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color activeBgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.activeBgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? textColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? textColor : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
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

    final titleLabel = isIncome
        ? 'สัดส่วนรายรับทั้งหมด'
        : 'สัดส่วนรายจ่ายทั้งหมด';
    final amountColor = isIncome
        ? const Color(0xFF16A34A)
        : const Color(0xFFE11D48);
    final amountPrefix = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
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
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '$amountPrefix${Formatters.money(totalAmount)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // แถบหลากสีแบ่งสัดส่วนหมวดหมู่
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
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
          const SizedBox(height: 14),

          // สรุป 3 หมวดหมู่หลักพร้อมจุดสี
          Wrap(
            spacing: 14,
            runSpacing: 8,
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
                  const SizedBox(width: 6),
                  Text(
                    '${item.category} ($pct%)',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF84CC16),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labelText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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
