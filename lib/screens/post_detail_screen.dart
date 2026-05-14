import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_write_screen.dart';
import '../services/minimax_service.dart';
import '../services/badge_store.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final GlobalKey _menuKey = GlobalKey();
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likesCount = 0;
  int _bookmarksCount = 0;
  int _commentsCount = 0;
  bool _isNotiOn = false;
  int? _replyToCommentId; // 답글 대상 댓글 id
  String? _replyToEmail; // 답글 대상 이메일
  int? _highlightedCommentId; // 초록 배경 줄 댓글 id

  List<Map<String, dynamic>> _commentLikes = [];
  final Map<String, int> _anonMap = {};
  Map<String, BadgeEntry> _badges = {};

  final FocusNode _commentFocusNode = FocusNode();

  String _anonLabel(dynamic userId) {
    if (userId == null) return '익명';
    final key = userId.toString();
    if (!_anonMap.containsKey(key)) {
      _anonMap[key] = _anonMap.length + 1;
    }
    return '익명${_anonMap[key]}';
  }

  void _rebuildAnonMap() {
    _anonMap.clear();
    final sorted = [..._comments]
      ..sort((a, b) => (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString()));
    for (final c in sorted) {
      _anonLabel(c['user_id']);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  String formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final date = DateTime.parse(isoTime);

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}/$month/$day $hour:$minute';
  }

  String timeAgo(String createdAt) {
  final now = DateTime.now();
  final post = DateTime.parse(createdAt).toLocal();
  final diff = now.difference(post);

  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 30) return '${diff.inDays}일 전';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
  return '${diff.inDays ~/ 365}년 전';
}

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // ignore: avoid_print
      print('[fetch] step=user');
      final user = Supabase.instance.client.auth.currentUser;

      // ignore: avoid_print
      print('[fetch] step=post id=${widget.postId}');
      final post = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('id', widget.postId)
          .single();

      // ignore: avoid_print
      print('[fetch] step=comments');
      final comments = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      // ignore: avoid_print
      print('[fetch] step=update views');
      await Supabase.instance.client
          .from('posts')
          .update({'views': (post['views'] ?? 0) + 1})
          .eq('id', widget.postId);

      // ignore: avoid_print
      print('[fetch] step=likes');
      final likes = await Supabase.instance.client
          .from('post_likes')
          .select()
          .eq('post_id', widget.postId);

      // ignore: avoid_print
      print('[fetch] step=bookmarks');
      final bookmarks = await Supabase.instance.client
          .from('post_bookmarks')
          .select()
          .eq('post_id', widget.postId);

      List myLike = [];
      List myBookmark = [];
      if (user != null) {
        myLike = await Supabase.instance.client
            .from('post_likes')
            .select()
            .eq('post_id', widget.postId)
            .eq('user_id', user.id);

        myBookmark = await Supabase.instance.client
            .from('post_bookmarks')
            .select()
            .eq('post_id', widget.postId)
            .eq('user_id', user.id);
      }

      final commentIds = (comments as List)
          .map((c) => c['id'])
          .whereType<int>()
          .toList();
      List commentLikes = [];
      if (commentIds.isNotEmpty) {
        commentLikes = await Supabase.instance.client
            .from('comment_likes')
            .select()
            .inFilter('comment_id', commentIds);
      }

      final badges = await BadgeStore.all();
      setState(() {
        _post = {...post, 'views': (post['views'] ?? 0) + 1};
        _commentLikes = List<Map<String, dynamic>>.from(commentLikes);
        _comments = List<Map<String, dynamic>>.from(comments);
        _likesCount = (likes as List).length;
        _bookmarksCount = (bookmarks as List).length;
        _commentsCount = (comments as List).length;
        _isLiked = myLike.isNotEmpty;
        _isBookmarked = myBookmark.isNotEmpty;
        _badges = badges;
        _rebuildAnonMap();
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('=== fetchData ERROR ===');
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(st);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_isLiked) {
      await Supabase.instance.client
          .from('post_likes')
          .delete()
          .eq('post_id', widget.postId)
          .eq('user_id', user.id);
      setState(() {
        _isLiked = false;
        _likesCount--;
      });
    } else {
      await Supabase.instance.client.from('post_likes').insert({
        'post_id': widget.postId,
        'user_id': user.id,
      });
      setState(() {
        _isLiked = true;
        _likesCount++;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_isBookmarked) {
      await Supabase.instance.client
          .from('post_bookmarks')
          .delete()
          .eq('post_id', widget.postId)
          .eq('user_id', user.id);
      setState(() {
        _isBookmarked = false;
        _bookmarksCount--;
      });
    } else {
      await Supabase.instance.client.from('post_bookmarks').insert({
        'post_id': widget.postId,
        'user_id': user.id,
      });
      setState(() {
        _isBookmarked = true;
        _bookmarksCount++;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final text = _commentController.text.trim();

    final inserted = await Supabase.instance.client
        .from('comments')
        .insert({
          'post_id': widget.postId,
          'content': text,
          'email': user?.email ?? '익명',
          'user_id': user?.id,
          'parent_id': _replyToCommentId,
        })
        .select()
        .single();

    _commentController.clear();
    setState(() {
      _replyToCommentId = null;
      _replyToEmail = null;
      _highlightedCommentId = null;
    });
    _fetchData(); // 댓글 즉시 표시

    // AI 분류는 백그라운드 — 결과 나오면 배지/점수 저장 + 다시 새로고침
    final previous = _comments
        .map((c) => (c['content'] ?? '').toString())
        .toList();
    final commentId = inserted['id'] as int;
    final userId = user?.id ?? '';
    () async {
      try {
        final badge = await MinimaxService.classify(
          newComment: text,
          previousComments: previous,
        );
        debugPrint('[badge] result: key=${badge.key} score=${badge.score}');
        if (badge.key == null) return;
        await BadgeStore.save(
          commentId: commentId,
          badge: badge.key!,
          score: badge.score,
          userId: userId,
        );
        if (mounted) _fetchData();
      } catch (e) {
        debugPrint('[badge] error: $e');
      }
    }();
  }

  Widget _badgeChip(Map<String, dynamic> comment) {
    final entry = _badges[(comment['id']).toString()];
    if (entry == null) return const SizedBox.shrink();
    final key = entry.badge;
    if (key == 'none') return const SizedBox.shrink();
    final score = entry.score;
    final isBad = key == 'aggressive';
    final bg = isBad ? const Color(0xFFFFE2E2) : const Color(0xFFE7F8DC);
    final fg = isBad ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
    String label;
    switch (key) {
      case 'logical':
        label = '완전 논리적이에요!';
        break;
      case 'evidence':
        label = '근거 자료 보충!';
        break;
      case 'new_perspective':
        label = '새로운 관점이네요!';
        break;
      case 'aggressive':
        label = '공격적 표현을 사용했어요!';
        break;
      default:
        return const SizedBox.shrink();
    }
    final scoreStr = score > 0 ? '+$score' : '$score';
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label $scoreStr',
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(isBad ? Icons.warning_rounded : Icons.check_circle,
                color: fg, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCommentLike(int commentId, bool isLike) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final existing = _commentLikes.where((l) =>
      l['comment_id'] == commentId && l['user_id'] == user.id).toList();

    if (existing.isNotEmpty) {
      if (existing.first['is_like'] == isLike) {
        // 같은 버튼 다시 누르면 취소
        await Supabase.instance.client
            .from('comment_likes')
            .delete()
            .eq('id', existing.first['id']);
      } else {
        // 반대 버튼 누르면 변경
        await Supabase.instance.client
            .from('comment_likes')
            .update({'is_like': isLike})
            .eq('id', existing.first['id']);
      }
    } else {
      await Supabase.instance.client.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': user.id,
        'is_like': isLike,
      });
    }
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _post?['category'] ?? '일반',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // 글 본문 영역
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 작성자 정보
                      Row(
                        children: [
                          // 프로필 동그라미
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '익명',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatTime(_post?['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    ' · 조회수 ${_post?['views'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const Spacer(),
                          // 알림 버튼
                          IconButton(
                            icon: Icon(
                              _isNotiOn
                                  ? Icons.notifications // ON
                                  : Icons.notifications_off_outlined, // OFF
                            ),
                            onPressed: () {
                              setState(() {
                                _isNotiOn = !_isNotiOn;
                              });
                            }
                          ),
                          // 더보기 버튼
                          IconButton(
                            key: _menuKey,
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: () async {
                              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                              final isAuthor = currentUserId == _post?['user_id'];

                              final RenderBox button =  _menuKey.currentContext!.findRenderObject() as RenderBox;
                              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                              final RelativeRect position = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
                                  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );

                              final result = await showMenu(
                                context: context,
                                position: position,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                items: [
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Text('공유하기'),
                                        SizedBox(width: 12),
                                        Icon(Icons.share_outlined, size: 18),
                                      ],
                                    ),
                                  ),
                                  if (isAuthor)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Text('수정하기'),
                                          SizedBox(width: 12),
                                          Icon(Icons.edit_outlined, size: 18),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Text('삭제하기', style: TextStyle(color: Colors.red)),
                                        const SizedBox(width: 12),
                                      const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              );

                              if (result == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostWriteScreen(
                                      editPostId: widget.postId,
                                      initialTitle: _post?['title'],
                                      initialContent: _post?['content'],
                                      initialCategory: _post?['category'],
                                    ),
                                  ),
                                );
                                _fetchData();
                              } else if (result == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('글 삭제'),
                                    content: const Text('정말 삭제하시겠어요?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await Supabase.instance.client.from('posts').delete().eq('id', widget.postId);
                                  if (mounted) Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 글 제목
                      Text(
                        _post?['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 글 내용
                      Text(
                        _post?['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 공감/댓글/관심 버튼
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReactionButton(
                            _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            '공감',
                            '$_likesCount',
                            _isLiked ? const Color(0xFF84EA37) : Colors.grey,
                            _toggleLike,
                          ),
                          _buildReactionButton(
                            Icons.chat_bubble,
                            '댓글',
                            '$_commentsCount',
                            Colors.grey,
                            () {},
                          ),
                          _buildReactionButton(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                            '관심',
                            '$_bookmarksCount',
                            _isBookmarked ? const Color(0xFFFFD44E) : Colors.grey,
                            _toggleBookmark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 댓글 영역
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              '흠.. 아직 조용하네요',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        )
                      else
                        ..._comments
                          .where((c) => c['parent_id'] == null)
                          .map((comment) {
                            final replies = _comments
                                .where((c) => c['parent_id'] == comment['id'] ||
                                    _comments.where((r) => r['parent_id'] == comment['id'])
                                        .any((r) => r['id'] == c['parent_id']))
                                .toList();
                            
                            // 각 답글의 답글 수 계산
                            final replyCountMap = <int, int>{};
                            for (final reply in replies) {
                              replyCountMap[reply['id']] = _comments
                                  .where((c) => c['parent_id'] == reply['id'])
                                  .length;
                            }
                            
                            return _buildCommentItem(comment, replies: replies, replyCountMap: replyCountMap);
                          }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 하단 댓글 입력창
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Column( // 👈 Row → Column으로 감싸기
              mainAxisSize: MainAxisSize.min,
              children: [ 
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: Colors.grey),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_outlined, color: Colors.grey),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            if (_replyToEmail != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  '@$_replyToEmail',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                decoration: InputDecoration(
                                  hintText: _replyToEmail != null ? '답글을 입력하세요' : '게시글에 대한 의견을 남겨주세요',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submitComment,
                      child: const Icon(Icons.send, color: Color(0xFF4CAF50)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, String label, String count, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        '$label $count',
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }

Widget _buildCommentItem(Map<String, dynamic> comment, {List<Map<String, dynamic>> replies = const [], Map<int, int> replyCountMap = const {}}) {    final likeCount = _commentLikes.where((l) => l['comment_id'] == comment['id'] && l['is_like'] == true).length;
    final dislikeCount = _commentLikes.where((l) => l['comment_id'] == comment['id'] && l['is_like'] == false).length;
    final user = Supabase.instance.client.auth.currentUser;
    final myLike = _commentLikes.where((l) => l['comment_id'] == comment['id'] && l['user_id'] == user?.id).firstOrNull;
    final isLiked = myLike?['is_like'] == true;
    final isDisliked = myLike?['is_like'] == false;

    return Container(
      color: _highlightedCommentId == comment['id'] 
          ? Colors.green.withOpacity(0.08) 
          : Colors.transparent,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _anonLabel(comment['user_id']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    timeAgo(comment['created_at']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  final isAuthor = user?.id == comment['user_id'];
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAuthor)
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                              onTap: () => Navigator.pop(context, 'delete'),
                            ),
                          if (!isAuthor)
                            ListTile(
                              leading: const Icon(Icons.flag_outlined, color: Colors.grey),
                              title: const Text('신고하기'),
                              onTap: () => Navigator.pop(context, 'report'),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (result == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('댓글 삭제'),
                        content: const Text('정말 삭제하시겠어요?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await Supabase.instance.client.from('comments').delete().eq('id', comment['id']);
                      _fetchData();
                    }
                  } else if (result == 'report') {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었어요')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              comment['content'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          _badgeChip(comment),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _replyToCommentId = comment['id'];
                      _replyToEmail = _anonLabel(comment['user_id']);
                      _highlightedCommentId = comment['id']; // 답글은 reply['id']
                     });
                    FocusScope.of(context).requestFocus(_commentFocusNode); // 입력창 포커스
                  },
                  child: Text(
                    replies.isEmpty ? '답글' : '답글 ${replies.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleCommentLike(comment['id'], true),
                  child: Icon(Icons.thumb_up_outlined, size: 14,
                      color: isLiked ? Colors.green : Colors.grey),
                ),
                const SizedBox(width: 4),
                Text('$likeCount', style: TextStyle(fontSize: 12,
                    color: isLiked ? Colors.green : Colors.grey)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleCommentLike(comment['id'], false),
                  child: Icon(Icons.thumb_down_outlined, size: 14,
                      color: isDisliked ? Colors.orange : Colors.grey),
                ),
                const SizedBox(width: 4),
                Text('$dislikeCount', style: TextStyle(fontSize: 12,
                    color: isDisliked ? Colors.orange : Colors.grey)),
              ],
            ),
          ),
          if (replies.isNotEmpty)
          ...replies.map((reply) {
          final replyLikeCount = _commentLikes.where((l) => l['comment_id'] == reply['id'] && l['is_like'] == true).length;
          final replyDislikeCount = _commentLikes.where((l) => l['comment_id'] == reply['id'] && l['is_like'] == false).length;
          final replyUser = Supabase.instance.client.auth.currentUser;
          final myReplyLike = _commentLikes.where((l) => l['comment_id'] == reply['id'] && l['user_id'] == replyUser?.id).firstOrNull;
          final isReplyLiked = myReplyLike?['is_like'] == true;
          final isReplyDisliked = myReplyLike?['is_like'] == false;

          return Container(
            color: _highlightedCommentId == reply['id']
                ? Colors.green.withOpacity(0.08)
                : Colors.transparent,
            padding: const EdgeInsets.only(left: 20, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _anonLabel(reply['user_id']),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          timeAgo(reply['created_at']),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                      onPressed: () async {
                        final replyUser = Supabase.instance.client.auth.currentUser;
                        final isAuthor = replyUser?.id == reply['user_id'];
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAuthor)
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                                    title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                                    onTap: () => Navigator.pop(context, 'delete'),
                                  ),
                                if (!isAuthor)
                                  ListTile(
                                    leading: const Icon(Icons.flag_outlined, color: Colors.grey),
                                    title: const Text('신고하기'),
                                    onTap: () => Navigator.pop(context, 'report'),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (result == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('답글 삭제'),
                              content: const Text('정말 삭제하시겠어요?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Supabase.instance.client.from('comments').delete().eq('id', reply['id']);
                            _fetchData();
                          }
                        } else if (result == 'report') {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었어요')));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '@${_anonLabel(comment['user_id'])} ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: reply['content'] ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.black, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                _badgeChip(reply),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyToCommentId = reply['id'];
                            _replyToEmail = _anonLabel(reply['user_id']);
                            _highlightedCommentId = reply['id']; // 답글은 reply['id']
                          });
                          FocusScope.of(context).requestFocus(_commentFocusNode); // 입력창 포커
                        },
                        child: Text(
                          (replyCountMap[reply['id']] ?? 0) == 0 
                              ? '답글' 
                              : '답글 ${replyCountMap[reply['id']]}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _toggleCommentLike(reply['id'], true),
                        child: Icon(Icons.thumb_up_outlined, size: 14,
                            color: isReplyLiked ? Colors.green : Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text('$replyLikeCount', style: TextStyle(fontSize: 12,
                          color: isReplyLiked ? Colors.green : Colors.grey)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleCommentLike(reply['id'], false),
                        child: Icon(Icons.thumb_down_outlined, size: 14,
                            color: isReplyDisliked ? Colors.orange : Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text('$replyDislikeCount', style: TextStyle(fontSize: 12,
                          color: isReplyDisliked ? Colors.orange : Colors.grey)),
                    ],
                  ),
                ),  
              ],
            ),);
          }),
          const Divider(height: 24),
        ],
      ),
    );
  }
}