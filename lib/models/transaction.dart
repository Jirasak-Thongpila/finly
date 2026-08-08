/// Transaction type strings used by the API.
class TransactionType {
  TransactionType._();

  static const String income = 'income';
  static const String expense = 'expense';

  static bool isIncome(String? type) => type == income;
}

/// Transaction model matching `GET /api/transactions` & `POST /api/transactions`.
///
/// Note: the backend returns `amount` either as a number or a string
/// (`"5000.00"`), so parsing is lenient on both.
class Transaction {
  final String id;
  final String userId;
  final String type; // "income" | "expense"
  final double amount;
  final String category;
  final String description;
  final String date; // YYYY-MM-DD
  final String createdAt;
  final String updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => TransactionType.isIncome(type);

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'expense',
        amount: _toDouble(json['amount']),
        category: json['category']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
      );

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}