import 'transaction.dart';

/// Category model matching `GET /api/categories` items.
class Category {
  final String id;
  final String name;
  final String icon; // material icon name, see CategoryIcons in constants

  const Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? 'category',
      );
}

/// Categories grouped by transaction type.
class CategoryGroup {
  final List<Category> income;
  final List<Category> expense;

  const CategoryGroup({required this.income, required this.expense});

  List<Category> forType(String type) =>
      type == TransactionType.income ? income : expense;

  factory CategoryGroup.fromJson(Map<String, dynamic> json) => CategoryGroup(
        income: _parse(json['income']),
        expense: _parse(json['expense']),
      );

  static List<Category> _parse(dynamic list) => (list as List? ?? [])
      .map((e) => Category.fromJson((e as Map?)?.cast<String, dynamic>() ?? {}))
      .toList();
}