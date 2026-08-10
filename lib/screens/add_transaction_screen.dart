import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/api_client.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../state/form_submit.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/state_views.dart';

/// Shared "Add / Edit transaction" form used by Add Income & Add Expense.
///
/// * `POST /api/transactions` when creating.
/// * `PUT /api/transactions/:id` when [existing] is provided (edit mode).
/// Categories are always fetched live from `GET /api/categories` —
/// never hardcoded.
class AddTransactionScreen extends StatefulWidget {
  final String type; // TransactionType.income | TransactionType.expense
  final Transaction? existing;

  const AddTransactionScreen({super.key, required this.type, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  List<Category> _categories = const [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  String? _selectedCategory;
  DateTime _date = DateTime.now();
  FormSubmit _submit = const FormSubmit.idle();

  bool get _isIncome => widget.type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amount.text = existing.amount.toStringAsFixed(2);
      _description.text = existing.description;
      _selectedCategory = existing.category;
      _date = Formatters.parseDate(existing.date);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final group = await TransactionService.categories();
      if (!mounted) return;
      setState(() {
        _categories = group.forType(widget.type);
        _categoriesLoading = false;
        if (_selectedCategory == null &&
            _categories.isNotEmpty &&
            !_categories.any((c) => c.name == _selectedCategory)) {
          _selectedCategory = _categories.first.name;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = e.userMessage;
        _categoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoriesError = 'ไม่สามารถโหลดหมวดหมู่ได้';
        _categoriesLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่ทำรายการ',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _isIncome
                ? AppColors.limeAccentDark
                : AppColors.expenseRed,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addQuickAmount(double value) {
    final current = double.tryParse(_amount.text.trim()) ?? 0.0;
    final updated = current + value;
    setState(() {
      _amount.text = updated.toStringAsFixed(updated % 1 == 0 ? 0 : 2);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')));
      return;
    }
    setState(() => _submit = const FormSubmit.loading());

    final token = context.read<SessionManager>().token;
    if (token == null) return;

    final amount = double.parse(_amount.text.trim());
    final category = _selectedCategory!;
    final description = _description.text.trim();
    final date = Formatters.apiDate(_date);

    try {
      if (widget.isEdit) {
        await TransactionService.update(
          token: token,
          id: widget.existing!.id,
          type: widget.type,
          amount: amount,
          category: category,
          description: description,
          date: date,
        );
      } else {
        await TransactionService.create(
          token: token,
          type: widget.type,
          amount: amount,
          category: category,
          description: description,
          date: date,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'อัปเดตรายการเรียบร้อยแล้ว'
                : _isIncome
                ? 'บันทึกรายรับสำเร็จ'
                : 'บันทึกรายจ่ายสำเร็จ',
          ),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submit = FormSubmit.failed(e.userMessage));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _submit = const FormSubmit.failed(
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit
        ? (_isIncome ? 'แก้ไขรายรับ' : 'แก้ไขรายจ่าย')
        : (_isIncome ? 'บันทึกรายรับ' : 'บันทึกรายจ่าย');

    return PopScope(
      canPop: !_submit.isBusy,
      child: Scaffold(
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
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: _submit.isBusy
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          centerTitle: true,
          actions: [
            // Badge บอกประเภทรายการ (รายรับ vs รายจ่าย)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isIncome
                        ? AppColors.limeAccent
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isIncome
                          ? AppColors.limeAccentDark.withValues(alpha: 0.4)
                          : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 13,
                        color: _isIncome
                            ? const Color(0xFF111827)
                            : const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isIncome ? 'รายรับ (+)' : 'รายจ่าย (-)',
                        style: TextStyle(
                          color: _isIncome
                              ? const Color(0xFF111827)
                              : const Color(0xFFE11D48),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _categoriesLoading
              ? const LoadingView(message: 'กำลังโหลดหมวดหมู่…')
              : _categoriesError != null
              ? ErrorView(message: _categoriesError!, onRetry: _loadCategories)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    10,
                    AppConstants.pagePadding,
                    40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. การ์ดระบุจำนวนเงิน (Hero Amount Card)
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827), // Obsidian Dark
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF111827,
                                ).withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Ambient Glow
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        (_isIncome
                                                ? AppColors.limeAccent
                                                : const Color(0xFFEF4444))
                                            .withValues(alpha: 0.22),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'จำนวนเงิน (THB)',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      Icon(
                                        Icons.payments_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _amount,
                                    autofocus: !widget.isEdit,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    cursorColor: _isIncome
                                        ? AppColors.limeAccent
                                        : const Color(0xFFEF4444),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: _isIncome
                                          ? AppColors.limeAccent
                                          : const Color(0xFFEF4444),
                                      fontFamily: 'Inter',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(
                                        color: (_isIncome
                                                ? AppColors.limeAccent
                                                : const Color(0xFFEF4444))
                                            .withValues(alpha: 0.3),
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      filled: false,
                                      prefixText: '฿ ',
                                      prefixStyle: TextStyle(
                                        color: _isIncome
                                            ? AppColors.limeAccent
                                            : const Color(0xFFEF4444),
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    validator: (v) {
                                      final text = (v ?? '').trim();
                                      if (text.isEmpty) {
                                        return 'กรุณากรอกจำนวนเงิน';
                                      }
                                      final n = double.tryParse(text);
                                      if (n == null || n <= 0) {
                                        return 'กรุณาระบุจำนวนเงินที่ถูกต้อง';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // แถบปุ่มลัดระบุจำนวนเงิน (+100, +500, +1,000, +5,000)
                                  Row(
                                    children: [
                                      _QuickAmountChip(
                                        label: '+100',
                                        onTap: () => _addQuickAmount(100),
                                      ),
                                      const SizedBox(width: 8),
                                      _QuickAmountChip(
                                        label: '+500',
                                        onTap: () => _addQuickAmount(500),
                                      ),
                                      const SizedBox(width: 8),
                                      _QuickAmountChip(
                                        label: '+1,000',
                                        onTap: () => _addQuickAmount(1000),
                                      ),
                                      const SizedBox(width: 8),
                                      _QuickAmountChip(
                                        label: '+5,000',
                                        onTap: () => _addQuickAmount(5000),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. หมวดหมู่ (Category Selector)
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
                            const Text(
                              'เลือกหมวดหมู่',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((c) {
                            final selected = c.name == _selectedCategory;
                            return _CategoryTile(
                              name: c.name,
                              icon: c.icon,
                              selected: selected,
                              isIncome: _isIncome,
                              onTap: () =>
                                  setState(() => _selectedCategory = c.name),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // 3. วันที่ทำรายการ (Date Picker)
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
                            const Text(
                              'วันที่ทำรายการ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.limeAccent.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Color(0xFF65A30D),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    Formatters.formatDate(
                                      Formatters.apiDate(_date),
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. บันทึกเพิ่มเติม (Note / Description)
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
                            const Text(
                              'บันทึกเพิ่มเติม (ไม่บังคับ)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _description,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontFamily: 'Inter',
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'ใส่รายละเอียด เช่น ค่ากาแฟ, เงินเดือน, ซื้อของเข้าบ้าน…',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              contentPadding: EdgeInsets.all(16),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),

                        if (_submit.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.expenseRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _submit.error!,
                                    style: const TextStyle(
                                      color: AppColors.expenseRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // 5. ปุ่มบันทึกรายการ (Submit Button)
                        GestureDetector(
                          onTap: _submit.isBusy ? null : _save,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            decoration: BoxDecoration(
                              color: _isIncome
                                  ? AppColors.limeAccent
                                  : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _isIncome
                                      ? AppColors.limeAccentDark.withValues(
                                          alpha: 0.4,
                                        )
                                      : const Color(
                                          0xFF111827,
                                        ).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _submit.isBusy
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: _isIncome
                                          ? const Color(0xFF111827)
                                          : Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.isEdit
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.add_circle_outline_rounded,
                                        size: 20,
                                        color: _isIncome
                                            ? const Color(0xFF111827)
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isEdit
                                            ? 'อัปเดตรายการ'
                                            : (_isIncome
                                                  ? 'บันทึกรายรับ'
                                                  : 'บันทึกรายจ่าย'),
                                        style: TextStyle(
                                          color: _isIncome
                                              ? const Color(0xFF111827)
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final String icon;
  final bool selected;
  final bool isIncome;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.selected,
    required this.isIncome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isIncome ? AppColors.limeAccent : const Color(0xFF111827);
    final activeText = isIncome ? const Color(0xFF111827) : Colors.white;

    return Material(
      color: selected ? activeBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: selected
          ? (isIncome
                ? AppColors.limeAccent.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.2))
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? (isIncome
                        ? AppColors.limeAccentDark
                        : const Color(0xFF111827))
                  : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryIcons.from(icon),
                size: 18,
                color: selected
                    ? activeText
                    : (isIncome
                          ? const Color(0xFF65A30D)
                          : const Color(0xFFE11D48)),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: selected ? activeText : AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
