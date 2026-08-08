import 'package:flutter/material.dart';

import '../models/transaction.dart';
import 'add_transaction_screen.dart';

/// Add / edit an expense transaction (red/orange accent, type = "expense").
class AddExpenseScreen extends StatelessWidget {
  final Transaction? transaction;

  const AddExpenseScreen({super.key, this.transaction});

  @override
  Widget build(BuildContext context) => AddTransactionScreen(
        type: TransactionType.expense,
        existing: transaction,
      );
}