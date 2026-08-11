import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// A single transaction row matching the reference fintech design:
/// circular avatar (with initials or category icon), title, timestamp,
/// amount, and transaction status/type label.
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final titleText = transaction.description.isNotEmpty
        ? transaction.description
        : transaction.category;
    final amountColor = isIncome ? AppColors.income : AppColors.expenseRed;
    final amountPrefix = isIncome ? '+' : '-';
    final typeLabel = isIncome ? 'รายรับ' : 'รายจ่าย';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category Icon Container with soft pastel background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIncome
                      ? const Color(0xFFDCFCE7) // Soft Green background
                      : const Color(0xFFFEE2E2), // Soft Red background
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  CategoryIcons.from(transaction.category),
                  color: isIncome ? AppColors.income : AppColors.expenseRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Merchant / Category Title & Time Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatSubtitle(transaction),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Column: Amount & Status / Type Tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix${Formatters.money(transaction.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  String _formatSubtitle(Transaction t) {
    if (t.createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(t.createdAt).toLocal();
        final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $ampm';
      } catch (_) {}
    }
    return Formatters.formatDate(t.date);
  }
}