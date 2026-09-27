class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? password;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.password,
    required this.createdAt,
  });

  /// Short 6-digit display code derived from the UUID (or first 6 chars)
  String get displayId {
    final clean = id.replaceAll('-', '');
    if (clean.length >= 6) {
      return clean.substring(0, 6).toUpperCase();
    }
    return id.padLeft(6, '0');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      password: json['password'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      if (password != null) 'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
