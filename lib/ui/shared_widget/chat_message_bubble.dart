import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/formatted_message_text.dart';

/// Format jam pesan chat, contoh `09:30 WIB`.
String formatChatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m WIB';
}

/// Bubble pesan chat (user atau bot) beserta avatar bot dan timestamp.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _BotAvatar(),
            const SizedBox(width: 10),
          ],
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
                  FormattedMessageText(text: text, isUser: isUser),
                  const SizedBox(height: 4),
                  Text(
                    formatChatTime(timestamp),
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

/// Bubble indikator "bot sedang mengetik" (tiga titik berdenyut halus).
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _BotAvatar(),
          const SizedBox(width: 10),
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
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

/// Avatar bulat kecil dengan ikon sparkles (dipakai bot & indikator mengetik).
class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: primaryColor50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/svg/ic_sparkles.svg',
        width: 14,
        height: 14,
        colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
      ),
    );
  }
}

/// Pembungkus animasi masuk untuk pesan baru (fade + slide up halus).
class AnimatedMessageEntry extends StatefulWidget {
  const AnimatedMessageEntry({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<AnimatedMessageEntry>
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
            // Wave offset per titik: i * 0.2
            final phase = ((_controller.value - i * 0.18) % 1.0);
            final wave = math.sin(phase * 2 * math.pi);
            final dy = wave > 0 ? -wave * 3.5 : 0.0;
            final opacity = 0.35 + 0.65 * (wave > 0 ? wave : 0.0);

            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
