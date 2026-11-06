import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Global Reusable SnackBar / Messenger Toast untuk PokéAtlas
/// Desain floating pill elegan, responsif, dan konsisten di seluruh aplikasi.
class AppMessenger {
  AppMessenger._();

  /// Menampilkan SnackBar kustom dengan ikon Pokéball atau ikon custom
  static void show(
    BuildContext context, {
    required String message,
    String? iconAsset,
    IconData? icon,
    Color backgroundColor = bgDark,
    Color textColor = textLightPrimary,
    Duration duration = const Duration(milliseconds: 1800),
    bool triggerHaptic = true,
  }) {
    if (triggerHaptic) {
      HapticFeedback.selectionClick();
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (iconAsset != null) ...[
              Image.asset(
                iconAsset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: smMedium.copyWith(
                  color: textColor,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        duration: duration,
      ),
    );
  }

  /// Preset: Menampilkan snackbar pemilihan Pokémon / Region
  static void showSelected(
    BuildContext context, {
    required String title,
    String iconAsset = 'assets/images/icons/pokeball.png',
  }) {
    show(
      context,
      message: title,
      iconAsset: iconAsset,
    );
  }

  /// Preset: Info singkat atau fitur yang sedang dikembangkan
  static void showComingSoon(
    BuildContext context, {
    required String featureName,
  }) {
    show(
      context,
      message: '🧬 $featureName coming soon!',
      duration: const Duration(milliseconds: 1500),
    );
  }

  /// Preset: Notifikasi sukses
  static void showSuccess(
    BuildContext context, {
    required String message,
  }) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF0F172A),
    );
  }
}
