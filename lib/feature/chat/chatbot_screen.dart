import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/config/service_locator.dart';
import 'package:jadwalin/data/local/chat_dao.dart';
import 'package:jadwalin/data/local/models.dart';
import 'package:jadwalin/data/local/user_memory_dao.dart';
import 'package:jadwalin/data/service/ai_chat_service.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/chat_message_bubble.dart';
import 'package:jadwalin/ui/typography.dart';

/// State yang bisa dikendalikan dari luar (MainNavigation / Sidebar).
abstract class ChatbotScreenState extends State<ChatbotScreen> {
  /// Muat pesan dari sesi yang sudah tersimpan.
  Future<void> openSession(String sessionId);

  /// Mulai percakapan baru kosong (sesi baru dibuat saat pesan pertama).
  void startNewChat();

  /// Kirim pesan atas nama user (dipakai bar bawah morphed di shell).
  void sendMessage(String text);

  /// Fokuskan field input (dipakai shell saat beralih ke mode chat).
  void requestInputFocus();
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
    this.showBackButton = true,
    this.showInputBar = true,
    this.onOpenSidebar,
    this.onSessionCreated,
  });

  /// Kalau dipakai sebagai tab di MainNavigation, back button disembunyikan.
  final bool showBackButton;

  /// Kalau false, input bar internal disembunyikan (shell menyediakan
  /// bar bawah morphed sebagai input).
  final bool showInputBar;

  /// Callback buka sidebar drawer (dipakai saat jadi tab).
  final VoidCallback? onOpenSidebar;

  /// Dipanggil setelah sesi baru tersimpan, agar sidebar bisa refresh.
  final VoidCallback? onSessionCreated;

  @override
  ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ChatbotScreenState {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AiChatService _aiService = serviceLocator<AiChatService>();
  final ChatDao _chatDao = serviceLocator<ChatDao>();
  final UserMemoryDao _memoryDao = serviceLocator<UserMemoryDao>();

  bool _hasText = false;
  bool _isTyping = false;

  /// Sesi yang sedang aktif. Null = percakapan baru, belum disimpan.
  String? _sessionId;

  static const String _greeting =
      "Halo! Aku Jadwalin AI. Tanya apa saja soal tips atur waktu atau "
      "produktivitas kuliah. 😊";

  /// Index pesan yang baru saja masuk — dipakai untuk animasi fade-in.
  int? _lastAddedIndex;

  final List<Map<String, dynamic>> _messages = [
    {
      'text': _greeting,
      'isFromUser': false,
      'timestamp': DateTime.now(),
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Future<void> openSession(String sessionId) async {
    final stored = await _chatDao.getMessages(sessionId);
    if (!mounted) return;

    setState(() {
      _sessionId = sessionId;
      _messages
        ..clear()
        ..addAll(
          stored.map(
            (m) => {
              'text': m.content,
              'isFromUser': m.isFromUser,
              'timestamp': m.createdAt,
            },
          ),
        );
      // Buka riwayat: langsung posisikan di pesan terakhir tanpa animasi.
      _lastAddedIndex = null;
      _isTyping = false;
    });
    _jumpToBottom();
  }

  @override
  void startNewChat() {
    setState(() {
      _sessionId = null;
      _messages
        ..clear()
        ..add({
          'text': _greeting,
          'isFromUser': false,
          'timestamp': DateTime.now(),
        });
      _lastAddedIndex = null;
      _isTyping = false;
    });
    _jumpToBottom();
  }

  @override
  void sendMessage(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _textController.text = clean;
    _sendMessage();
  }

  @override
  void requestInputFocus() {
    _focusNode.requestFocus();
  }

  void _onTextChanged(String value) {
    final has = value.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  /// Scroll ke pesan paling bawah dengan animasi smooth.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Lompat instan ke pesan paling bawah (dipakai saat membuka riwayat chat).
  /// Dua frame ditunggu agar ListView sempat mengukur tinggi konten baru.
  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

      // Frame kedua: layout kadang belum final saat isi list berubah drastis.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // History dipakai untuk konteks AI. Greeting awal tidak dikirim.
    final history = _messages
        .where((m) => m['text'] != _greeting)
        .map(
          (m) => {
            'role': (m['isFromUser'] as bool) ? 'user' : 'assistant',
            'content': m['text'] as String,
          },
        )
        .toList();

    final userTime = DateTime.now();

    setState(() {
      _messages.add({
        'text': text,
        'isFromUser': true,
        'timestamp': userTime,
      });
      _lastAddedIndex = _messages.length - 1;
      _isTyping = true;
    });

    _textController.clear();
    _onTextChanged('');
    _focusNode.unfocus();
    _scrollToBottom();

    // Pastikan sesi ada sebelum menyimpan pesan pertama.
    await _ensureSession(text);

    // Simpan pesan user ke SQLite.
    await _chatDao.insertMessage(
      ChatMessageModel(
        sessionId: _sessionId!,
        role: 'user',
        content: text,
        createdAt: userTime,
      ),
    );

    // Ambil memori lintas-sesi yang tersimpan di SQLite.
    final memory = await _memoryDao.getAll();

    // Panggil AI real (Dattio / DeepSeek)
    final reply = await _aiService.sendMessage(
      userMessage: text,
      history: history,
      userMemory: memory,
    );

    if (!mounted) return;

    final botTime = DateTime.now();

    setState(() {
      _isTyping = false;
      _messages.add({
        'text': reply,
        'isFromUser': false,
        'timestamp': botTime,
      });
      _lastAddedIndex = _messages.length - 1;
    });

    _scrollToBottom();

    // Simpan balasan bot.
    await _chatDao.insertMessage(
      ChatMessageModel(
        sessionId: _sessionId!,
        role: 'assistant',
        content: reply,
        createdAt: botTime,
      ),
    );

    // Di background: cek apakah user menyebutkan fakta profil baru (nama, kampus, dsb).
    _extractAndSaveMemory(text, reply);
  }

  /// Ekstraksi fakta profil secara non-blocking di background.
  void _extractAndSaveMemory(String userText, String botReply) {
    _aiService
        .extractUserFacts(userText: userText, botReply: botReply)
        .then((facts) {
      if (facts.isNotEmpty) {
        _memoryDao.saveFacts(facts);
      }
    }).catchError((_) {});
  }

  /// Buat sesi chat baru kalau belum ada. Judul = 40 karakter pesan pertama.
  Future<void> _ensureSession(String firstMessage) async {
    if (_sessionId != null) return;

    final now = DateTime.now();
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}…'
        : firstMessage;
    final id = 'chat-${now.millisecondsSinceEpoch}';

    await _chatDao.upsertSession(
      ChatSessionModel(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );

    _sessionId = id;
    widget.onSessionCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCanvasBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header compact: menu ☰ / back + judul
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.showBackButton) {
                        Navigator.pop(context);
                      } else {
                        widget.onOpenSidebar?.call();
                      }
                    },
                    icon: SvgPicture.asset(
                      widget.showBackButton
                          ? 'assets/svg/ic_arrow_left.svg'
                          : 'assets/svg/ic_menu.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        darkEspresso,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, Color(0xFF8B6B4D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/svg/ic_sparkles.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asisten Jadwal',
                          style: sBold.copyWith(
                            color: darkEspresso,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Online • siap bantu',
                              style: xxxsMedium.copyWith(color: mutedTaupe),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/svg/ic_more_horizontal.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        mutedTaupe,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat list + input bar
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        widget.showInputBar ? 140 : 104,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return const TypingBubble();
                        }
                        final msg = _messages[index];
                        final isNewest = index == _lastAddedIndex;

                        return AnimatedMessageEntry(
                          key: ValueKey(index),
                          animate: isNewest,
                          child: ChatMessageBubble(
                            text: msg['text'] as String,
                            isUser: msg['isFromUser'] as bool,
                            timestamp: msg['timestamp'] as DateTime,
                          ),
                        );
                      },
                    ),
                  ),

                  // Floating input bar (capsule rounded penuh) — disembunyikan
                  // jika shell menyediakan bar bawah morphed.
                  if (widget.showInputBar)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFEADBCE),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: darkEspresso.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Tombol plus (kiri)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: _circleButton(
                                    icon: 'assets/svg/ic_plus.svg',
                                    filled: false,
                                    onTap: () {},
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Text input — teks panjang turun ke baris baru
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      style: smMedium.copyWith(
                                        color: darkEspresso,
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: 4,
                                      minLines: 1,
                                      onChanged: _onTextChanged,
                                      decoration: InputDecoration(
                                        hintText: 'Tulis pesan...',
                                        hintStyle: smRegular.copyWith(
                                          color: mutedTaupe,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        filled: false,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Tombol kanan: mic (kosong) / send (ada teks)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                    child: _hasText
                                        ? _circleButton(
                                            key: const ValueKey('send'),
                                            icon: 'assets/svg/ic_send.svg',
                                            filled: true,
                                            onTap: _sendMessage,
                                          )
                                        : _circleButton(
                                            key: const ValueKey('mic'),
                                            icon: 'assets/svg/ic_mic.svg',
                                            filled: true,
                                            onTap: () {},
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol bulat kecil untuk input bar (plus / mic / send).
  Widget _circleButton({
    Key? key,
    required String icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [primaryColor, Color(0xFF8B6B4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : warmCanvasBg,
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(color: const Color(0xFFEADBCE), width: 1),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              filled ? Colors.white : darkEspresso,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
