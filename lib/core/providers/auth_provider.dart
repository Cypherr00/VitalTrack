import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyUserId = 'vital_track_user_id';
  static const String _keyUserAccessId = 'vital_track_user_access_id';
  static const String _keyUserName = 'vital_track_user_name';
  static const String _keyUserEmail = 'vital_track_user_email';

  final SupabaseService _supabase = SupabaseService();

  UserProfile? _currentUser;
  bool _isLoading = true;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_keyUserId);

      if (savedId != null && savedId.isNotEmpty) {
        // Try fetching fresh data from Supabase if connected
        if (_supabase.isReady) {
          final profile = await _supabase.fetchUserProfile(savedId);
          if (profile != null) {
            _currentUser = profile;
          } else {
            // Restore from cached info
            final name = prefs.getString(_keyUserName) ?? 'User';
            final email = prefs.getString(_keyUserEmail) ?? '';
            final accessId = prefs.getString(_keyUserAccessId);
            _currentUser = UserProfile(
              id: savedId,
              userAccessId: accessId,
              fullName: name,
              email: email,
              createdAt: DateTime.now(),
            );
          }
        } else {
          // Restore from cache if Supabase credentials pending
          final name = prefs.getString(_keyUserName) ?? 'User';
          final email = prefs.getString(_keyUserEmail) ?? '';
          final accessId = prefs.getString(_keyUserAccessId);
          _currentUser = UserProfile(
            id: savedId,
            userAccessId: accessId,
            fullName: name,
            email: email,
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final user = await _supabase.loginUser(email, password);
    if (user == null) {
      throw Exception('Invalid email or password. Please check your credentials.');
    }

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.fullName);
    await prefs.setString(_keyUserEmail, user.email);
    if (user.userAccessId != null) {
      await prefs.setString(_keyUserAccessId, user.userAccessId!);
    }

    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _supabase.registerUser(
      fullName: fullName,
      email: email,
      password: password,
    );

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.fullName);
    await prefs.setString(_keyUserEmail, user.email);
    if (user.userAccessId != null) {
      await prefs.setString(_keyUserAccessId, user.userAccessId!);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserAccessId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);

    notifyListeners();
  }
}
