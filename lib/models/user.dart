/// User model matching `user` objects returned by the auth endpoints.
class User {
  final String id;
  final String fname;
  final String lname;
  final String email;
  final String? createdAt;

  const User({
    required this.id,
    required this.fname,
    required this.lname,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        fname: json['fname']?.toString() ?? '',
        lname: json['lname']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        createdAt: json['created_at']?.toString(),
      );

  String get fullName => '$fname $lname'.trim();

  /// Initials used for the avatar fallback.
  String get initials {
    final parts = [fname, lname].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fname': fname,
        'lname': lname,
        'email': email,
        'created_at': createdAt,
      };
}