import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostWriteScreen extends StatefulWidget {
  final int? editPostId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;

  const PostWriteScreen({
    super.key,
    this.editPostId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
  });

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isAnonymous = false;
  String _selectedCategory = '캠퍼스';
  final List<String> _categories = ['캠퍼스', '정치', '사회', '기술', '환경', '문화', '교육'];
  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  List<String> _bookmarkedCategories = [];
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialContent != null) _contentController.text = widget.initialContent!;
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
    _fetchBookmarkedCategories();
    _fetchDraftCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
      if (widget.editPostId != null) {
        await Supabase.instance.client.from('posts').update({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'category': _selectedCategory,
        }).eq('id', widget.editPostId!);
      } else {
        await Supabase.instance.client.from('posts').insert({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'email': '익명',
          'user_id': user?.id,
          'category': _selectedCategory,
          'likes': 0,
          'bookmarks': 0,
        });
      }
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

  Future<void> _fetchBookmarkedCategories() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('profiles')
        .select('bookmarked_categories')
        .eq('id', user.id)
        .single();
    setState(() {
      _bookmarkedCategories =
          List<String>.from(data['bookmarked_categories'] ?? []);
    });
  }

  Future<void> _toggleBookmarkCategory(String category) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final updated = List<String>.from(_bookmarkedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    await Supabase.instance.client
        .from('profiles')
        .update({'bookmarked_categories': updated}).eq('id', user.id);
    setState(() => _bookmarkedCategories = updated);
  }

  Future<void> _fetchDraftCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('draft_posts')
        .select()
        .eq('user_id', user.id);
    setState(() => _draftCount = (data as List).length);
  }

  Future<void> _saveDraft() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('draft_posts').insert({
      'user_id': user.id,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'category': _selectedCategory,
    });
    await _fetchDraftCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('임시저장 되었습니다.')),
      );
    }
  }

  void _showDrafts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('draft_posts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    final drafts = List<Map<String, dynamic>>.from(data);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraftListSheet(
        drafts: drafts,
        onSelect: (draft) {
          setState(() {
            _titleController.text = draft['title'] ?? '';
            _contentController.text = draft['content'] ?? '';
            _selectedCategory = draft['category'] ?? '캠퍼스';
          });
          Navigator.pop(context);
        },
        onDelete: (id) async {
          await Supabase.instance.client
              .from('draft_posts')
              .delete()
              .eq('id', id);
          await _fetchDraftCount();
          Navigator.pop(context);
          _showDrafts();
        },
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        const Text(
                          '카테고리 선택',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFF323232)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ..._categories.map(
                    (cat) => ListTile(
                      leading: GestureDetector(
                        onTap: () async {
                          await _toggleBookmarkCategory(cat);
                          setModalState(() {});
                        },
                        child: Icon(
                          _bookmarkedCategories.contains(cat)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _bookmarkedCategories.contains(cat)
                              ? const Color(0xFF323232)
                              : Colors.grey,
                        ),
                      ),
                      title: Text(cat),
                      trailing: cat == _selectedCategory
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF4CAF50))
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                fontWeight:
                    _hasContent ? FontWeight.w600 : FontWeight.normal,
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
                          color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF000000)),
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
                IconButton(
                  icon: const Icon(Icons.image_outlined,
                      color: Colors.grey, size: 22),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.link,
                      color: Color(0xFF939393), size: 22),
                  onPressed: () {},
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isAnonymous = !_isAnonymous),
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
                Container(
                    width: 1, height: 16, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _saveDraft,
                  child: const Text('임시저장',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                Container(
                    width: 1, height: 16, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showDrafts,
                  child: Text('$_draftCount',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DraftListSheet extends StatelessWidget {
  final List<Map<String, dynamic>> drafts;
  final Function(Map<String, dynamic>) onSelect;
  final Function(int) onDelete;

  const DraftListSheet({
    super.key,
    required this.drafts,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    '임시저장 글',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    '총 ${drafts.length}개',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: drafts.isEmpty
                  ? const Center(child: Text('임시저장된 글이 없어요'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        return GestureDetector(
                          onTap: () => onSelect(draft),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft['category'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  draft['title']?.isNotEmpty == true
                                      ? draft['title']
                                      : '제목 없음',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  draft['content'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Divider(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}