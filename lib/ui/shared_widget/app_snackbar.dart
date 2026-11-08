import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

enum AppSnackBarType {
  info,
  success,
  warning,
  error,
}

/// Global SnackBar / Toast dengan bahasa desain Warm Mocha "Jadwalin".
///
/// Karakter visual:
/// - Floating capsule rounded 16 dengan soft shadow
/// - Dark Espresso background (kontras tinggi, tidak nabrak canvas krem)
/// - Border oat lembut 1px
/// - Ikon SVG berlingkaran tint kategori (tanpa emoji)
/// - Tipografi Plus Jakarta Sans (`xsSemiBold` pesan, `xxxsRegular` subteks jika ada)
/// - Opsional tombol aksi / undo bergaya pill Warm Mocha
class AppSnackBar {
  AppSnackBar._();

  /// Tampilkan snackbar global dengan preset tipe.
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2400),
    bool triggerHaptic = true,
  }) {
    if (triggerHaptic) {
      HapticFeedback.lightImpact();
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final config = _configFor(type);

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: darkEspresso,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge ikon dengan background tint halus
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: config.tintBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  config.iconAsset,
                  width: 17,
                  height: 17,
                  colorFilter: ColorFilter.mode(
                    config.tintFg,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Pesan teks (+ optional subteks)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: xsSemiBold.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: xxxsMedium.copyWith(
                          color: const Color(0xFFD6C7B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Tombol aksi opsional (misal: "Batal" / "Lihat")
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        actionLabel,
                        style: xxsBold.copyWith(
                          color: secondaryColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Preset: Info biasa (default mocha).
  static void info(
    BuildContext context, {
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      type: AppSnackBarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Preset: Sukses (centang emerald).
  static void success(
    BuildContext context, {
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      type: AppSnackBarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Preset: Peringatan (segitiga amber).
  static void warning(
    BuildContext context, {
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      type: AppSnackBarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Preset: Error (tanda seru / silang coral merah).
  static void error(
    BuildContext context, {
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      subtitle: subtitle,
      type: AppSnackBarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Helper untuk fitur yang sedang dalam proses pengerjaan.
  static void comingSoon(
    BuildContext context, {
    required String featureName,
  }) {
    info(
      context,
      message: '$featureName segera hadir',
      subtitle: 'Fitur sedang dalam tahap pengembangan',
    );
  }

  static _TypeConfig _configFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const _TypeConfig(
          iconAsset: 'assets/svg/ic_circle_check.svg',
          tintBg: Color(0x2610B981),
          tintFg: Color(0xFF34D399),
        );
      case AppSnackBarType.warning:
        return const _TypeConfig(
          iconAsset: 'assets/svg/ic_triangle_alert.svg',
          tintBg: Color(0x26F59E0B),
          tintFg: Color(0xFFFBBF24),
        );
      case AppSnackBarType.error:
        return const _TypeConfig(
          iconAsset: 'assets/svg/ic_circle_alert.svg',
          tintBg: Color(0x26EF4444),
          tintFg: Color(0xFFF87171),
        );
      case AppSnackBarType.info:
        return const _TypeConfig(
          iconAsset: 'assets/svg/ic_info.svg',
          tintBg: Color(0x33A67C52),
          tintFg: secondaryColor,
        );
    }
  }
}

class _TypeConfig {
  const _TypeConfig({
    required this.iconAsset,
    required this.tintBg,
    required this.tintFg,
  });

  final String iconAsset;
  final Color tintBg;
  final Color tintFg;
}
