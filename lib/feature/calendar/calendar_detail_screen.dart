import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/interactive_timeline.dart';
import 'package:jadwalin/ui/shared_widget/mini_calendar.dart';
import 'package:jadwalin/ui/shared_widget/schedule_bottom_sheets.dart';
import 'package:jadwalin/ui/typography.dart';

class CalendarDetailScreen extends StatefulWidget {
  const CalendarDetailScreen({
    super.key,
    required this.initialDate,
    this.focusHour,
    this.focusMinute = 0,
  });

  final DateTime initialDate;

  /// Jam awal yang ingin difokuskan di timeline (opsional).
  /// Dipakai saat membuka detail dari kartu jadwal tertentu di Home.
  final int? focusHour;

  /// Menit awal fokus (default 0).
  final int focusMinute;

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _weekdayShort = [
    'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab',
  ];

  late DateTime _selectedDate;
  late ScrollController _monthScrollController;
  late ScrollController _dateScrollController;
  final ScrollController _timelineScrollController = ScrollController();

  // Progress collapse header: 0.0 = expanded, 1.0 = collapsed
  double _collapseT = 0.0;
  static const double _collapseDistance = 110.0;

  // Dummy List Jadwal untuk hari yang dipilih
  final List<TimelineItem> _schedules = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _monthScrollController = ScrollController();
    _dateScrollController = ScrollController();

    _timelineScrollController.addListener(_onTimelineScroll);
    _loadSampleSchedules();

