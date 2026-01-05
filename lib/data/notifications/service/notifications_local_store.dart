import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final class NotificationsLocalStore {
  static const _keyReadIds = 'notifications_read_ids_v1';

  Future<Set<int>> loadReadIds() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_keyReadIds);
    if (raw == null || raw.isEmpty) return <int>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>{};
      return decoded
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  Future<void> saveReadIds(Set<int> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyReadIds, jsonEncode(ids.toList()));
  }

  Future<void> addReadId(int id) async {
    final ids = await loadReadIds();
    if (ids.add(id)) {
      await saveReadIds(ids);
    }
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyReadIds);
  }
}
