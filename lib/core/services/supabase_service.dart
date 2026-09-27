import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/health_threshold.dart';
import '../models/vital_record.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isReady => client != null;

  /// Fetch user profile from 'users' table
  Future<UserProfile?> fetchUserProfile([String? userId]) async {
    final cli = client;
    if (cli == null) return null;
    try {
      if (userId != null && userId.isNotEmpty) {
        final data = await cli
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (data != null) return UserProfile.fromJson(data);
      }
      // If no specific userId, fetch the first available user in the table
      final List<dynamic> allUsers = await cli
          .from('users')
          .select()
          .order('created_at', ascending: true)
          .limit(1);
      if (allUsers.isNotEmpty) {
        return UserProfile.fromJson(allUsers.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Login with email and password from 'users' table
  Future<UserProfile?> loginUser(String email, String password) async {
    final cli = client;
    if (cli == null) {
      throw Exception('Supabase is not configured yet. Please enter your project credentials in supabase_config.dart.');
    }
    try {
      final data = await cli
          .from('users')
          .select()
          .eq('email', email.trim().toLowerCase())
          .eq('password', password)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('Error logging in user: $e');
      rethrow;
    }
  }

  /// Register a new user in 'users' table
  Future<UserProfile> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cli = client;
    if (cli == null) {
      throw Exception('Supabase is not configured yet. Please enter your project credentials in supabase_config.dart.');
    }
    final normalizedEmail = email.trim().toLowerCase();

    // Check if email already exists
    final existing = await cli
        .from('users')
        .select('id')
        .eq('email', normalizedEmail)
        .maybeSingle();

    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    // Insert user
    final inserted = await cli.from('users').insert({
      'full_name': fullName.trim(),
      'email': normalizedEmail,
      'password': password,
    }).select().single();

    final user = UserProfile.fromJson(inserted);

    // Attempt to seed default thresholds for this user
    try {
      await cli.from('health_thresholds').insert({
        'user_id': user.id,
        'min_spo2': 94.00,
        'min_hr': 50,
        'max_hr': 120,
        'max_temp': 37.8,
      });
    } catch (e) {
      debugPrint('Default threshold notice: $e');
    }

    return user;
  }

  /// Fetch health thresholds for user from 'health_thresholds' table
  Future<HealthThreshold?> fetchThresholds([String? userId]) async {
    final cli = client;
    if (cli == null) return null;
    try {
      if (userId != null && userId.isNotEmpty) {
        final data = await cli
            .from('health_thresholds')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (data != null) return HealthThreshold.fromJson(data);
      }
      // Fallback: fetch the general/first threshold definition
      final List<dynamic> list = await cli
          .from('health_thresholds')
          .select()
          .limit(1);
      if (list.isNotEmpty) {
        return HealthThreshold.fromJson(list.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching health thresholds: $e');
      return null;
    }
  }

  /// Fetch the latest vital scan record from 'records' table
  Future<VitalRecord?> fetchLatestRecord([String? userId]) async {
    final cli = client;
    if (cli == null) return null;
    try {
      var query = cli.from('records').select();
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      final data = await query
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return VitalRecord.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching latest record: $e');
      return null;
    }
  }

  /// Fetch historical scan records from 'records' table
  Future<List<VitalRecord>> fetchHistory([String? userId, int limit = 50]) async {
    final cli = client;
    if (cli == null) return [];
    try {
      var query = cli.from('records').select();
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      final List<dynamic> data = await query
          .order('recorded_at', ascending: false)
          .limit(limit);
      return data.map((item) => VitalRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching records history: $e');
      return [];
    }
  }

  /// Listen to real-time records updates as ESP device inserts them
  Stream<List<VitalRecord>> streamRecentRecords([String? userId, int limit = 20]) {
    final cli = client;
    if (cli == null) return const Stream.empty();
    try {
      final SupabaseStreamBuilder stream = (userId != null && userId.isNotEmpty)
          ? cli.from('records').stream(primaryKey: ['id']).eq('user_id', userId)
          : cli.from('records').stream(primaryKey: ['id']);

      return stream
          .order('recorded_at', ascending: false)
          .limit(limit)
          .map((maps) => maps.map((m) => VitalRecord.fromJson(m)).toList());
    } catch (e) {
      debugPrint('Error in streamRecentRecords: $e');
      return const Stream.empty();
    }
  }

  /// Insert a newly scanned record into 'records' table
  Future<VitalRecord?> insertRecord({
    required String userId,
    required double temperature,
    required double spo2,
    required int heartRate,
    bool isNormal = true,
  }) async {
    final cli = client;
    if (cli == null) return null;
    try {
      final data = await cli.from('records').insert({
        'user_id': userId,
        'temperature': temperature,
        'spo2': spo2,
        'heart_rate': heartRate,
        'is_normal': isNormal,
      }).select().single();
      return VitalRecord.fromJson(data);
    } catch (e) {
      debugPrint('Error inserting record: $e');
      return null;
    }
  }
}
