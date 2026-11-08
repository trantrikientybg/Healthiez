import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhysicalStore {
  PhysicalStore(this.client, this.userId);

  final SupabaseClient client;
  final String userId;
  static const table = 'physical_health_records';
  Future<String>? _deviceId;

  void _checkUser() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('The signed-in account changed');
    }
  }

  Future<String> _device(String kind) async {
    if (kind == 'physical') return '';
    try {
      return await (_deviceId ??= () async {
        final preferences = await SharedPreferences.getInstance();
        const key = 'healthiez.steps.device';
        final existing = preferences.getString(key);
        if (existing != null) return existing;
        final random = Random.secure();
        final id = List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        if (!await preferences.setString(key, id)) {
          throw StateError('Cannot persist step device identifier');
        }
        return id;
      }());
    } catch (_) {
      _deviceId = null;
      rethrow;
    }
  }

  Future<String?> read(String kind) async {
    _checkUser();
    final device = await _device(kind);
    _checkUser();
    final row = await client
        .from(table)
        .select('payload')
        .eq('user_id', userId)
        .eq('kind', kind)
        .eq('device_id', device)
        .maybeSingle();
    _checkUser();
    return row == null ? null : jsonEncode(row['payload']);
  }

  Future<bool> write(String kind, String value) async {
    _checkUser();
    final payload = jsonDecode(value) as Map<String, dynamic>;
    final device = await _device(kind);
    _checkUser();
    // shortcut: last snapshot wins across devices; use atomic events for concurrent edits.
    await client.from(table).upsert({
      'user_id': userId,
      'kind': kind,
      'device_id': device,
      'payload': payload,
    }, onConflict: 'user_id,kind,device_id');
    _checkUser();
    return true;
  }
}
