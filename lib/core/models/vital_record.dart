class VitalRecord {
  final String id;
  final String userId;
  final double temperature;
  final double spo2;
  final int heartRate;
  final bool isNormal;
  final DateTime recordedAt;

  VitalRecord({
    required this.id,
    required this.userId,
    required this.temperature,
    required this.spo2,
    required this.heartRate,
    this.isNormal = true,
    required this.recordedAt,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    // Supports both 'is_normal' and legacy 'is_abnormal'
    bool normal = true;
    if (json.containsKey('is_normal') && json['is_normal'] != null) {
      normal = json['is_normal'] as bool;
    } else if (json.containsKey('is_abnormal') && json['is_abnormal'] != null) {
      normal = !(json['is_abnormal'] as bool);
    }

    return VitalRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      spo2: (json['spo2'] as num?)?.toDouble() ?? 0.0,
      heartRate: (json['heart_rate'] as num?)?.toInt() ?? 0,
      isNormal: normal,
      recordedAt: _parseDateTime(json['recorded_at']),
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
      'user_id': userId,
      'temperature': temperature,
      'spo2': spo2,
      'heart_rate': heartRate,
      'is_normal': isNormal,
    };
  }
}
