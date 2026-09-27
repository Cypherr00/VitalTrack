// ─────────────────────────────────────────────────────────────────────────────
// secrets.example.dart  —  SAFE TEMPLATE committed to git
// ─────────────────────────────────────────────────────────────────────────────
// To set up locally:
//   1. Copy this file and rename it to:  secrets.dart
//   2. Fill in your real Supabase credentials below.
//   3. Never commit secrets.dart  (it is already listed in .gitignore).
//
// Find your credentials at:
//   Supabase Dashboard → Project Settings → API
// ─────────────────────────────────────────────────────────────────────────────

const String kSupabaseUrl = 'YOUR_SUPABASE_URL';
// e.g. 'https://abcdefghijklmnop.supabase.co'

const String kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
// starts with 'eyJhbGciOiJI...'
// Use the 'anon' 'public' key — NOT the service_role key.
