class UserProfile {
  final String id;
  final String? userAccessId;
  final String fullName;
  final String email;
  final String? password;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.userAccessId,
    required this.fullName,
    required this.email,
    this.password,
    required this.createdAt,
  });

  /// 6-digit access code from the 'user_access_id' column in the 'users' table.
  /// Falls back to deriving a 6-character code from the UUID if user_access_id is not set.
  String get displayId {
    if (userAccessId != null && userAccessId!.trim().isNotEmpty) {
      return userAccessId!.trim();
    }
    final clean = id.replaceAll('-', '');
    if (clean.length >= 6) {
      return clean.substring(0, 6).toUpperCase();
    }
    return id.padLeft(6, '0');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      userAccessId: json['user_access_id']?.toString(),
      fullName: json['full_name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  /// Safely parses a Supabase timestamp that may arrive as a String, DateTime,
  /// int (epoch ms), or double (epoch ms as a float).
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userAccessId != null) 'user_access_id': userAccessId,
      'full_name': fullName,
      'email': email,
      if (password != null) 'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
