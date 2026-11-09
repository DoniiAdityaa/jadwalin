import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/config/service_locator.dart';
import 'package:jadwalin/data/local/chat_dao.dart';
import 'package:jadwalin/data/local/models.dart';
import 'package:jadwalin/feature/chat/chatbot_screen.dart';
import 'package:jadwalin/feature/home/home_screen.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/app_sidebar.dart';
import 'package:jadwalin/ui/shared_widget/app_snackbar.dart';
import 'package:jadwalin/ui/shared_widget/bouncing_tap.dart';
import 'package:jadwalin/ui/shared_widget/dattio_ai_studio_sheet.dart';
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
  final GlobalKey<ChatbotScreenState> _chatKey =
      GlobalKey<ChatbotScreenState>();

  /// Text controller untuk input chat morphed di bottom bar.
  final TextEditingController _chatInputController = TextEditingController();
  final FocusNode _chatInputFocusNode = FocusNode();
  bool _hasChatText = false;

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

  @override
  void dispose() {
    _chatInputController.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  void _onChatInputChanged(String value) {
    final has = value.trim().isNotEmpty;
    if (has != _hasChatText) {
      setState(() => _hasChatText = has);
    }
  }

  void _sendFromBottomBar() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    _chatKey.currentState?.sendMessage(text);
    _chatInputController.clear();
    setState(() => _hasChatText = false);
  }

  /// Bottom sheet pilih sumber lampiran: Gambar / PDF.
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEADBCE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Lampirkan ke Asisten Jadwal',
                style: mBold.copyWith(color: darkEspresso),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih sumber untuk diekstrak jadi jadwal',
                style: xsRegular.copyWith(color: mutedTaupe),
              ),
              const SizedBox(height: 18),
              _attachOption(
                icon: 'assets/svg/ic_image.svg',
                iconBg: const Color(0xFFFFF3E8),
                iconColor: secondaryColor,
                title: 'Gambar / Screenshot',
                subtitle: 'Poster, foto papan tulis, atau tangkapan layar',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleAttachment('image');
                },
              ),
              const SizedBox(height: 10),
              _attachOption(
                icon: 'assets/svg/ic_file_text.svg',
                iconBg: oatMilkPill,
                iconColor: primaryColor,
                title: 'Dokumen PDF',
                subtitle: 'KRS, jadwal kuliah, atau surat undangan',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleAttachment('pdf');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Baris opsi lampiran di dalam bottom sheet.
  Widget _attachOption({
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEADBCE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                icon,
                width: 21,
                height: 21,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: sSemiBold.copyWith(color: darkEspresso)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: xsRegular.copyWith(color: mutedTaupe),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/svg/ic_chevron_right.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(mutedTaupe, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder handling lampiran. Belum ada parser — beri umpan balik
  /// sementara ke user lewat snackbar global sampai integrasi picker siap.
  void _handleAttachment(String type) {
    final label = type == 'pdf' ? 'Dokumen PDF' : 'Gambar';
    AppSnackBar.info(
      context,
      message: '$label dipilih',
      subtitle: 'Fitur ekstraksi segera hadir',
    );
  }

  /// Voice note belum diimplementasi — beri umpan balik sementara.
  void _onVoiceNoteTapped() {
    AppSnackBar.comingSoon(context, featureName: 'Voice note');
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

  Future<void> _renameSession(String sessionId, String newTitle) async {
    await serviceLocator<ChatDao>().renameSession(sessionId, newTitle);
    await _loadSessions();
  }

  /// Progress buka-tutup sidebar: 0.0 = tertutup, 1.0 = terbuka penuh.
  double _sidebarProgress = 0.0;

  /// Sedang digeser pakai jari.
  bool _isDragging = false;

  bool get _isSidebarOpen => _sidebarProgress > 0.5;

  bool get _isChatMode => _currentIndex == 1;

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Tap tab yang sama saat sidebar terbuka -> tutup sidebar.
      if (_sidebarProgress > 0) _closeSidebar();
      return;
    }
    setState(() {
      _currentIndex = index;
      // Sidebar hanya relevan di mode Chatbot. Pindah ke Jadwal menutupnya
      // agar tidak ada drawer menggantung di layar jadwal.
      if (index != 1) _sidebarProgress = 0.0;
    });
  }

  /// Tap tombol tengah: langsung buka Dattio AI Studio.
  void _onAiButtonTapped() {
    HapticFeedback.lightImpact();
    _showDattioPromptSheet();
  }

  /// Bottom sheet "Dattio AI Studio" dengan animasi masuk yang halus.
  void _showDattioPromptSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF261C14).withValues(alpha: 0.42),
      builder: (sheetContext) => DattioAiStudioSheet(
        onPickSource: (type) {
          Navigator.pop(sheetContext);
          _handleAiImport(type);
        },
        onManualText: () {
          Navigator.pop(sheetContext);
          setState(() => _currentIndex = 1);
        },
      ),
    );
  }

  void _closeSidebar() => setState(() => _sidebarProgress = 0.0);

  void _toggleSidebar() {
    setState(() => _sidebarProgress = _isSidebarOpen ? 0.0 : 1.0);
  }

  /// Gesture drag mulai: geser sidebar sesuai posisi jari.
  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    // Drawer swipe hanya aktif di mode Chatbot.
    if (!_isChatMode) return;
    setState(() {
      _isDragging = true;
      _sidebarProgress =
          (_sidebarProgress + details.delta.dx / width).clamp(0.0, 1.0);
    });
  }

  /// Drag selesai: snap ke buka/tutup berdasarkan progress.
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isChatMode) {
      if (_isDragging) setState(() => _isDragging = false);
      return;
    }
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
    // Pindah ke mode Chatbot dulu supaya laporan AI muncul di sana.
    Future.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      setState(() => _currentIndex = 1);
      _showAiInputBottomSheet();
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!_isChatMode) return;
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
              onSessionRename: _renameSession,
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
                            showInputBar: false,
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
      bottomNavigationBar: AnimatedSlide(
        duration:
            _isDragging ? Duration.zero : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: Offset(_sidebarProgress * 0.55, _sidebarProgress * 1.4),
        child: AnimatedOpacity(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 260),
          opacity: 1 - _sidebarProgress,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: _isChatMode ? 16 : 44,
                  vertical: _isChatMode ? 10 : 14,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(
                    minHeight: _isChatMode ? 58 : 72,
                    maxHeight: _isChatMode ? 140 : 72,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_isChatMode ? 26 : 36),
                    border: _isChatMode
                        ? Border.all(color: const Color(0xFFEADBCE), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _isChatMode
                            ? darkEspresso.withValues(alpha: 0.08)
                            : primaryColor.withValues(alpha: 0.08),
                        blurRadius: _isChatMode ? 18 : 24,
                        offset: Offset(0, _isChatMode ? 4 : 8),
                      ),
                      if (!_isChatMode)
                        BoxShadow(
                          color: secondaryColor.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child:
                        _isChatMode ? _buildChatInputBar() : _buildMainNavBar(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Isi bottom bar saat mode normal (Jadwal): 3 item navigasi.
  Widget _buildMainNavBar() {
    return Row(
      key: const ValueKey('nav_bar'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tab 0: Rundown Harian
        _navItem(
          svgAsset: 'assets/svg/ic_calendar.svg',
          isSelected: _currentIndex == 0,
          onTap: () => _onTabTapped(0),
        ),

        // Center Action: Animasi Sparkle Burst -> Tanya Dattio
        BouncingTap(
          scaleDown: 0.93,
          child: GestureDetector(
            onTap: _onAiButtonTapped,
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
        ),

        // Tab 1: AI Chat Asisten
        _navItem(
          svgAsset: 'assets/svg/ic_message_dots.svg',
          isSelected: _currentIndex == 1,
          onTap: () => _onTabTapped(1),
        ),
      ],
    );
  }

  /// Isi bottom bar saat morphed ke mode Chatbot: input bar lengkap.
  Widget _buildChatInputBar() {
    return Padding(
      key: const ValueKey('chat_input'),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol plus: pilih sumber lampiran (Gambar / PDF)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: BouncingTap(
              scaleDown: 0.9,
              child: InkWell(
                onTap: _showAttachmentSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: oatMilkPill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svg/ic_plus.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Text Field "Tulis pesan..." — multiline expanding (max 4 baris)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TextField(
                controller: _chatInputController,
                focusNode: _chatInputFocusNode,
                style: smMedium.copyWith(color: darkEspresso),
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onChanged: _onChatInputChanged,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: smRegular.copyWith(color: mutedTaupe),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Tombol aksi: Buka Sidebar Drawer AI / Kirim Pesan
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: BouncingTap(
              scaleDown: 0.9,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _hasChatText
                    ? InkWell(
                        key: const ValueKey('send_btn'),
                        onTap: _sendFromBottomBar,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/svg/ic_send.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        key: const ValueKey('mic_btn'),
                        onTap: _onVoiceNoteTapped,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: oatMilkPill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/svg/ic_mic.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              primaryColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required String svgAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      scaleDown: 0.9,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? oatMilkPill : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
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
