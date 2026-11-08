import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Kartu pengganti [LiveHighlightCard] saat tidak ada agenda yang sedang
/// berlangsung maupun berikutnya hari ini.
///
/// Tetap memakai bahasa desain Warm Mocha: background putih, border oat,
/// aksen mocha lembut, tipografi tenang.
class EmptyHighlightCard extends StatelessWidget {
  const EmptyHighlightCard({
    super.key,
    this.onAddSchedule,
  });

  /// Dipanggil saat pengguna menekan tombol tambah jadwal.
  /// Kalau null, tombol tetap tampil namun non-aktif.
  final VoidCallback? onAddSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon kalender dalam lingkaran oat
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: oatMilkPill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/svg/ic_calendar_days.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Belum ada agenda berikutnya',
                  style: smBold.copyWith(color: darkEspresso),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tambahkan jadwal atau pilih tanggal lain di kalender.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: xsRegular.copyWith(color: mutedTaupe, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol tambah
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onAddSchedule,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: SvgPicture.asset(
                  'assets/svg/ic_plus.svg',
                  width: 17,
                  height: 17,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
