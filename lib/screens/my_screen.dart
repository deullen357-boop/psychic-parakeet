import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/badge_store.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _total = 0;
  Map<String, int> _counts = {
    'logical': 0,
    'evidence': 0,
    'new_perspective': 0,
    'aggressive': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final total = await BadgeStore.totalScoreForUser(user.id);
    final counts = await BadgeStore.countsForUser(user.id);
    setState(() {
      _total = total;
      _counts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 16),
                    const Text('마이페이지',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _total >= 0
                              ? [
                                  const Color(0xFFE7F8DC),
                                  const Color(0xFFC9F09F),
                                ]
                              : [
                                  const Color(0xFFFFE2E2),
                                  const Color(0xFFFFB3B3),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 점수',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.6)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_total > 0 ? '+' : ''}$_total점',
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('획득한 배지',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _badgeRow('완전 논리적이에요', _counts['logical']!, 15, false),
                    _badgeRow('근거 자료 보충', _counts['evidence']!, 10, false),
                    _badgeRow(
                        '새로운 관점이네요', _counts['new_perspective']!, 10, false),
                    const SizedBox(height: 16),
                    const Text('받은 벌점',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _badgeRow(
                        '공격적 표현을 사용했어요', _counts['aggressive']!, -20, true),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _badgeRow(String label, int count, int per, bool isBad) {
    final bg = isBad ? const Color(0xFFFFE2E2) : const Color(0xFFE7F8DC);
    final fg = isBad ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isBad ? Icons.warning_rounded : Icons.check_circle, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
          ),
          Text('$count회',
              style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(
            '${per > 0 ? '+' : ''}${per * count}점',
            style: TextStyle(color: fg, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
