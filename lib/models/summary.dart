/// Summary totals returned by `GET /api/transactions` and `GET /api/reports/summary`.
class Summary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const Summary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  static const Summary empty = Summary(
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
  );

  factory Summary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Summary.empty;
    return Summary(
      totalIncome: _toDouble(json['totalIncome']),
      totalExpense: _toDouble(json['totalExpense']),
      balance: _toDouble(json['balance']),
    );
  }

  static double _toDouble(dynamic v) => v is num
      ? v.toDouble()
      : double.tryParse(v?.toString() ?? '') ?? 0;
}

/// Pagination metadata from `GET /api/transactions`.
class Pagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Pagination(page: 1, limit: 50, totalItems: 0, totalPages: 0);
    return Pagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One entry of `categoryBreakdown` from `GET /api/reports/summary`.
class CategoryBreakdown {
  final String category;
  final String type;
  final double total;
  final int count;

  const CategoryBreakdown({
    required this.category,
    required this.type,
    required this.total,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdown(
        category: json['category']?.toString() ?? '',
        type: json['type']?.toString() ?? 'expense',
        total: json['total'] is num
            ? (json['total'] as num).toDouble()
            : double.tryParse(json['total']?.toString() ?? '') ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// Full monthly report from `GET /api/reports/summary`.
class ReportSummary {
  final String month; // "all" or "YYYY-MM"
  final Summary summary;
  final List<CategoryBreakdown> categoryBreakdown;

  const ReportSummary({
    required this.month,
    required this.summary,
    required this.categoryBreakdown,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        month: json['month']?.toString() ?? 'all',
        summary: Summary.fromJson(
            (json['summary'] as Map?)?.cast<String, dynamic>()),
        categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
            .map((e) => CategoryBreakdown.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );
}