import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:finly/models/transaction.dart';
import 'package:finly/screens/add_transaction_screen.dart';
import 'package:finly/services/session_manager.dart';
import 'package:finly/utils/storage.dart';

void main() {
  testWidgets('AddTransactionScreen in edit mode shows delete button and confirmation dialog', (WidgetTester tester) async {
    final storage = MemoryTokenStorage();
    await storage.writeToken('mock-token');
    final session = SessionManager(storage: storage);
    await session.restore();

    final testTransaction = Transaction(
      id: 'tx_123',
      userId: 'usr_1',
      type: TransactionType.expense,
      amount: 150.0,
      category: 'Food',
      description: 'Lunch at cafe',
      date: '2026-08-12',
      createdAt: '2026-08-12T10:00:00Z',
      updatedAt: '2026-08-12T10:00:00Z',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionManager>.value(
        value: session,
        child: MaterialApp(
          home: AddTransactionScreen(
            type: TransactionType.expense,
            existing: testTransaction,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Edit title and Delete icon button in AppBar exist
    expect(find.text('แก้ไขรายจ่าย'), findsOneWidget);
    expect(find.byTooltip('ลบรายการ'), findsOneWidget);

    // Tap Delete button in AppBar
    await tester.tap(find.byTooltip('ลบรายการ'));
    await tester.pumpAndSettle();

    // Verify Confirmation dialog appears with title and transaction name
    expect(find.text('ยืนยันการลบรายการ?'), findsOneWidget);
    expect(find.text('คุณต้องการลบรายการ "Lunch at cafe" ใช่หรือไม่?'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('ลบรายการ'), findsWidgets);

    // Tap cancel
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    // Verify dialog dismissed and edit screen is still active
    expect(find.text('ยืนยันการลบรายการ?'), findsNothing);
    expect(find.text('แก้ไขรายจ่าย'), findsOneWidget);
  });
}
