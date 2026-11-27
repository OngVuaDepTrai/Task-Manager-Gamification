import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://uehiygjnksniazrdvlol.supabase.co';
  static const String anonKey =
      'sb_publishable_T1-m50Q98HODkxH6hGFX-Q_9lVd2L6O';

  static SupabaseClient get client => Supabase.instance.client;
}
