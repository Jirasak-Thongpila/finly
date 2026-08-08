import 'package:flutter/material.dart';

import '../models/transaction.dart';
import 'add_transaction_screen.dart';

/// Add / edit an income transaction (green accent, type = "income").
class AddIncomeScreen extends StatelessWidget {
  final Transaction? transaction;

  const AddIncomeScreen({super.key, this.transaction});

  @override
  Widget build(BuildContext context) => AddTransactionScreen(
        type: TransactionType.income,
        existing: transaction,
      );
}