import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/live_highlight_card.dart';
import 'package:jadwalin/ui/typography.dart';

/// Model item agenda untuk [StackedHighlightCards].
class HighlightCardItem {
  const HighlightCardItem({
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.category = 'KULIAH',
    this.iconAsset = 'assets/svg/ic_book_open.svg',
    this.accentColor = const Color(0xFF2563EB),
    this.onTap,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String category;
  final String iconAsset;
  final Color accentColor;
  final VoidCallback? onTap;
}

/// Carousel tumpukan kartu bertingkat horizontal untuk agenda hari ini di HomeScreen.
///
/// Kartu depan tampil penuh (dengan teks, timer, dan status).
/// Kartu belakang (depth 1 & 2) hanya berupa "badan kartu" dekoratif (tanpa teks)
/// sehingga dijamin TIDAK PERNAH tumpang tindih teks seperti bug sebelumnya.
class StackedHighlightCards extends StatefulWidget {
  const StackedHighlightCards({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.now,
    this.onIndexChanged,
  });

  final List<HighlightCardItem> items;
  final int initialIndex;
  final DateTime? now;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<StackedHighlightCards> createState() => _StackedHighlightCardsState();
}

class _StackedHighlightCardsState extends State<StackedHighlightCards>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  double _dragDx = 0.0;

  late final AnimationController _animController;
  late Animation<double> _slideAnimation;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.items.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.items.length - 1);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideAnimation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void didUpdateWidget(covariant StackedHighlightCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.items.length) {
      _currentIndex = widget.items.length - 1;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.items.length <= 1) return;
    // Wrap-around aktif: selalu bisa maju/mundur
    setState(() {
      _dragDx += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.items.length <= 1) return;

    final velocity = details.primaryVelocity ?? 0.0;
    const threshold = 70.0;

    final swipedLeft = _dragDx < -threshold || velocity < -450;
    final swipedRight = _dragDx > threshold || velocity > 450;

    if (swipedLeft) {
      _animateToNext(1);
    } else if (swipedRight) {
      _animateToNext(-1);
    } else {
      _animateBack();
    }
  }

  /// Animasi pindah kartu dengan wrap-around.
  ///
  /// `direction == 1` (swipe kiri) : kartu depan keluar ke kiri, kartu berikutnya
  ///                                 masuk dari kanan menuju tengah.
  /// `direction == -1` (swipe kanan): kartu depan keluar ke kanan, kartu sebelumnya
  ///                                 masuk dari kiri menuju tengah.
  void _animateToNext(int direction) {
    HapticFeedback.selectionClick();
    final width = MediaQuery.of(context).size.width;
    final target = direction > 0 ? -width * 0.85 : width * 0.85;

    _slideAnimation = Tween<double>(
      begin: _dragDx,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      final total = widget.items.length;
      setState(() {
        // Wrap-around: lewat batas kembali ke ujung seberang
        _currentIndex = (_currentIndex + direction) % total;
        if (_currentIndex < 0) _currentIndex += total;
        _dragDx = 0.0;
      });
      _animController.reset();
      widget.onIndexChanged?.call(_currentIndex);
    });
  }

  void _animateBack() {
    _slideAnimation = Tween<double>(
      begin: _dragDx,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _dragDx = 0.0;
      });
      _animController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final total = widget.items.length;
    final hasDepth1 = total >= 2;
    final hasDepth2 = total >= 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Counter indicator pill jika kartu > 1 (contoh: 2/4 dengan hint swipe)
        if (widget.items.length > 1) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 2, left: 2),
            child: Row(
              children: [
                Text(
                  'HIGHLIGHT HARI INI',
                  style: xxxsBold.copyWith(
                    color: mutedTaupe,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: oatMilkPill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentIndex + 1}/${widget.items.length}',
                        style: xxxsBold.copyWith(
                          color: darkEspresso,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'swipe ‹ ›',
                        style: xxxsMedium.copyWith(color: mutedTaupe),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Area tumpukan kartu
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final effectiveDx =
                  _animController.isAnimating ? _slideAnimation.value : _dragDx;
              final dragFraction = (effectiveDx.abs() / 240.0).clamp(0.0, 1.0);

              return GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // URUTAN PENTING DI STACK FLUTTER:
                    // Child pertama = PALING BAWAH (depth 2)
                    // Child kedua   = TENGAH (depth 1)
                    // Child ketiga  = PALING ATAS / DEPAN (depth 0)

                    // 1. Kartu Paling Belakang (depth 2) — dekoratif siluet
                    if (hasDepth2)
                      Positioned.fill(
                        child: _buildBackCardSiluet(
                          baseY: 18.0,
                          baseScale: 0.88,
                          baseOpacity: 0.40,
                          dragFraction: dragFraction,
                          accent: widget
                              .items[_wrapIndex(_currentIndex + 2)].accentColor,
                        ),
                      ),

                    // 2. Kartu Tengah (depth 1) — dekoratif siluet
                    if (hasDepth1)
                      Positioned.fill(
                        child: _buildBackCardSiluet(
                          baseY: 10.0,
                          baseScale: 0.94,
                          baseOpacity: 0.70,
                          dragFraction: dragFraction,
                          accent: widget
                              .items[_wrapIndex(_currentIndex + 1)].accentColor,
                        ),
                      ),

                    // 3. Kartu Depan (depth 0) — AKTIF dan menjadi layout anchor
                    _buildFrontCard(effectiveDx),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _wrapIndex(int index) {
    final len = widget.items.length;
    if (len == 0) return 0;
    final r = index % len;
    return r < 0 ? r + len : r;
  }

  /// Siluet kartu belakang: bersih, tanpa teks yang bikin tumpang tindih.
  /// Memakai warna putih dengan border oat + bayangan + strip aksen bawah.
  Widget _buildBackCardSiluet({
    required double baseY,
    required double baseScale,
    required double baseOpacity,
    required double dragFraction,
    required Color accent,
  }) {
    // Saat kartu depan ditarik, kartu belakang membesar & maju sedikit
    final scale = baseScale + (0.06 * dragFraction);
    final y = baseY - (8.0 * dragFraction);
    final opacity = (baseOpacity + (0.2 * dragFraction)).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, y),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFEADBCE),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu depan yang aktif, bisa di-drag, berotasi, dan nampilin konten asli.
  Widget _buildFrontCard(double dragDx) {
    final item = widget.items[_currentIndex];
    final rotation = (dragDx / 320.0) * (math.pi / 24.0);

    return Transform.translate(
      offset: Offset(dragDx, 0),
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: item.onTap,
          child: LiveHighlightCard(
            title: item.title,
            location: item.location,
            start: item.start,
            end: item.end,
            category: item.category,
            iconAsset: item.iconAsset,
            accentColor: item.accentColor,
            now: _now,
            dimmed: false,
          ),
        ),
      ),
    );
  }
}
