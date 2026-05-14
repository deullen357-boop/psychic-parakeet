import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_detail_screen.dart';
import 'post_write_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bookmark_screen.dart';
import 'subscription_screen.dart';
import 'my_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  int _currentTab = 0;
  int _bottomNavIndex = 0;
  Key _myKey = UniqueKey();
  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', 'HOT', '캠퍼스', '정치', '사회', '기술', '환경', '문화', '교육'];

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

  Map<int, int> _participantCounts = {};
  List<Map<String, dynamic>> _hotPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      // ignore: avoid_print
      print('[home] step=posts');
      var response;
      if (_selectedCategory == '전체' || _selectedCategory == 'HOT') {
        response = await Supabase.instance.client
            .from('posts')
            .select('*, post_likes(count), comments(count)')
            .order('created_at', ascending: false);
      } else {
        response = await Supabase.instance.client
            .from('posts')
            .select('*, post_likes(count), comments(count)')
            .eq('category', _selectedCategory)
            .order('created_at', ascending: false);
      }

      // ignore: avoid_print
      print('[home] step=participant_counts');
      final participantData = await Supabase.instance.client
          .from('post_participant_counts')
          .select();

      // ignore: avoid_print
      print('[home] step=count_map');
      final Map<int, int> counts = {};
      for (final row in participantData as List) {
        final pid = row['post_id'];
        final pc = row['participant_count'];
        if (pid is int && pc is int) counts[pid] = pc;
      }
      final hotPosts = List<Map<String, dynamic>>.from(response);
      hotPosts.sort((a, b) =>
          (_participantCounts[b['id']] ?? 1).compareTo(_participantCounts[a['id']] ?? 1));

      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _hotPosts = hotPosts.take(10).toList();
        _participantCounts = counts;
        _isLoading = false;
      });
      // ignore: avoid_print
      print('[home] done. posts=${_posts.length}');
    } catch (e, st) {
      // ignore: avoid_print
      print('=== home fetchPosts ERROR ===');
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(st);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: IndexedStack(
        index: _bottomNavIndex, 
        children: [
          SafeArea(
            child: Column(
          children: [
            // 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'PIKL',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84EA36),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 26),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 홈/최신 탭
            Row(
              children: [
                Expanded(child: _buildTab('홈', 0)),
                Expanded(child: _buildTab('최신', 1)),
              ],
            ),
            const Divider(height: 1),

            // 본문
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPosts,
                child: _currentTab == 0
                    ? ListView(
                        children: [
                          // 뜨거운 감자 섹션
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '오늘 연세대 뜨거운 감자',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentTab = 1;
                                      _selectedCategory = 'HOT';
                                      _fetchPosts();
                                    });
                                  },
                                  child: const Text(
                                    '더보기 >',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 가로 스크롤 카드
                          SizedBox(
                            height: screenHeight * 0.244,
                            child: _posts.isEmpty
                                ? const Center(child: Text('글이 없어요'))
                                : GestureDetector(
                                    onHorizontalDragUpdate: (_) {},
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: _hotPosts.length > 5 ? 5 : _hotPosts.length,
                                      itemBuilder: (context, index) {
                                        final post = _hotPosts[index];
                                        return GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PostDetailScreen(postId: post['id']),
                                              ),
                                            );
                                            _fetchPosts();
                                          },
                                          child: Container(
                                            width: screenWidth * 0.724,
                                            margin: const EdgeInsets.only(right: 12),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFBDBDBD), // 얇은 회색
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  post['category'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: const Color(0xFFBDBDBD),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  post['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  post['content'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: const Color(0xFF626262),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.local_fire_department,
                                                        color: const Color(0xFFFF7400), size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${_participantCounts[post['id']] ?? 1}명 참여중',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(0xFFFF7400),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),

                          // 추천 게시글
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Text(
                              '추천 게시글',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),

                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_posts.isEmpty)
                            const Center(child: Text('아직 글이 없어요. 첫 글을 작성해보세요!'))
                          else
                            ..._posts.map((post) => _buildPostItem(post)),
                        ],
                      )
                    : Column(
                        children: [
                          // 카테고리 필터
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected = cat == _selectedCategory;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    _fetchPosts(); // 👈 추가
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF323232) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF323232) : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1),

                          // 최신 게시글 리스트
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _posts.isEmpty
                                    ? const Center(child: Text('아직 글이 없어요'))
                                    : ListView.builder(
                                        itemCount: _selectedCategory == 'HOT' 
                                            ? _hotPosts.length 
                                            : _posts.length,
                                        itemBuilder: (context, index) {
                                          final post = _selectedCategory == 'HOT' 
                                              ? _hotPosts[index] 
                                              : _posts[index];
                                          return _buildPostItem(post);
                                        }
                                      ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
          ),
          const BookmarkScreen(),
          const SubscriptionScreen(),
          MyScreen(key: _myKey),
        ],
      ),
      // 하단 네비게이션
      bottomNavigationBar: SizedBox(
        height: 74.1,
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
              if (index == 3) _myKey = UniqueKey();
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/home.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBBBBBB),
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/home.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF323232),
                  BlendMode.srcIn,
                ),
              ),
              label: '', //
            ),

            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/haert.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBBBBBB),
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/haert.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF323232),
                  BlendMode.srcIn,
                ),
              ),
              label: '', //
            ),

            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/supscription.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBBBBBB),
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/supscription.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF323232),
                  BlendMode.srcIn,
                ),
              ),
              label: '', //
            ),

            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/my.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBBBBBB),
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/my.svg',
                width: 28.42,
                height: 42.1,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF323232),
                  BlendMode.srcIn,
                ),
              ),
              label: '', //
            ),
          ],
        ),
      ),
    
      // 글쓰기 버튼
      floatingActionButton: _bottomNavIndex == 0
      ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostWriteScreen()),
          );
          _fetchPosts();
        },
        backgroundColor: const Color(0xFF84EA37),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23), 
        ),
        child: const Icon(Icons.edit, color: const Color(0xFF323232)),
      )
      : null,
    );
  }

  Widget _buildTab(String label, int index) {
  final isSelected = _currentTab == index;

  return GestureDetector(
    onTap: () => setState(() { 
      _currentTab = index; 
      if (index == 0) {
        _selectedCategory = '전체'; 
        _fetchPosts();
      }
    }),
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    ),
  );
}

Widget _buildPostItem(Map<String, dynamic> post) {
  return GestureDetector(
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: post['id']),
        ),
      );
      _fetchPosts();
    },
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post['title'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            post['content'] ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 14,color: const Color(0xFF5FD55F)),
              const SizedBox(width: 4),
              Text(
                    '${post['post_likes'][0]['count'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
              const SizedBox(width: 12),
              const Icon(Icons.comment_outlined, size: 14, color: const Color(0xFF5FD55F)),
              const SizedBox(width: 4),
              Text('${post['comments'][0]['count'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
              const SizedBox(width: 12),
              Text(timeAgo(post['created_at']),),
              const SizedBox(width: 12),
              const Text(
                '익명',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),
        ],
      ),
    ),
  );
}
}