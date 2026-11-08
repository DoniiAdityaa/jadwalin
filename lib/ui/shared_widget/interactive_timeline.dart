import 'package:flutter/material.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/schedule_bottom_sheets.dart';
import 'package:jadwalin/ui/typography.dart';

/// Widget Interactive Timeline per jam dengan:
/// - Plot posisi card presisi berdasarkan jam & menit
/// - Long press area kosong -> trigger onEmptySlotLongPressed(hour, minute)
/// - Drag body card -> geser waktu mulai & selesai (durasi tetap)
/// - Drag bottom handle -> resize durasi / jam selesai
/// - Now indicator: garis merah horizontal di jam sekarang (kalau tanggal = hari ini)
class InteractiveTimeline extends StatefulWidget {
  const InteractiveTimeline({
    super.key,
    required this.items,
    required this.onItemTapped,
    required this.onEmptySlotLongPressed,
    required this.onItemUpdated,
    required this.selectedDate,
    this.scrollController,
  });

  final List<TimelineItem> items;
  final ValueChanged<TimelineItem> onItemTapped;
  final void Function(int hour, int minute) onEmptySlotLongPressed;
  final ValueChanged<TimelineItem> onItemUpdated;
  final DateTime selectedDate;
  final ScrollController? scrollController;

  @override
  State<InteractiveTimeline> createState() => _InteractiveTimelineState();
}

class _InteractiveTimelineState extends State<InteractiveTimeline> {
  static const double _hourHeight = 68.0;
  static const double _minuteHeight = _hourHeight / 60.0;
  static const int _totalHours = 24;

  // Sedang drag item apa?
  String? _draggingItemId;
  // Sedang resize item apa?
  String? _resizingItemId;

  // Offset akumulasi sementara saat dragging
  double _dragDy = 0.0;
  double _resizeDy = 0.0;

  late final ScrollController _internalScrollController;
  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController;