    // Scroll otomatis ke tanggal terpilih setelah render pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
      _scrollTimelineToFocus();
    });
  }

  /// Gulir timeline ke jam yang difokuskan (dari kartu jadwal Home).
  void _scrollTimelineToFocus() {
    final hour = widget.focusHour;
    if (hour == null) return;
    if (!_timelineScrollController.hasClients) return;

    // Tinggi tiap jam di timeline = 68.0 (lihat InteractiveTimeline).
    const double hourHeight = 68.0;
    final target = (hour * hourHeight) +
        (widget.focusMinute / 60.0 * hourHeight) -
        80.0;

    _timelineScrollController.animateTo(
      target.clamp(
        0.0,
        _timelineScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _dateScrollController.dispose();
    _timelineScrollController.removeListener(_onTimelineScroll);
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _onTimelineScroll() {
    final off = _timelineScrollController.offset;
    final t = (off / _collapseDistance).clamp(0.0, 1.0);
    if ((t - _collapseT).abs() > 0.005) {
      setState(() => _collapseT = t);
    }
  }

  void _loadSampleSchedules() {
    _schedules.addAll([
      TimelineItem(
        id: '1',
        title: 'Kalkulus & Aljabar Linear',
        category: 'KULIAH',
        accentColor: const Color(0xFF2563EB),
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 30,
        location: 'Gedung D (R. 302)',
      ),
      TimelineItem(
        id: '2',
        title: 'Algoritma & Pemrograman II',
        category: 'KULIAH',
        accentColor: const Color(0xFF2563EB),
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 45,
        location: 'Lab Komputer 4',
      ),
      TimelineItem(
        id: '3',
        title: 'Rapat Rundown Dies Natalis',
        category: 'ORGANISASI',
        accentColor: const Color(0xFFD97706),
        startHour: 13,
        startMinute: 30,
        endHour: 15,
        endMinute: 0,
        location: 'Sekre BEM Gedung F',
      ),
      TimelineItem(
        id: '4',
        title: 'Flutter Mobile Development',
        category: 'BOOTCAMP',
        accentColor: const Color(0xFF059669),
        startHour: 19,
        startMinute: 30,
        endHour: 21,
        endMinute: 0,
        location: 'Online (Google Meet)',
      ),
    ]);
  }

  void _scrollToSelectedDate() {
    final dayIndex = _selectedDate.day - 1;
    // Estimasi lebar tiap item tanggal = 54 + padding 8 = 62
    final offset = (dayIndex * 62.0) - 120;
    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onMonthTapped(int monthIndex) {
    setState(() {
      final daysInTargetMonth = DateTime(_selectedDate.year, monthIndex + 2, 0).day;
      final targetDay = _selectedDate.day.clamp(1, daysInTargetMonth);
      _selectedDate = DateTime(_selectedDate.year, monthIndex + 1, targetDay);
    });
    _scrollToSelectedDate();
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _scrollToSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    final daysInCurrentMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor: warmCanvasBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar transparan di atas canvas (tidak ikut sheet putih)
            _buildAppBar(),

            // Sheet putih: bulan + tanggal + timeline, rounded di atas
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // 1. Month strip (collapse: fade + slide up)
                    _collapsible(
                      height: 32.0 * (1 - _collapseT),
                      child: Opacity(
                        opacity: 1 - _collapseT,
                        child: _buildMonthStrip(),
                      ),
                    ),

                    // 2. Date strip (collapse: fade + height menyusut)
                    _collapsible(
                      height: 84.0 * (1 - _collapseT),
                      child: Opacity(
                        opacity: 1 - _collapseT,
                        child: _buildDateStrip(daysInCurrentMonth),
                      ),
                    ),

                    // 3. Timeline (scroll driving the collapse)
                    Expanded(
                      child: InteractiveTimeline(
                        items: _schedules,
                        selectedDate: _selectedDate,
                        scrollController: _timelineScrollController,
                        onItemTapped: (item) {
                          // Tap -> Buka Detail Read-Only
                          ScheduleBottomSheets.showDetail(
                            context: context,
                            item: item,
                            onEdit: () {
                              // Dari detail klik Edit -> buka form edit
                              ScheduleBottomSheets.showAddOrEdit(
                                context: context,
                                initialItem: item,
                                onSave: (updated) {
                                  setState(() {
                                    final idx = _schedules.indexWhere(
                                      (s) => s.id == updated.id,
                                    );
                                    if (idx != -1) _schedules[idx] = updated;
                                  });
                                },
                              );
                            },
                            onDelete: () {
                              setState(() {
                                _schedules.removeWhere((s) => s.id == item.id);
                              });
                            },
                          );
                        },
                        onEmptySlotLongPressed: (hour, minute) {
                          // Long press slot kosong -> Tambah Jadwal, jam pre-fill
                          ScheduleBottomSheets.showAddOrEdit(
                            context: context,
                            defaultStartHour: hour,
                            defaultStartMinute: minute,
                            onSave: (newItem) {
                              setState(() {
                                _schedules.add(newItem);
                              });
                            },
                          );
                        },
                        onItemUpdated: (updated) {
                          // Drag atau resize selesai -> update data
                          setState(() {
                            final idx =
                                _schedules.indexWhere((s) => s.id == updated.id);
                            if (idx != -1) _schedules[idx] = updated;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wrapper animasi tinggi untuk bagian header yang bisa collapse.
  Widget _collapsible({required double height, required Widget child}) {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: height,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: SvgPicture.asset(
              'assets/svg/ic_arrow_left.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(darkEspresso, BlendMode.srcIn),
            ),
          ),
          const Spacer(),
          // Title fade out saat collapse, ganti info tanggal
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _collapseT > 0.6
                ? Text(
                    _formattedSelectedDate,
                    key: const ValueKey('collapsed'),
                    style: mBold.copyWith(
                      color: darkEspresso,
                      letterSpacing: -0.2,
                    ),
                  )
                : Text(
                    'Detail Jadwal',
                    key: const ValueKey('expanded'),
                    style: mBold.copyWith(
                      color: darkEspresso,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
          const Spacer(),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  String get _formattedSelectedDate {
    final d = _selectedDate;
    final monthShort = _monthNames[d.month - 1].substring(0, 3);
    return '${d.day} $monthShort ${d.year}';
  }

  /// Strip Bulan Horizontal (Jan, Feb, Mar, ...) dengan fade shadow kiri-kanan
  Widget _buildMonthStrip() {
    return Stack(
      children: [
        SizedBox(
          height: 32,
          child: ListView.builder(
            controller: _monthScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _monthNames.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedDate.month == (index + 1);

              return GestureDetector(
                onTap: () => _onMonthTapped(index),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    _monthNames[index],
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? darkEspresso : mutedTaupe.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Fade gradient kiri
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 30,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        // Fade gradient kanan
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 30,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Row Tanggal Horizontal (21, 22, 23, 24...) dengan fade gradient kiri-kanan
  Widget _buildDateStrip(int totalDays) {
    return Stack(
      children: [
        SizedBox(
          height: 72,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: totalDays,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(_selectedDate.year, _selectedDate.month, day);
              final isSelected = _selectedDate.day == day;
              final dayName = _weekdayShort[date.weekday % 7];

              // Dot agenda: dummy set + jadwal yang ada di tanggal ini
              final hasEvent = CalendarEventDummy.eventDayNumbers.contains(day) ||
                  (isSelected && _schedules.isNotEmpty);

              // Penanda hari ini
              final now = DateTime.now();
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return GestureDetector(
                onTap: () => _onDateTapped(date),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Kotak rounded 10px, gradient mocha (konsisten MiniCalendar)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [primaryColor, Color(0xFF8B6B4D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFEADBCE),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x405C4033),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: const Alignment(0, -0.15),
                              child: Text(
                                '$day',
                                style: (isSelected ? xsBold : xsMedium).copyWith(
                                  color: isSelected ? Colors.white : darkEspresso,
                                ),
                              ),
                            ),
                            if (hasEvent)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? oatMilkPill
                                        : secondaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSelected
                                                ? oatMilkPill
                                                : secondaryColor)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (isToday)
                              Positioned(
                                top: 4,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Singkatan Nama Hari (Sen, Sel, Rab...)
                      Text(
                        dayName,
                        style: xxsSemiBold.copyWith(
                          color: isSelected ? darkEspresso : mutedTaupe,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Fade gradient kiri
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 32,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        // Fade gradient kanan
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 32,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
