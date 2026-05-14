import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CommentBadge {
  final String? key; // logical | evidence | new_perspective | aggressive | null
  final int score;
  const CommentBadge({this.key, this.score = 0});

  static const CommentBadge none = CommentBadge();
}

class MinimaxService {
  static String get _apiKey => dotenv.env['MINIMAX_API_KEY'] ?? '';
  static String get _model => dotenv.env['MINIMAX_MODEL'] ?? 'MiniMax-M2.7';
  static String get _baseUrl =>
      dotenv.env['MINIMAX_BASE_URL'] ?? 'https://api.minimax.io/v1';

  static Future<CommentBadge> classify({
    required String newComment,
    required List<String> previousComments,
  }) async {
    if (_apiKey.isEmpty) return _fallback(newComment);

    final ctx = previousComments.isEmpty
        ? '(기존 댓글 없음)'
        : previousComments
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n');

    final allowNewPerspective = previousComments.length >= 3;

    final system = '''
당신은 토론 댓글 분류기입니다. 새 댓글을 다음 중 하나로만 분류하세요.

- "logical": 주장 + 이유/설명이 명확히 갖춰진 댓글
- "evidence": 명시적인 근거자료(링크, 출처, 통계 등)를 직접 제시한 댓글
- "new_perspective": 기존 댓글과 확연히 다른 새로운 의견 ${allowNewPerspective ? "(허용)" : "(이번 댓글에서는 절대 사용 금지: 기존 댓글이 부족함)"}
- "aggressive": 욕설/공격적 표현/혐오 표현이 포함된 댓글
- "none": 위 어디에도 해당하지 않을 때 (대부분의 평범한 의견)

엄격하게 판단하세요. 애매하면 "none"을 선택하세요.
응답은 반드시 다음 JSON 한 줄: {"badge":"<key>"}
''';

    final user = '기존 댓글:\n$ctx\n\n새 댓글:\n$newComment';

    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/text/chatcompletion_v2'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
              'temperature': 0.1,
              'max_tokens': 600,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        debugPrint('minimax HTTP ${resp.statusCode}: ${resp.body}');
        return _fallback(newComment);
      }
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final content =
          data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return _fallback(newComment);
      final m = RegExp(r'"badge"\s*:\s*"([a-z_]+)"').firstMatch(content);
      final picked = m?.group(1);
      if (picked == 'new_perspective' && !allowNewPerspective) {
        return CommentBadge.none;
      }
      return _scoreFor(picked);
    } catch (e) {
      debugPrint('minimax error: $e');
      return _fallback(newComment);
    }
  }

  static CommentBadge _scoreFor(String? badge) {
    switch (badge) {
      case 'logical':
        return const CommentBadge(key: 'logical', score: 15);
      case 'evidence':
        return const CommentBadge(key: 'evidence', score: 10);
      case 'new_perspective':
        return const CommentBadge(key: 'new_perspective', score: 10);
      case 'aggressive':
        return const CommentBadge(key: 'aggressive', score: -20);
      default:
        return CommentBadge.none;
    }
  }

  // API 호출 실패 시 분류 안 함 (룰베이스드 사용 안 함)
  static CommentBadge _fallback(String _) => CommentBadge.none;
}
