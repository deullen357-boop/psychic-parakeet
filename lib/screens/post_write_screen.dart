import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostWriteScreen extends StatefulWidget {
  const PostWriteScreen({super.key});

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isAnonymous = false;
  String _selectedCategory = '정치/경제';
  final List<String> _categories = ['정치/경제', '사회/문화', '과학/기술', '환경'];
  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('posts').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'email': _isAnonymous ? '익명' : (user?.email ?? '익명'),
        'user_id': user?.id,
        'category': _selectedCategory,
        'likes': 0,
        'bookmarks': 0,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글 작성에 실패했어요')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '카테고리 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ..._categories.map(
              (cat) => ListTile(
                leading: Icon(
                  cat == _selectedCategory
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: cat == _selectedCategory
                      ? const Color(0xFF323232)
                      : Colors.grey,
                ),
                title: Text(cat),
                trailing: cat == _selectedCategory
                    ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                    : null,
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showCategoryPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedCategory,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.black, size: 20),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading || !_hasContent ? null : _submit,
            child: Text(
              '등록',
              style: TextStyle(
                color: _hasContent
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade400,
                fontSize: 15,
                fontWeight: _hasContent
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 입력
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000000),
                    ),
                    decoration: const InputDecoration(
                      hintText: '제목을 입력하세요.',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const Divider(height: 1),

                  // 내용 입력
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF000000),
                      ),
                      decoration: const InputDecoration(
                        hintText: '내용을 입력하세요.',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      maxLines: null,
                      expands: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 바
          const Divider(height: 1),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                // 사진 아이콘
                IconButton(
                  icon: const Icon(Icons.image_outlined,
                      color: Colors.grey, size: 22),
                  onPressed: () {},
                ),
                // 링크 아이콘
                IconButton(
                  icon: const Icon(Icons.link,
                      color: const Color(0xFF939393), size: 22),
                  onPressed: () {},
                ),
                const Spacer(),

                // 익명 체크박스
                GestureDetector(
                  onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                  child: Row(
                    children: [
                      Icon(
                        _isAnonymous
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank,
                        color: _isAnonymous
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '익명',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isAnonymous
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 구분선
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),

                // 임시저장
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('임시저장 되었습니다.')),
                    );
                  },
                  child: const Text(
                    '임시저장',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),

                // 구분선
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),

                // 숫자
                const Text(
                  '3',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}