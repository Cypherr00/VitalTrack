class HealthThreshold {
  final String id;
  final String? userId;
  final double minSpo2;
  final int minHr;
  final int maxHr;
  final double maxTemp;
  final DateTime updatedAt;

  HealthThreshold({
    required this.id,
    this.userId,
    this.minSpo2 = 94.00,
    this.minHr = 50,
    this.maxHr = 120,
    this.maxTemp = 37.8,
    required this.updatedAt,
  });

  factory HealthThreshold.fromJson(Map<String, dynamic> json) {
    int parsedMinHr = 50;
    int parsedMaxHr = 120;

    // Supports column name 'minhr_max_hr' (e.g. integer or string or range)
    // as well as separate 'min_hr' and 'max_hr'
    if (json['min_hr'] != null) {
      parsedMinHr = (json['min_hr'] as num).toInt();
    }
    if (json['max_hr'] != null) {
      parsedMaxHr = (json['max_hr'] as num).toInt();
    } else if (json['minhr_max_hr'] != null) {
      // If minhr_max_hr is stored as string like "50-120" or numeric
      final val = json['minhr_max_hr'];
      if (val is num) {
        parsedMaxHr = val.toInt();
      } else if (val is String && val.contains('-')) {
        final parts = val.split('-');
        if (parts.length == 2) {
          parsedMinHr = int.tryParse(parts[0].trim()) ?? 50;
          parsedMaxHr = int.tryParse(parts[1].trim()) ?? 120;
        }
      }
    }

    return HealthThreshold(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      minSpo2: (json['min_spo2'] as num?)?.toDouble() ?? 94.00,
      minHr: parsedMinHr,
      maxHr: parsedMaxHr,
      maxTemp: (json['max_temp'] as num?)?.toDouble() ?? 37.8,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'min_spo2': minSpo2,
      'min_hr': minHr,
      'max_hr': maxHr,
      'max_temp': maxTemp,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
