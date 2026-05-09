import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────
// 시작화면
// ─────────────────────────────────────────
class OnboardingStartScreen extends StatelessWidget {
  const OnboardingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역 (로고 + 태그)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F8D0), Color(0xFFFFFDE7), Colors.white],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PIKL',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF84EA36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '온라인 토론에\n가치가 생기는 순간',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        children: const [
                          _HashTag('#캠퍼스'),
                          _HashTag('#정치'),
                          _HashTag('#사회'),
                          _HashTag('#기술'),
                          _HashTag('#환경'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  _StartButton(
                    color: const Color(0xFFFFE400),
                    icon: Icons.chat_bubble,
                    iconColor: const Color(0xFF3C1E1E),
                    label: '카카오로 시작하기',
                    textColor: const Color(0xFF3C1E1E),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _StartButton(
                    color: Colors.white,
                    icon: Icons.g_mobiledata,
                    iconColor: Colors.red,
                    label: '구글로 시작하기',
                    textColor: Colors.black,
                    border: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _StartButton(
                    color: Colors.white,
                    icon: Icons.email_outlined,
                    iconColor: Colors.grey,
                    label: '이메일로 시작하기',
                    textColor: Colors.black,
                    border: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OnboardingStep1Screen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _StartButton(
                    color: Colors.white,
                    icon: Icons.group_outlined,
                    iconColor: Colors.grey,
                    label: '단체 회원가입하기',
                    textColor: Colors.black,
                    border: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('로그인',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                      const Text('·',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('계정 찾기',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                      const Text('·',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('비밀번호 찾기',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HashTag extends StatelessWidget {
  final String label;
  const _HashTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }
}

class _StartButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool border;
  final VoidCallback onTap;

  const _StartButton({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: border ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 16,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Step 1: 약관 동의 (1/3)
// ─────────────────────────────────────────
class OnboardingStep1Screen extends StatefulWidget {
  const OnboardingStep1Screen({super.key});

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen> {
  final List<bool> _checked = [false, false, false, false, false, false, false];
  // 0: 전체, 1~4: 필수, 5~6: 선택

  bool get _allRequired => _checked[1] && _checked[2] && _checked[3] && _checked[4];

  void _toggleAll(bool val) {
    setState(() {
      for (int i = 0; i < _checked.length; i++) {
        _checked[i] = val;
      }
    });
  }

  void _toggle(int index) {
    setState(() {
      _checked[index] = !_checked[index];
      _checked[0] = _checked.sublist(1).every((v) => v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('1 / 3',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1 / 3,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF84EA36),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '서비스 이용을 위해\n약관에 동의해주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '언제든 설정에서 변경할 수 있어요',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            // 전체 동의
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _toggleAll(!_checked[0]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _checked[0]
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _checked[0]
                            ? const Color(0xFF84EA36)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text('전체 동의하기',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 항목들
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _TermItem(
                    label: '(필수) 만 14세 이상입니다',
                    checked: _checked[1],
                    onTap: () => _toggle(1),
                  ),
                  _TermItem(
                    label: '(필수) 이용약관 동의',
                    checked: _checked[2],
                    onTap: () => _toggle(2),
                  ),
                  _TermItem(
                    label: '(필수) 개인정보 수집 및 이용 동의',
                    checked: _checked[3],
                    onTap: () => _toggle(3),
                  ),
                  _TermItem(
                    label: '(필수) 학교 인증정보 수집 동의',
                    checked: _checked[4],
                    onTap: () => _toggle(4),
                  ),
                  _TermItem(
                    label: '(선택) 마케팅 정보 수신 동의',
                    checked: _checked[5],
                    onTap: () => _toggle(5),
                    required: false,
                  ),
                  _TermItem(
                    label: '(선택) 야간 알림 수신 동의',
                    checked: _checked[6],
                    onTap: () => _toggle(6),
                    required: false,
                  ),
                ],
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: _GreenButton(
                label: '동의하고 계속',
                enabled: _allRequired,
                onTap: _allRequired
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const OnboardingStep2Screen()),
                        )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final bool required;

  const _TermItem({
    required this.label,
    required this.checked,
    required this.onTap,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked
                  ? const Color(0xFF84EA36)
                  : Colors.grey.shade300,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: required ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Step 2: 전화번호 인증 (2/3)
// ─────────────────────────────────────────
class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('2 / 3',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 2 / 3,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF84EA36),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '전화번호를 인증해주세요',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '중복 가입과 도용을 막기 위해 사용해요.\n게시글에는 표시되지 않아요.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),

            // 전화번호 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '010-1234-5678',
                        hintStyle:
                            const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF323232),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('재전송',
                          style: TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 인증번호 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '인증번호 6자리',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('문자가 오지 않으면 스팸함을 확인해주세요',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: _GreenButton(
                label: '확인',
                enabled: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OnboardingStep3Screen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Step 3: 카테고리 선택 (3/3)
// ─────────────────────────────────────────
class OnboardingStep3Screen extends StatefulWidget {
  const OnboardingStep3Screen({super.key});

  @override
  State<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends State<OnboardingStep3Screen> {
  String _gender = '남자';
  final _nicknameController = TextEditingController();
  final String _region = '서울·경기·인천';
  final Set<String> _selectedTopics = {};

  final List<Map<String, String>> _topics = [
    {'label': '캠퍼스', 'emoji': '🏫'},
    {'label': '정치', 'emoji': '🏛'},
    {'label': '사회', 'emoji': '🍕'},
    {'label': '기술', 'emoji': '📢'},
    {'label': '환경', 'emoji': '🌿'},
    {'label': '문화', 'emoji': '🍜'},
    {'label': '교육', 'emoji': '✏️'},
  ];

  bool get _canProceed => _selectedTopics.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('3 / 3',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF84EA36),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '조금 더 자세히 알려주시겠어요?',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '피드와 추천 게시글을 맞춤으로 보여드려요',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 성별
                  Row(
                    children: ['남자', '여자', '직접 입력'].map((g) {
                      final selected = _gender == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF323232)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF323232)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                fontSize: 14,
                                color: selected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 닉네임
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '입력해주세요',
                            hintStyle:
                                const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF323232),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('확인',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 지역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_region,
                          style: const TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: () {},
                        child: const Text('수정',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF84EA36),
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 관심 주제
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('관심 있는 주제',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text(
                        '2~7개   ${_selectedTopics.length}/7',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: _topics.map((topic) {
                      final selected =
                          _selectedTopics.contains(topic['label']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedTopics.remove(topic['label']);
                            } else if (_selectedTopics.length < 7) {
                              _selectedTopics.add(topic['label']!);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE8F8D0)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF84EA36)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(topic['emoji']!,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(topic['label']!,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: _GreenButton(
                label: '시작하기',
                enabled: _canProceed,
                onTap: _canProceed
                    ? () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const OnboardingCompleteScreen(
                                    selectedTopics: [],
                                  )),
                        )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 완료화면
// ─────────────────────────────────────────
class OnboardingCompleteScreen extends StatelessWidget {
  final List<String> selectedTopics;
  const OnboardingCompleteScreen({super.key, required this.selectedTopics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF84EA36),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '가입이 완료되었어요!',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '픽클에 오신 걸 환영해요!\n관심 있는 주제부터 천천히 둘러볼까요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    if (selectedTopics.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('관심 주제',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: selectedTopics
                                  .map((t) => Text('#$t',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: _GreenButton(
                label: '시작하기',
                enabled: true,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 공통 버튼
// ─────────────────────────────────────────
class _GreenButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _GreenButton({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF84EA36) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}