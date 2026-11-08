import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/config/service_locator.dart';
import 'package:jadwalin/data/local/chat_dao.dart';
import 'package:jadwalin/data/local/models.dart';
import 'package:jadwalin/feature/chat/chatbot_screen.dart';
import 'package:jadwalin/feature/home/home_screen.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/app_sidebar.dart';
import 'package:jadwalin/ui/typography.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  static const double _sidebarMaxWidth = 310.0;

  int _currentIndex = 0;

  /// Controller untuk memanggil openSession / startNewChat di chatbot.
  final GlobalKey<ChatbotScreenState> _chatKey = GlobalKey<ChatbotScreenState>();

  /// Riwayat chat dari SQLite (sidebar).
  List<ChatSessionModel> _sessions = const [];

  /// Sesi chat yang sedang dibuka.
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await serviceLocator<ChatDao>().getSessions(limit: 30);
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  void _openSession(String sessionId) {
    _activeSessionId = sessionId;
    _currentIndex = 1;
    _chatKey.currentState?.openSession(sessionId);
    setState(() {});
    _closeSidebar();
  }

  void _startNewChat() {
    _activeSessionId = null;
    _chatKey.currentState?.startNewChat();
  }

  Future<void> _deleteSession(String sessionId) async {
    await serviceLocator<ChatDao>().deleteSession(sessionId);

    // Kalau yang dihapus adalah sesi aktif, reset ke chat kosong.
    if (_activeSessionId == sessionId) {
      _activeSessionId = null;
      _chatKey.currentState?.startNewChat();
    }

    await _loadSessions();
  }

  /// Progress buka-tutup sidebar: 0.0 = tertutup, 1.0 = terbuka penuh.
  double _sidebarProgress = 0.0;

  /// Sedang digeser pakai jari.
  bool _isDragging = false;

  bool get _isSidebarOpen => _sidebarProgress > 0.5;

  bool get _isChatMode => _currentIndex == 1;

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _openSidebar() => setState(() => _sidebarProgress = 1.0);

  void _closeSidebar() => setState(() => _sidebarProgress = 0.0);

  void _toggleSidebar() {
    setState(() => _sidebarProgress = _isSidebarOpen ? 0.0 : 1.0);
  }

  /// Gesture drag mulai: geser sidebar sesuai posisi jari.
  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _isDragging = true;
      _sidebarProgress =
          (_sidebarProgress + details.delta.dx / width).clamp(0.0, 1.0);
    });
  }

  /// Drag selesai: snap ke buka/tutup berdasarkan progress.
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    setState(() {
      _isDragging = false;
      if (velocity > 300) {
        _sidebarProgress = 1.0;
      } else if (velocity < -300) {
        _sidebarProgress = 0.0;
      } else {
        _sidebarProgress = _sidebarProgress > 0.5 ? 1.0 : 0.0;
      }
    });
  }

  void _showAiInputBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _aiInputModal(context),
    );
  }

  void _handleAiImport(String type) {
    _closeSidebar();
    Future.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      _showAiInputBottomSheet();
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  /// Faktor gelap overlay: 0 (terang) .. 1 (gelap).
  double get _dimFactor => _sidebarProgress * 0.06;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth =
        (screenWidth * 0.80).clamp(260.0, _sidebarMaxWidth).toDouble();

    return Scaffold(
      backgroundColor: warmCanvasBg,
      extendBody: true,
      body: Stack(
        children: [
          // 1. Sidebar nempel di kiri layar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: AppSidebarContent(
              currentIndex: _currentIndex,
              onClose: _closeSidebar,
              onNavigate: _onTabTapped,
              onAiImport: _handleAiImport,
              sessions: _sessions,
              activeSessionId: _activeSessionId,
              onSessionTap: _openSession,
              onNewChat: _startNewChat,
              onSessionDelete: _deleteSession,
            ),
          ),

          // 2. Main Content Screen yang terdorong ke kanan saat sidebar buka
          AnimatedPositioned(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: _sidebarProgress * sidebarWidth,
            right: -_sidebarProgress * sidebarWidth,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: (details) =>
                  _onHorizontalDragUpdate(details, sidebarWidth),
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: _sidebarProgress > 0.02
                      ? [
                          BoxShadow(
                            color: const Color(0xFF261C14)
                                .withValues(alpha: 0.18 * _sidebarProgress),
                            blurRadius: 28,
                            offset: const Offset(-8, 0),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    24 * _sidebarProgress,
                  ),
                  child: Stack(
                    children: [
                      // Layar aktif (Home atau Chatbot)
                      IndexedStack(
                        index: _currentIndex,
                        children: [
                          const HomeScreen(),
                          ChatbotScreen(
                            key: _chatKey,
                            showBackButton: false,
                            onOpenSidebar: _toggleSidebar,
                            onSessionCreated: _loadSessions,
                          ),
                        ],
                      ),

                      // Overlay gelap saat sidebar terbuka
                      IgnorePointer(
                        ignoring: true,
                        child: AnimatedContainer(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          color: Colors.black.withValues(alpha: _dimFactor),
                        ),
                      ),

                      // Tap blocker di area content saat sidebar kebuka
                      if (_isSidebarOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _closeSidebar,
                            behavior: HitTestBehavior.translucent,
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isChatMode
          ? null
          : AnimatedSlide(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: Offset(_sidebarProgress * 0.55, _sidebarProgress * 1.4),
              child: AnimatedOpacity(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                opacity: 1 - _sidebarProgress,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 14,
                    ),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: secondaryColor.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Tab 0: Rundown Harian
                          _navItem(
                            svgAsset: 'assets/svg/ic_calendar.svg',
                            isSelected: _currentIndex == 0,
                            onTap: () => _onTabTapped(0),
                          ),

                          // Center Action: Buka Sidebar
                          GestureDetector(
                            onTap: _openSidebar,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/svg/ic_sparkles.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Tab 1: AI Chat Asisten
                          _navItem(
                            svgAsset: 'assets/svg/ic_message_dots.svg',
                            isSelected: _currentIndex == 1,
                            onTap: () => _onTabTapped(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _navItem({
    required String svgAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? oatMilkPill : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: SvgPicture.asset(
            svgAsset,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? primaryColor : mutedTaupe,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _aiInputModal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFEADBCE),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: oatMilkPill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/svg/ic_sparkles.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Jadwal Otomatis ✨',
                      style: mBold.copyWith(color: darkEspresso),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilih sumber dokumen untuk diekstrak oleh AI',
                      style: xsRegular.copyWith(color: mutedTaupe),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _aiOptionCard(
            svgAsset: 'assets/svg/ic_file_text.svg',
            iconBg: oatMilkPill,
            iconColor: primaryColor,
            title: 'Upload Dokumen PDF KRS',
            subtitle: 'Auto-generate jadwal kuliah 16 minggu',
            badge: '16 Minggu',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _aiOptionCard(
            svgAsset: 'assets/svg/ic_image.svg',
            iconBg: const Color(0xFFFFF3E8),
            iconColor: secondaryColor,
            title: 'Scan Foto / Poster / SS',
            subtitle: 'Ekstrak waktu rapat organisasi & seminar',
            badge: 'Instan',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _aiOptionCard(
            svgAsset: 'assets/svg/ic_chat.svg',
            iconBg: const Color(0xFFEFF5ED),
            iconColor: const Color(0xFF4A6B40),
            title: 'Tempel Chat WhatsApp / Discord',
            subtitle: 'Format pengumuman teks langsung jadi jadwal',
            badge: 'Teks Chat',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _aiOptionCard({
    required String svgAsset,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEADBCE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgAsset,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    iconColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: sSemiBold.copyWith(color: darkEspresso),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: xsRegular.copyWith(color: mutedTaupe),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: xxsBold.copyWith(color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
