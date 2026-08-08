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

  const AddTransactionScreen({
    super.key,
    required this.type,
    this.existing,
  });

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
  Color get _accent => _isIncome ? AppColors.income : AppColors.expense;

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
        _categoriesError = 'Could not load categories.';
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: _accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
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
          content: Text(widget.isEdit
              ? 'Transaction updated successfully'
              : _isIncome
                  ? 'Income added successfully'
                  : 'Expense added successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submit = FormSubmit.failed(e.userMessage));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submit = const FormSubmit.failed('Unexpected error. Please try again.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit
        ? (_isIncome ? 'Edit Income' : 'Edit Expense')
        : (_isIncome ? 'Add Income' : 'Add Expense');

    return PopScope(
      canPop: !_submit.isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _submit.isBusy
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: _categoriesLoading
              ? const LoadingView(message: 'Loading categories…')
              : _categoriesError != null
                  ? ErrorView(message: _categoriesError!, onRetry: _loadCategories)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.pagePadding, 8, AppConstants.pagePadding, 40,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                              ),
                              child: TextFormField(
                                controller: _amount,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  prefixText: '฿ ',
                                  prefixStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                validator: (v) {
                                  final err = Validators.amount(v);
                                  if (err != null) return err;
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Category',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((c) {
                                final selected = c.name == _selectedCategory;
                                return ChoiceChip(
                                  label: Text(c.name),
                                  avatar: Icon(
                                    CategoryIcons.from(c.icon),
                                    size: 18,
                                    color: selected
                                        ? Colors.white
                                        : _accent,
                                  ),
                                  selected: selected,
                                  selectedColor: _accent,
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  backgroundColor: AppColors.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: selected ? _accent : AppColors.divider,
                                    ),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = c.name),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Date',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusS),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius:
                                      BorderRadius.circular(AppConstants.radiusS),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      Formatters.formatDate(Formatters.apiDate(_date)),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Note',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _description,
                              maxLines: 3,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                hintText: 'Add a short description (optional)',
                              ),
                            ),
                            if (_submit.error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _submit.error!,
                                style: const TextStyle(
                                    color: AppColors.expenseRed, fontSize: 13.5),
                              ),
                            ],
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: _submit.isBusy ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                              ),
                              child: _submit.isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(widget.isEdit ? 'Update' : 'Save'),
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