  /// Cek apakah timeline ini menampilkan hari ini (untuk now indicator)
  bool get _isShowingToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    return today == selected;
  }

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
    // Auto-scroll ke jam sekarang kalau showing today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isShowingToday) {
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final offset = (currentMinutes * _minuteHeight) - 200;
        final controller = _effectiveScrollController;
        if (controller.hasClients) {
          controller.animateTo(
            offset.clamp(0.0, controller.position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const totalTimelineHeight = _hourHeight * _totalHours;

    return SingleChildScrollView(
      controller: _effectiveScrollController,
      physics: const BouncingScrollPhysics(),
      child: GestureDetector(
        // Long Press Area Kosong
        onLongPressStart: (details) {
          final dy = details.localPosition.dy;
          // Hitung jam & bulatkan ke interval 15 menit
          final rawMinutes = (dy / _minuteHeight).clamp(0, 24 * 60 - 15).toInt();
          final snappedMinutes = (rawMinutes ~/ 15) * 15;
          final hour = snappedMinutes ~/ 60;
          final minute = snappedMinutes % 60;
          widget.onEmptySlotLongPressed(hour, minute);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: totalTimelineHeight,
          child: Stack(
            children: [
              // 1. Background Grid Garis Jam & Label Jam
              _buildBackgroundGrid(),

              // 2. Plot Kartu-kartu Jadwal
              ...widget.items.map((item) => _buildScheduleCard(item)),

              // 3. Garis Penanda Waktu Sekarang (di atas card, biar motong)
              if (_isShowingToday) _buildNowIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  /// Garis waktu sekarang (now indicator).
  Widget _buildNowIndicator() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final top = currentMinutes * _minuteHeight;

    return Positioned(
      top: top - 1,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            // Titik bulat merah pas di kiri dekat label jam
            Container(
              margin: const EdgeInsets.only(left: 48),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: errorColor.withValues(alpha: 0.6),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            // Garis horizontal membentang
            Expanded(
              child: Container(
                height: 1.5,
                color: errorColor.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Garis horizontal dan teks jam 00:00 - 23:00 di sisi kiri
  Widget _buildBackgroundGrid() {
    return Column(
      children: List.generate(_totalHours, (hour) {
        final label = '${hour.toString().padLeft(2, '0')}:00';

        return SizedBox(
          height: _hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label Jam
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: xxsSemiBold.copyWith(
                      color: mutedTaupe.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              // Garis Pemisah Jam Tipis
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 8),
                  color: const Color(0xFFEADBCE).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Render satu kartu jadwal yang bisa di-drag & di-resize
  Widget _buildScheduleCard(TimelineItem item) {
    final isDragging = _draggingItemId == item.id;
    final isResizing = _resizingItemId == item.id;

    // Hitung posisi awal
    final startMinutes = (item.startHour * 60) + item.startMinute;
    double top = startMinutes * _minuteHeight;
    double height = item.durationMinutes * _minuteHeight;

    // Apply offset sementara kalau lagi di-drag
    if (isDragging) {
      top += _dragDy;
    }
    // Apply offset sementara kalau lagi di-resize
    if (isResizing) {
      height += _resizeDy;
      if (height < 24.0) height = 24.0; // Minimal durasi
    }

    // Hindari keluar dari bounds 24 jam
    top = top.clamp(0.0, (_totalHours * _hourHeight) - height);

    return Positioned(
      top: top,
      left: 60, // Sebelah kanan label jam
      right: 16,
      height: height,
      child: Stack(
        children: [
          // Card Body (Bisa di-tap untuk detail & di-drag untuk pindah jam)
          GestureDetector(
            onTap: () => widget.onItemTapped(item),
            onVerticalDragStart: (_) {
              setState(() {
                _draggingItemId = item.id;
                _dragDy = 0.0;
              });
            },
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragDy += details.delta.dy;
              });
            },
            onVerticalDragEnd: (_) {
              _finishDrag(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDragging || isResizing
                      ? item.accentColor
                      : const Color(0xFFEADBCE),
                  width: isDragging || isResizing ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.accentColor.withValues(
                      alpha: isDragging || isResizing ? 0.25 : 0.08,
                    ),
                    blurRadius: isDragging || isResizing ? 16 : 8,
                    offset: Offset(0, isDragging || isResizing ? 6 : 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  // Aksen kiri tebal
                  Container(
                    width: 5,
                    height: double.infinity,
                    color: item.accentColor,
                  ),

                  // Isi Informasi Card (responsif terhadap tinggi card)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ClipRect(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header: Badge + Durasi (hanya kalau tinggi cukup)
                            if (height >= 52) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: xxxsBold.copyWith(
                                        color: item.accentColor,
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.durationMinutes} mnt',
                                    style: xxsSemiBold.copyWith(color: mutedTaupe),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                            ],

                            // Judul Jadwal
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sBold.copyWith(
                                color: darkEspresso,
                                fontSize: height < 50 ? 11.5 : 13,
                                height: 1.15,
                              ),
                            ),

                            // Jam (hanya jika tinggi mencukupi >= 75px / durasi > 1 jam)
                            if (height >= 75) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.timeRangeString,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: xxsRegular.copyWith(color: mutedTaupe),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resize Handle di Bagian Bawah Card (Tarik ke atas/bawah untuk ubah durasi)
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            height: 14,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {
                setState(() {
                  _resizingItemId = item.id;
                  _resizeDy = 0.0;
                });
              },
              onVerticalDragUpdate: (details) {
                setState(() {
                  _resizeDy += details.delta.dy;
                });
              },
              onVerticalDragEnd: (_) {
                _finishResize(item);
              },
              child: Center(
                child: Container(
                  width: 28,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selesai Drag Body -> Hitung ulang startHour & endHour dengan durasi tetap
  void _finishDrag(TimelineItem item) {
    if (_dragDy == 0.0) {
      setState(() => _draggingItemId = null);
      return;
    }

    final deltaMinutesRaw = (_dragDy / _minuteHeight).round();
    // Snap ke kelipatan 15 menit biar rapi
    final deltaMinutes = (deltaMinutesRaw / 15).round() * 15;

    final duration = item.durationMinutes;
    int currentStartMin = (item.startHour * 60) + item.startMinute;
    int newStartMin = (currentStartMin + deltaMinutes).clamp(0, (24 * 60) - duration);
    int newEndMin = newStartMin + duration;

    item.startHour = newStartMin ~/ 60;
    item.startMinute = newStartMin % 60;
    item.endHour = newEndMin ~/ 60;
    item.endMinute = newEndMin % 60;

    setState(() {
      _draggingItemId = null;
      _dragDy = 0.0;
    });

    widget.onItemUpdated(item);
  }

  /// Selesai Resize Handle -> Ubah endHour & endMinute (durasi berubah)
  void _finishResize(TimelineItem item) {
    if (_resizeDy == 0.0) {
      setState(() => _resizingItemId = null);
      return;
    }

    final deltaMinutesRaw = (_resizeDy / _minuteHeight).round();
    final deltaMinutes = (deltaMinutesRaw / 15).round() * 15;

    int currentEndMin = (item.endHour * 60) + item.endMinute;
    int startMin = (item.startHour * 60) + item.startMinute;
    // Minimal durasi 15 menit, maksimal 23:59
    int newEndMin = (currentEndMin + deltaMinutes).clamp(startMin + 15, 24 * 60);

    item.endHour = newEndMin ~/ 60;
    item.endMinute = newEndMin % 60;

    setState(() {
      _resizingItemId = null;
      _resizeDy = 0.0;
    });

    widget.onItemUpdated(item);
  }
}
