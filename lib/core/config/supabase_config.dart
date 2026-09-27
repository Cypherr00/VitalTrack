import 'secrets.dart';

/// Supabase Configuration
///
/// ⚠  Do NOT paste your credentials directly here.
///    Instead, open  lib/core/config/secrets.dart  and fill in the values there.
///    That file is gitignored and stays local to your machine.
///
///    If secrets.dart doesn't exist yet:
///      Copy secrets.example.dart → secrets.dart  and fill in your values.
class SupabaseConfig {
  /// Your Supabase Project URL — set in secrets.dart
  static const String supabaseUrl = kSupabaseUrl;

  /// Your Supabase Anon (public) Key — set in secrets.dart
  static const String supabaseAnonKey = kSupabaseAnonKey;

  /// Helper flag to check if credentials have been filled in
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
