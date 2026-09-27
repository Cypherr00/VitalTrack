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
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
    );
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
