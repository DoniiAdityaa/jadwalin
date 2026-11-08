import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/config/service_locator.dart';
import 'package:jadwalin/data/local/chat_dao.dart';
import 'package:jadwalin/data/local/models.dart';
import 'package:jadwalin/data/local/user_memory_dao.dart';
import 'package:jadwalin/data/service/ai_chat_service.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';
import 'package:lottie/lottie.dart';

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
      _lastAddedIndex = _messages.isEmpty ? null : _messages.length - 1;
    });
    _scrollToBottom();
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
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
                        widget.showInputBar ? 100 : 88,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return _typingBubble();
                        }
                        final msg = _messages[index];
                        final isNewest = index == _lastAddedIndex;
                        final isSingleGreeting =
                            _messages.length == 1 && !msg['isFromUser'];

                        Widget bubble = _chatBubble(
                          text: msg['text'] as String,
                          isUser: msg['isFromUser'] as bool,
                          timestamp: msg['timestamp'] as DateTime,
                        );

                        // Saat chat kosong / baru mulai, beri orb mengambang di atas sapaan.
                        if (isSingleGreeting) {
                          bubble = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 18),
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: Lottie.asset(
                                  'assets/animation/ai_orb.json',
                                  fit: BoxFit.contain,
                                  repeat: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              bubble,
                            ],
                          );
                        }

                        return _AnimatedMessageEntry(
                          key: ValueKey(index),
                          animate: isNewest,
                          child: bubble,
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Tombol plus (kiri)
                                _circleButton(
                                  icon: 'assets/svg/ic_plus.svg',
                                  filled: false,
                                  onTap: () {},
                                ),

                                const SizedBox(width: 10),

                                // Text input
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    style:
                                        smMedium.copyWith(color: darkEspresso),
                                    maxLines: 4,
                                    minLines: 1,
                                    textAlignVertical: TextAlignVertical.center,
                                    onChanged: _onTextChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Tulis pesan...',
                                      hintStyle:
                                          smRegular.copyWith(color: mutedTaupe),
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
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Tombol kanan: mic (kosong) / send (ada teks)
                                AnimatedSwitcher(
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

  /// Indikator bot sedang mengetik (tiga titik berdenyut).
  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: primaryColor50,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/svg/ic_sparkles.svg',
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: const Color(0xFFEADBCE), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Lottie.asset(
                    'assets/animation/ai_thinking.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(width: 10),
                _TypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Teks bubble dengan dukungan Markdown ringan (**bold**, bullet).
  Widget _formattedText({
    required String text,
    required bool isUser,
  }) {
    return _FormattedMessageText(text: text, isUser: isUser);
  }

  /// Widget Bubble Chat (method langsung di dalam State, konsisten tanpa class terpisah)
  Widget _chatBubble({
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar Bot (hanya muncul di bubble bot)
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: primaryColor50,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/svg/ic_sparkles.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [primaryColor, Color(0xFF8B6B4D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFEADBCE), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF261C14).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _formattedText(
                    text: text,
                    isUser: isUser,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.75)
                          : mutedTaupe.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Pembungkus animasi masuk untuk pesan baru (fade + slide up halus).
class _AnimatedMessageEntry extends StatefulWidget {
  const _AnimatedMessageEntry({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.animate ? 0.0 : 1.0,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Tiga titik berdenyut untuk indikator "bot sedang mengetik".
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = 0.35 + 0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Parser Markdown ringan: **bold**, *italic*, bullet `- `, dan baris baru.
/// Dipakai di dalam bubble chat agar balasan AI tampil rapi.
class _FormattedMessageText extends StatelessWidget {
  const _FormattedMessageText({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  static final RegExp _boldPattern = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _italicPattern =
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isUser ? Colors.white : darkEspresso,
      height: 1.4,
    );

    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      final isBullet =
          line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('• ');

      final content = isBullet ? line.trimLeft().substring(2) : line;

      final spans = _buildSpans(content, base);

      if (isBullet) {
        spans.insert(
          0,
          TextSpan(
            text: '• ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  isUser ? Colors.white.withValues(alpha: 0.8) : primaryColor,
            ),
          ),
        );
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i == lines.length - 1 ? 0 : 3,
            left: isBullet ? 4 : 0,
          ),
          child: Text.rich(
            TextSpan(style: base, children: spans),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<TextSpan> _buildSpans(String input, TextStyle base) {
    final spans = <TextSpan>[];
    var cursor = 0;

    // Kumpulkan semua match bold + italic, urut posisi.
    final matches = <_InlineMatch>[
      ..._boldPattern.allMatches(input).map(
            (m) => _InlineMatch(
              start: m.start,
              end: m.end,
              content: m.group(1)!,
              weight: FontWeight.w700,
            ),
          ),
      ..._italicPattern.allMatches(input).map(
            (m) => _InlineMatch(
              start: m.start,
              end: m.end,
              content: m.group(1)!,
              style: FontStyle.italic,
            ),
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final m in matches) {
      if (m.start < cursor) continue; // lewati yang tumpang tindih
      if (m.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.content,
          style: TextStyle(fontWeight: m.weight, fontStyle: m.style),
        ),
      );
      cursor = m.end;
    }

    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor)));
    }

    return spans;
  }
}

class _InlineMatch {
  const _InlineMatch({
    required this.start,
    required this.end,
    required this.content,
    this.weight,
    this.style,
  });

  final int start;
  final int end;
  final String content;
  final FontWeight? weight;
  final FontStyle? style;
}
