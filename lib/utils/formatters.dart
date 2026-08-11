import 'package:intl/intl.dart';

/// Formatting helpers used across the app.
class Formatters {
  Formatters._();

  static final NumberFormat _baht = NumberFormat.currency(
    locale: 'en_US',
    symbol: '฿',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _month = DateFormat('MMMM yyyy');
  static final DateFormat _monthKey = DateFormat('yyyy-MM');

  static String money(num value) => _baht.format(value);

  /// Parses `YYYY-MM-DD` API date strings into a [DateTime].
  static DateTime parseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return DateTime.now();
    }
  }

  static String formatDate(String date) => _date.format(parseDate(date));

  static String formatMonth(DateTime date) => _month.format(date);

  /// `YYYY-MM` key for `GET /api/reports/summary?month=`.
  static String monthKey(DateTime date) => _monthKey.format(date);

  static String todayKey() => _monthKey.format(DateTime.now());

  static String apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Simple client-side validators used before hitting the API.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'กรุณากรอกอีเมล';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return 'กรุณากรอก $field ';
    return null;
  }

  static String? password(String? value, {bool confirm = false}) {
    final v = value ?? '';
    final label = confirm ? 'รหัสผ่านอีกครั้ง' : 'รหัสผ่าน';
    if (v.isEmpty) return 'กรุณากรอก$label';
    if (!confirm && v.length < 6) return 'กรุณากรอกให้ครบ 6 ตัวอักษร';
    return null;
  }

  /// Returns trimmed amount or null when invalid/empty.
  static String? amount(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Please enter a valid amount';
    return null;
  }
}