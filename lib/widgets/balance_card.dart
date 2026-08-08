import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Continuous gradient card showing balance, total income and total expense.
class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFCA5A5);
    final balancePrefix = isPositive ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16251C), Color(0xFF0F172A)], // Deep Charcoal Navy Gradient
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยอดเงินคงเหลือรวม',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 6),
          Text(
            '$balancePrefix${Formatters.money(balance.abs())}',
            style: TextStyle(
              color: balanceColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'รายรับ (+)',
                  value: '+${Formatters.money(totalIncome)}',
                  valueColor: const Color(0xFF4ADE80), // Vibrant Green
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white24,
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'รายจ่าย (-)',
                  value: '-${Formatters.money(totalExpense)}',
                  valueColor: const Color(0xFFF87171), // Vibrant Red
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Icon(icon, color: valueColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}