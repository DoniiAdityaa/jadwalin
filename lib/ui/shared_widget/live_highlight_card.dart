import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

enum HighlightState { live, upcoming, none }

/// Kartu highlight untuk agenda yang sedang berlangsung atau berikutnya.
///
/// Tetap ikut bahasa desain Warm Mocha: background putih, border oat,
/// satu aksen warna kategori, tipografi tenang.
class LiveHighlightCard extends StatefulWidget {
  const LiveHighlightCard({
    super.key,
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.category = 'KULIAH',
    this.iconAsset = 'assets/svg/ic_book_open.svg',
    this.accentColor = const Color(0xFF2563EB),
    this.now,
    this.tickInterval = const Duration(seconds: 30),
    this.dimmed = false,
  });

  final String title;
  final String? location;
  final DateTime start;
  final DateTime end;
  final String category;
  final String iconAsset;
  final Color accentColor;
  final DateTime? now;
  final Duration tickInterval;

  /// Kalau true, seluruh kartu dibuat tenang (dipakai untuk kartu di belakang
  /// tumpukan). Bukan sama dengan status "SELESAI".
  final bool dimmed;

  @override
  State<LiveHighlightCard> createState() => _LiveHighlightCardState();
}

class _LiveHighlightCardState extends State<LiveHighlightCard> {
  Timer? _timer;

  DateTime get _now => widget.now ?? DateTime.now();

  HighlightState get _state {
    final now = _now;
    if (now.isAfter(widget.start) && now.isBefore(widget.end)) {
      return HighlightState.live;
    }
    if (now.isBefore(widget.start)) return HighlightState.upcoming;
    return HighlightState.none;
  }

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant LiveHighlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dimmed != widget.dimmed) _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.now == null && !widget.dimmed) {
      _timer = Timer.periodic(widget.tickInterval, (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    final total = widget.end.difference(widget.start).inSeconds;
    if (total <= 0) return 0;
    final elapsed = _now.difference(widget.start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes < 60) return '$totalMinutes mnt';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '$hours jam' : '$hours jam $minutes mnt';
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _state == HighlightState.live;
    final isUpcoming = _state == HighlightState.upcoming;
    final isDone = _state == HighlightState.none;

    // Dimmed = dipakai di kartu belakang tumpukan (tidak terkait status selesai)
    final effectiveAccent =
        widget.dimmed ? mutedTaupe : (isDone ? mutedTaupe : widget.accentColor);
    final accent = effectiveAccent;
    final label = isLive
        ? 'SEDANG BERLANGSUNG'
        : isUpcoming
            ? 'BERIKUTNYA'
            : 'SELESAI';
    final countdown = isLive
        ? 'Selesai ${_formatDuration(widget.end.difference(_now))} lagi'
        : isUpcoming
            ? 'Mulai ${_formatDuration(widget.start.difference(_now))} lagi'
            : 'Sudah lewat';

    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.dimmed ? const Color(0xFFFDFAF7) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLive
                ? accent.withValues(alpha: 0.35)
                : const Color(0xFFEADBCE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? accent.withValues(alpha: 0.10)
                  : const Color(0x08000000),
              blurRadius: isLive ? 18 : 6,
              offset: Offset(0, isLive ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isLive && !widget.dimmed) ...[
                            _PulseDot(color: accent),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            label,
                            style: xxxsBold.copyWith(
                              color: accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              widget.category,
                              style: xxxsBold.copyWith(
                                color: accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: smBold.copyWith(
                          color: darkEspresso,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          '${_formatTime(widget.start)} - ${_formatTime(widget.end)} WIB',
                          if (widget.location != null) widget.location!,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: xsMedium.copyWith(color: mutedTaupe),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            countdown,
                            style: xsSemiBold.copyWith(color: accent),
                          ),
                        ],
                      ),
                      if (isLive && !widget.dimmed) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(
                                height: 3,
                                color: const Color(0xFFF1E7DC),
                              ),
                              FractionallySizedBox(
                                widthFactor: _progress.clamp(0.02, 1.0),
                                child: Container(
                                  height: 3,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
