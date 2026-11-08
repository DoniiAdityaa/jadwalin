import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Kartu rangkuman sukses yang tampil saat seluruh agenda hari ini sudah lewat.
///
/// Menggantikan kartu abu-abu "SELESAI Sudah lewat" agar terasa rewarding.
class AllDoneCard extends StatelessWidget {
  const AllDoneCard({
    super.key,
    this.totalCompleted = 4,
    this.onViewTomorrow,
  });

  /// Jumlah agenda yang sudah diselesaikan hari ini.
  final int totalCompleted;

  /// Aksi membuka agenda besok.
  final VoidCallback? onViewTomorrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD1FAE5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C059669),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon centang hijau emerald lembut
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/svg/ic_check_circle.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Color(0xFF059669),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Teks apresiasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Semua agenda selesai!',
                      style: smBold.copyWith(color: darkEspresso),
                    ),
                    const SizedBox(width: 4),
                    const Text('🎉', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalCompleted agenda tuntas hari ini. Istirahat yang cukup!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: xsRegular.copyWith(
                    color: mutedTaupe,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol aksi "Besok"
          Material(
            color: oatMilkPill,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onViewTomorrow,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Besok',
                      style: xsSemiBold.copyWith(color: primaryColor),
                    ),
                    const SizedBox(width: 2),
                    SvgPicture.asset(
                      'assets/svg/ic_chevron_right.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
