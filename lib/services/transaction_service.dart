import 'dart:convert';

import '../models/category.dart';
import '../models/transaction.dart';
import '../models/summary.dart';
import 'api_client.dart';

/// Transaction / category / report endpoints.
class TransactionService {
  TransactionService._();

  /// `GET /api/transactions` — list with optional filters.
  static Future<TransactionPage> list({
    required String token,
    String? type,
    String? startDate,
    String? endDate,
    String? category,
    int? page,
    int? limit,
  }) async {
    final data = await ApiClient.get(
      '/transactions',
      token: token,
      query: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (category != null && category.isNotEmpty) 'category': category,
        if (page != null && page > 0) 'page': '$page',
        if (limit != null && limit > 0) 'limit': '$limit',
      },
    );
    return TransactionPage.fromJson(data);
  }

  /// `POST /api/transactions`.
  static Future<Transaction> create({
    required String token,
    required String type,
    required double amount,
    required String category,
    String? description,
    String? date,
  }) async {
    final data = await ApiClient.post(
      '/transactions',
      token: token,
      body: {
        'type': type,
        'amount': amount,
        'category': category,
        'description': description ?? '',
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    return Transaction.fromJson(
        (data['transaction'] as Map? ?? {}).cast<String, dynamic>());
  }

  /// `PUT /api/transactions/:id`.
  static Future<Transaction> update({
    required String token,
    required String id,
    required String type,
    required double amount,
    required String category,
    String? description,
    String? date,
  }) async {
    final data = await ApiClient.put(
      '/transactions/$id',
      token: token,
      body: {
        'type': type,
        'amount': amount,
        'category': category,
        'description': description ?? '',
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    return Transaction.fromJson(
        (data['transaction'] as Map? ?? {}).cast<String, dynamic>());
  }

  /// `DELETE /api/transactions/:id`.
  static Future<void> delete({required String token, required String id}) async {
    await ApiClient.delete('/transactions/$id', token: token);
  }

  /// `GET /api/categories`.
  static Future<CategoryGroup> categories() async {
    final data = await ApiClient.get('/categories');
    return CategoryGroup.fromJson((data as Map).cast<String, dynamic>());
  }

  /// `GET /api/reports/summary?month=YYYY-MM`.
  static Future<ReportSummary> report({
    required String token,
    String? month,
  }) async {
    final data = await ApiClient.get(
      '/reports/summary',
      token: token,
      query: {if (month != null && month.isNotEmpty) 'month': month},
    );
    return ReportSummary.fromJson((data as Map).cast<String, dynamic>());
  }
}

/// Result of `GET /api/transactions`.
class TransactionPage {
  final Summary summary;
  final Pagination pagination;
  final List<Transaction> transactions;

  const TransactionPage({
    required this.summary,
    required this.pagination,
    required this.transactions,
  });

  factory TransactionPage.fromJson(Map<String, dynamic> json) => TransactionPage(
        summary: Summary.fromJson(
            (json['summary'] as Map?)?.cast<String, dynamic>()),
        pagination: Pagination.fromJson(
            (json['pagination'] as Map?)?.cast<String, dynamic>()),
        transactions: (json['transactions'] as List? ?? [])
            .map((e) => Transaction.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// Conversation helpers for the JSON user cache (safe decoded, since the
/// secure storage layer handles encryption).
class JsonCodec {
  JsonCodec._();

  static String encode(Map<String, dynamic> map) => jsonEncode(map);

  static Map<String, dynamic> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return (decoded as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }
}