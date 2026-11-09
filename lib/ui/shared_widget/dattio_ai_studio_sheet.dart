import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';
import 'package:lottie/lottie.dart';

/// Sheet "Dattio AI Studio" — panel unggah dokumen penuh untuk mengekstrak
/// jadwal dari PDF KRS, screenshot chat grup, atau foto poster.
///
/// Karakter visual Warm Mocha:
/// - Header gradient mocha-caramel dengan Lottie AI Orb mengambang di tengah
/// - Judul besar + subteks tipis, status badge "AI Reader"
/// - 3 kartu sumber vertikal besar dengan ikon 52px, gradien tint, dan
///   indikator chevron
/// - Footer: tombol "Tempel teks manual" + hint privasi
///
/// Animasi masuk: slide-up + fade + slight scale (Curves.easeOutQuart).
class DattioAiStudioSheet extends StatefulWidget {
  const DattioAiStudioSheet({
    super.key,
    required this.onPickSource,
    required this.onManualText,
  });

  /// Callback saat sumber file dipilih. Argumen: `pdf`, `image`, atau `chat`.
  final ValueChanged<String> onPickSource;

  /// Callback saat pengguna memilih input teks manual.
  final VoidCallback onManualText;

  @override
  State<DattioAiStudioSheet> createState() => _DattioAiStudioSheetState();
}

class _DattioAiStudioSheetState extends State<DattioAiStudioSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _scale;

  static const List<_SourceData> _sources = [
    _SourceData(
      key: 'pdf',
      icon: 'assets/svg/ic_file_text.svg',
      title: 'Jadwal KRS / PDF',
      subtitle: 'Auto-generate jadwal kuliah 16 minggu dari dokumen PDF',
      badge: '16 Minggu',
      tintBg: Color(0x14A67C52),
      tintFg: Color(0xFFA67C52),
      accent: Color(0xFFA67C52),
    ),
    _SourceData(
      key: 'image',
      icon: 'assets/svg/ic_image.svg',
      title: 'Screenshot Chat WA / Discord',
      subtitle: 'Tempel tangkapan layar pengumuman grup jadi jadwal',
      badge: 'Instan',
      tintBg: Color(0x14C88A58),
      tintFg: Color(0xFFC88A58),
      accent: Color(0xFFC88A58),
    ),
    _SourceData(
      key: 'chat',
      icon: 'assets/svg/ic_chat.svg',
      title: 'Tempel Teks Chat',
      subtitle: 'Salin percakapan WhatsApp atau Discord langsung sebagai teks',
      badge: 'Teks',
      tintBg: Color(0x144A6B40),
      tintFg: Color(0xFF4A6B40),
      accent: Color(0xFF4A6B40),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutQuart,
    );
    _fade = curve;
    _slide = Tween<double>(begin: 36, end: 0).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.88;

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: Transform.scale(
              scale: _scale.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._sources.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SourceCard(
                            data: s,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onPickSource(s.key);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildManualButton(),
                      const SizedBox(height: 14),
                      _buildPrivacyHint(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Latar gradient Warm Mocha
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7A5233),
                  Color(0xFFA67C52),
                  Color(0xFFC88A58)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Ornamen lingkaran halus
          Positioned(
            top: -60,
            right: -40,
            child: _orbBlur(180, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: _orbBlur(140, Colors.white.withValues(alpha: 0.05)),
          ),

          // Lottie AI Orb mengambang
          Positioned(
            top: 4,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animation/ai_orb.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),

          // Teks di bawah orb
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/ic_sparkles.svg',
                            width: 10,
                            height: 10,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI Asisten',
                            style: xxxsBold.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ubah apa pun jadi jadwal',
                  style: lBold.copyWith(
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kirim PDF, screenshot chat, atau tempel teks — Ai yang susun.',
                  style: xsRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Drag handle
          Positioned(
            top: 10,
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orbBlur(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildManualButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onManualText();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: warmCanvasBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADBCE), width: 1),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/ic_clipboard.svg',
                width: 17,
                height: 17,
                colorFilter: const ColorFilter.mode(
                  primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tempel teks manual',
                  style: sSemiBold.copyWith(color: darkEspresso),
                ),
              ),
              SvgPicture.asset(
                'assets/svg/ic_chevron_right.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  mutedTaupe,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/svg/ic_check_circle.svg',
          width: 11,
          height: 11,
          colorFilter: const ColorFilter.mode(mutedTaupe, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Dokumen hanya diproses untuk membuat jadwal.',
            style: xxxsMedium.copyWith(color: mutedTaupe),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Kartu besar sumber dokumen.
class _SourceCard extends StatefulWidget {
  const _SourceCard({required this.data, required this.onTap});

  final _SourceData data;
  final VoidCallback onTap;

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEADBCE), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ikon dalam kotak tint
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.data.tintBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  widget.data.icon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    widget.data.tintFg,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.data.title,
                            style: smBold.copyWith(
                              color: darkEspresso,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.data.tintBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.data.badge,
                            style: xxxsBold.copyWith(
                              color: widget.data.tintFg,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.data.subtitle,
                      style: xsRegular.copyWith(
                        color: mutedTaupe,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: warmCanvasBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEADBCE),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/svg/ic_chevron_right.svg',
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    widget.data.accent,
                    BlendMode.srcIn,
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

class _SourceData {
  const _SourceData({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.tintBg,
    required this.tintFg,
    required this.accent,
  });

  final String key;
  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color tintBg;
  final Color tintFg;
  final Color accent;
}
