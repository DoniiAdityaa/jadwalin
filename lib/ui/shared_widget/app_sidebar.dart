import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/data/local/models.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Content sidebar ala ChatGPT yang nempel di sisi kiri dan
/// mendorong main content ke kanan saat terbuka.
class AppSidebarContent extends StatelessWidget {
  const AppSidebarContent({
    super.key,
    required this.currentIndex,
    required this.onClose,
    required this.onNavigate,
    required this.onAiImport,
    this.sessions = const [],
    this.activeSessionId,
    this.onSessionTap,
    this.onNewChat,
    this.onSessionDelete,
    this.onSessionRename,
  });

  final int currentIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onNavigate;
  final ValueChanged<String> onAiImport;

  /// Daftar sesi chat dari SQLite, terbaru dulu.
  final List<ChatSessionModel> sessions;

  /// Sesi chat yang sedang dibuka di chatbot.
  final String? activeSessionId;

  /// Buka riwayat chat tertentu.
  final ValueChanged<String>? onSessionTap;

  /// Mulai percakapan baru kosong.
  final VoidCallback? onNewChat;

  /// Hapus sesi chat (dipanggil setelah user konfirmasi).
  final ValueChanged<String>? onSessionDelete;

  /// Ganti nama sesi chat. Callback menerima (sessionId, judulBaru).
  final void Function(String sessionId, String newTitle)? onSessionRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil User
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: oatMilkPill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEADBCE),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/svg/ic_user.svg',
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
                          'Doni Aditya',
                          style: sBold.copyWith(
                            color: darkEspresso,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mahasiswa • Semester 1',
                          style: xxxsMedium.copyWith(color: mutedTaupe),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: warmCanvasBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/svg/ic_arrow_left.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          darkEspresso,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Navigasi utama berupa segmented toggle ringkas.
              // Bottom bar adalah sumber navigasi tunggal; toggle ini
              // cermin cepat agar sidebar tetap fungsional tanpa menduplikasi
              // daftar menu.
              _modeToggle(currentIndex, onNavigate, onClose),

              const SizedBox(height: 22),
              _sectionLabel('Tambah Jadwal Otomatis'),
              const SizedBox(height: 10),

              // AI Import Cards
              _aiCard(
                icon: 'assets/svg/ic_file_text.svg',
                iconBg: oatMilkPill,
                iconColor: primaryColor,
                title: 'Upload Dokumen PDF KRS',
                subtitle: 'Auto-generate jadwal kuliah',
                badge: '16 Minggu',
                badgeColor: primaryColor,
                onTap: () => onAiImport('pdf'),
              ),
              const SizedBox(height: 8),
              _aiCard(
                icon: 'assets/svg/ic_image.svg',
                iconBg: const Color(0xFFFFF3E8),
                iconColor: secondaryColor,
                title: 'Scan Foto / Poster / SS',
                subtitle: 'Ekstrak rapat & seminar',
                badge: 'Instan',
                badgeColor: secondaryColor,
                onTap: () => onAiImport('image'),
              ),
              const SizedBox(height: 8),
              _aiCard(
                icon: 'assets/svg/ic_chat.svg',
                iconBg: const Color(0xFFEFF5ED),
                iconColor: const Color(0xFF4A6B40),
                title: 'Tempel Chat WhatsApp',
                subtitle: 'Teks langsung jadi jadwal',
                badge: 'Teks Chat',
                badgeColor: const Color(0xFF4A6B40),
                onTap: () => onAiImport('chat'),
              ),

              const SizedBox(height: 22),
              _sectionLabel('Riwayat Chat'),
              const SizedBox(height: 8),

              Expanded(
                child: sessions.isEmpty
                    ? _emptyHistory()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final s = sessions[index];
                          return _dismissibleHistoryRow(
                            context: context,
                            session: s,
                            isActive: s.id == activeSessionId,
                            onTap: () => onSessionTap?.call(s.id),
                            onDelete: () => onSessionDelete?.call(s.id),
                            onRename: (newTitle) =>
                                onSessionRename?.call(s.id, newTitle),
                          );
                        },
                      ),
              ),

              // Chat baru pill button
              GestureDetector(
                onTap: () {
                  onNewChat?.call();
                  onNavigate(1);
                  onClose();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, Color(0xFF8B6B4D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svg/ic_edit.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chat Baru',
                        style: smBold.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: xxxsBold.copyWith(
        color: mutedTaupe,
        letterSpacing: 0.8,
      ),
    );
  }

  /// Segmented toggle ringkas: Home / Chatbot.
  ///
  /// Berfungsi sebagai cermin cepat dari bottom bar tanpa menduplikasi
  /// daftar menu penuh. Tap berpindah mode sekaligus menutup sidebar.
  Widget _modeToggle(
    int currentIndex,
    ValueChanged<int> onNavigate,
    VoidCallback onClose,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: warmCanvasBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeSegment(
              icon: 'assets/svg/ic_calendar.svg',
              label: 'Jadwal',
              isActive: currentIndex == 0,
              onTap: () {
                onNavigate(0);
                onClose();
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modeSegment(
              icon: 'assets/svg/ic_message_dots.svg',
              label: 'Chatbot',
              isActive: currentIndex == 1,
              onTap: () {
                onNavigate(1);
                onClose();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSegment({
    required String icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isActive ? primaryColor : mutedTaupe,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: xsSemiBold.copyWith(
                color: isActive ? darkEspresso : mutedTaupe,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiCard({
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: warmCanvasBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFEADBCE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: xsSemiBold.copyWith(color: darkEspresso),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: xxxsMedium.copyWith(color: mutedTaupe),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                badge,
                style: xxxsBold.copyWith(color: badgeColor, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada riwayat',
            style: xsMedium.copyWith(color: mutedTaupe),
          ),
          const SizedBox(height: 2),
          Text(
            'Mulai chat baru untuk memulai.',
            style: xxxsMedium.copyWith(color: mutedTaupe),
          ),
        ],
      ),
    );
  }

  Widget _dismissibleHistoryRow({
    required BuildContext context,
    required ChatSessionModel session,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required ValueChanged<String> onRename,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Dismissible(
          key: ValueKey(session.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/ic_trash.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          errorColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hapus Riwayat?',
                        style: mBold.copyWith(color: darkEspresso),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Percakapan "${session.title}" akan dihapus permanen '
                  'dan tidak bisa dikembalikan.',
                  style: smRegular.copyWith(color: mutedTaupe, height: 1.4),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: smSemiBold.copyWith(color: mutedTaupe),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: TextButton.styleFrom(
                      backgroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ya, Hapus',
                      style: smSemiBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 18),
            color: errorColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/svg/ic_trash.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hapus',
                  style: xxxsBold.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? oatMilkPill : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/ic_message.svg',
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(
                      isActive ? primaryColor : mutedTaupe,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: xsMedium.copyWith(
                        color: isActive ? primaryColor : darkEspresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tombol rename kecil (pensil).
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRenameDialog(context, session, onRename),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        'assets/svg/ic_pencil.svg',
                        width: 13,
                        height: 13,
                        colorFilter: ColorFilter.mode(
                          isActive
                              ? primaryColor.withValues(alpha: 0.7)
                              : mutedTaupe.withValues(alpha: 0.6),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog untuk mengganti judul sesi chat.
  Future<void> _showRenameDialog(
    BuildContext context,
    ChatSessionModel session,
    ValueChanged<String> onRename,
  ) async {
    final controller = TextEditingController(text: session.title);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: oatMilkPill,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/svg/ic_pencil.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ganti Nama',
                style: mBold.copyWith(color: darkEspresso),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          style: smRegular.copyWith(color: darkEspresso),
          decoration: InputDecoration(
            hintText: 'Judul percakapan',
            hintStyle: smRegular.copyWith(color: mutedTaupe),
            counterText: '',
            filled: true,
            fillColor: warmCanvasBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEADBCE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Batal',
              style: smSemiBold.copyWith(color: mutedTaupe),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Simpan',
              style: smSemiBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      onRename(newTitle);
    }
  }
}
