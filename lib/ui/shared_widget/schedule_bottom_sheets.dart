import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Model data lokal untuk interaksi timeline & calendar detail
class TimelineItem {
  TimelineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.accentColor,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.location,
    this.iconAsset = 'assets/svg/ic_book_open.svg',
  });

  final String id;
  String title;
  String category;
  Color accentColor;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String? location;
  String iconAsset;

  int get durationMinutes {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return (end - start).clamp(15, 24 * 60);
  }

  String get timeRangeString {
    final sH = startHour.toString().padLeft(2, '0');
    final sM = startMinute.toString().padLeft(2, '0');
    final eH = endHour.toString().padLeft(2, '0');
    final eM = endMinute.toString().padLeft(2, '0');
    return '$sH:$sM - $eH:$eM WIB';
  }
}

/// Helper modal bottom sheet untuk Detail & Tambah/Edit Jadwal
class ScheduleBottomSheets {
  ScheduleBottomSheets._();

  /// 1. Detail Read-Only Sheet (dengan tombol Edit & Hapus)
  static Future<void> showDetail({
    required BuildContext context,
    required TimelineItem item,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEADBCE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Badge & Actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: xxxsBold.copyWith(
                        color: item.accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Edit Button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: SvgPicture.asset(
                      'assets/svg/ic_edit.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        darkEspresso,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: SvgPicture.asset(
                      'assets/svg/ic_trash.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        errorColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                style: lBold.copyWith(color: darkEspresso, height: 1.25),
              ),
              const SizedBox(height: 16),

              // Waktu Info Box
              _infoRow(
                icon: 'assets/svg/ic_clock.svg',
                title: item.timeRangeString,
                subtitle: '${item.durationMinutes} Menit',
              ),
              const SizedBox(height: 12),

              // Lokasi Info Box (kalau ada)
              if (item.location != null && item.location!.isNotEmpty) ...[
                _infoRow(
                  icon: 'assets/svg/ic_map_pin.svg',
                  title: item.location!,
                  subtitle: 'Lokasi Pertemuan',
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 2. Form Add / Edit Jadwal Sheet (Start time pre-filled dari long press)
  static Future<void> showAddOrEdit({
    required BuildContext context,
    TimelineItem? initialItem,
    int? defaultStartHour,
    int? defaultStartMinute,
    required ValueChanged<TimelineItem> onSave,
  }) {
    final titleController = TextEditingController(text: initialItem?.title ?? '');
    final locationController = TextEditingController(text: initialItem?.location ?? '');

    int sH = initialItem?.startHour ?? defaultStartHour ?? 9;
    int sM = initialItem?.startMinute ?? defaultStartMinute ?? 0;
    int eH = initialItem?.endHour ?? (sH + 1);
    int eM = initialItem?.endMinute ?? sM;

    String selectedCategory = initialItem?.category ?? 'KULIAH';

    final categories = <String, Color>{
      'KULIAH': const Color(0xFF2563EB),
      'ORGANISASI': const Color(0xFFD97706),
      'BOOTCAMP': const Color(0xFF059669),
      'DEADLINE': const Color(0xFFDC2626),
    };

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatTime(int h, int m) {
              return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEADBCE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      initialItem == null ? 'Tambah Jadwal Baru ✍️' : 'Ubah Jadwal ✏️',
                      style: mBold.copyWith(color: darkEspresso),
                    ),
                    const SizedBox(height: 16),

                    // Input Judul
                    TextField(
                      controller: titleController,
                      style: smMedium.copyWith(color: darkEspresso),
                      decoration: InputDecoration(
                        hintText: 'Nama agenda atau mata kuliah...',
                        hintStyle: smRegular.copyWith(color: mutedTaupe),
                        filled: true,
                        fillColor: warmCanvasBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Kategori Selector
                    Row(
                      children: categories.entries.map((entry) {
                        final isSel = selectedCategory == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedCategory = entry.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? entry.value : entry.value.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.key,
                                style: xxsBold.copyWith(
                                  color: isSel ? Colors.white : entry.value,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Time Range Selector
                    Row(
                      children: [
                        Expanded(
                          child: _timePickerButton(
                            label: 'Jam Mulai',
                            timeString: formatTime(sH, sM),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: sH, minute: sM),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  sH = picked.hour;
                                  sM = picked.minute;
                                  if (eH < sH || (eH == sH && eM <= sM)) {
                                    eH = (sH + 1) % 24;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _timePickerButton(
                            label: 'Jam Selesai',
                            timeString: formatTime(eH, eM),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: eH, minute: eM),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  eH = picked.hour;
                                  eM = picked.minute;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Lokasi Input
                    TextField(
                      controller: locationController,
                      style: smMedium.copyWith(color: darkEspresso),
                      decoration: InputDecoration(
                        hintText: 'Lokasi (opsional, misal: Gedung D / Zoom)',
                        hintStyle: smRegular.copyWith(color: mutedTaupe),
                        filled: true,
                        fillColor: warmCanvasBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;

                          final result = TimelineItem(
                            id: initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text.trim(),
                            category: selectedCategory,
                            accentColor: categories[selectedCategory] ?? primaryColor,
                            startHour: sH,
                            startMinute: sM,
                            endHour: eH,
                            endMinute: eM,
                            location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                            iconAsset: selectedCategory == 'KULIAH'
                                ? 'assets/svg/ic_book_open.svg'
                                : selectedCategory == 'ORGANISASI'
                                    ? 'assets/svg/ic_users.svg'
                                    : 'assets/svg/ic_cpu.svg',
                          );

                          Navigator.pop(context);
                          onSave(result);
                        },
                        child: Text(
                          initialItem == null ? 'Simpan Agenda' : 'Perbarui Agenda',
                          style: smBold.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _timePickerButton({
    required String label,
    required String timeString,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: warmCanvasBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: xxsRegular.copyWith(color: mutedTaupe)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(timeString, style: smBold.copyWith(color: darkEspresso)),
                const Spacer(),
                SvgPicture.asset(
                  'assets/svg/ic_clock.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warmCanvasBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              icon,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: sSemiBold.copyWith(color: darkEspresso)),
              const SizedBox(height: 2),
              Text(subtitle, style: xsRegular.copyWith(color: mutedTaupe)),
            ],
          ),
        ],
      ),
    );
  }
}
