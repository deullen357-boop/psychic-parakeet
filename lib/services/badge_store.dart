import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeEntry {
  final String badge;
  final int score;
  final String userId;
  const BadgeEntry({required this.badge, required this.score, required this.userId});

  Map<String, dynamic> toJson() => {'badge': badge, 'score': score, 'userId': userId};
  static BadgeEntry fromJson(Map<String, dynamic> j) => BadgeEntry(
        badge: j['badge'] as String,
        score: (j['score'] as num).toInt(),
        userId: j['userId'] as String? ?? '',
      );
}

class BadgeStore {
  static const _key = 'comment_badges_v1';
  static Map<String, BadgeEntry>? _cache;

  static Future<Map<String, BadgeEntry>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = {};
      return _cache!;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _cache = m.map((k, v) => MapEntry(k, BadgeEntry.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = _cache ?? {};
    await prefs.setString(_key, jsonEncode(cache.map((k, v) => MapEntry(k, v.toJson()))));
  }

  static Future<void> save({
    required int commentId,
    required String badge,
    required int score,
    required String userId,
  }) async {
    final m = await _load();
    m[commentId.toString()] = BadgeEntry(badge: badge, score: score, userId: userId);
    await _persist();
  }

  static Future<BadgeEntry?> get(int commentId) async {
    final m = await _load();
    return m[commentId.toString()];
  }

  static Future<Map<String, BadgeEntry>> all() async => Map.of(await _load());

  static Future<int> totalScoreForUser(String userId) async {
    final m = await _load();
    return m.values.where((e) => e.userId == userId).fold<int>(0, (a, b) => a + b.score);
  }

  static Future<Map<String, int>> countsForUser(String userId) async {
    final m = await _load();
    final counts = <String, int>{
      'logical': 0,
      'evidence': 0,
      'new_perspective': 0,
      'aggressive': 0,
    };
    for (final e in m.values.where((e) => e.userId == userId)) {
      if (counts.containsKey(e.badge)) counts[e.badge] = counts[e.badge]! + 1;
    }
    return counts;
  }
}
