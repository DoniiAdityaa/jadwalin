import 'package:flutter/material.dart';

/// Transisi halaman bergaya Shared Axis (Material Motion): halaman baru
/// masuk dengan fade + slide horizontal tipis, halaman lama memudar keluar.
///
/// Jauh lebih halus daripada slide bawaan iOS/Android untuk navigasi
/// master-detail (kartu jadwal -> detail kalender).
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            // Halaman lama: mengecil + memudar sedikit ke belakang.
            final secondaryCurve = CurvedAnimation(
              parent: secondary,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Halaman baru: fade + slide dari kanan.
            final enterFade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final enterSlide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(enterFade);

            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.03, 0),
              ).animate(secondaryCurve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.85)
                    .animate(secondaryCurve),
                child: SlideTransition(
                  position: enterSlide,
                  child: FadeTransition(
                    opacity: enterFade,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
