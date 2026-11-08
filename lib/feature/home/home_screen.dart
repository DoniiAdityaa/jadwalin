import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/typography.dart';
import 'package:jadwalin/feature/calendar/calendar_detail_screen.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/all_done_card.dart';
import 'package:jadwalin/ui/shared_widget/bouncing_tap.dart';
import 'package:jadwalin/ui/shared_widget/empty_highlight_card.dart';
import 'package:jadwalin/ui/shared_widget/live_highlight_card.dart';
import 'package:jadwalin/ui/shared_widget/mini_calendar.dart';
import 'package:jadwalin/ui/shared_widget/shared_axis_route.dart';
import 'package:jadwalin/ui/shared_widget/staggered_entrance.dart';

/// Model jadwal sederhana (dummy, belum pakai data layer).
class _DummySchedule {
  const _DummySchedule({
    required this.title,
    required this.location,
    required this.category,
    required this.iconAsset,
    required this.accentColor,
    required this.start,
    required this.end,
  });

  final String title;
  final String location;
  final String category;
  final String iconAsset;
  final Color accentColor;
  final DateTime start;
  final DateTime end;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  DateTime? _selectedDate;
  DateTime _currentMonth = DateTime.now();

  /// Jarak dari atas layar saat kartu mulai menempel.
  static const double _pinnedTop = 10.0;

  /// Tinggi header user + padding (posisi kalender saat scroll = 0).
  static const double _calendarRestTop = 74.0;

  /// Scroll offset saat kartu sudah benar-benar menempel.
  static const double _pinReachOffset = _calendarRestTop - _pinnedTop;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 0.0 = 1 baris (collapsed), 1.0 = bulan penuh.
  double _progressForOffset(double offset) {
    // Mulai mengecil setelah 16px, selesai tepat saat kartu menempel.
    const start = 16.0;
    final span = _pinReachOffset - start;
    if (span <= 0) return 1.0;
    return (1.0 - ((offset - start) / span)).clamp(0.0, 1.0);
  }

  /// Geser vertikal kartu sebelum menempel.
  double _translateForOffset(double offset) {
    final travel = _calendarRestTop - _pinnedTop - offset;
    return travel > 0 ? travel : 0.0;
  }

  /// Tanggal dipilih. Tap pada tanggal yang sama membuka detail kalender.
  void _onDateSelected(DateTime date) {
    final isSameSelected = _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;

    if (!isSameSelected) {
      setState(() {
        _selectedDate = date;
        _currentMonth = DateTime(date.year, date.month);
      });
      return;
    }

    final offset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if (offset < 8) {
      Navigator.of(context).push(
        SharedAxisPageRoute(
          builder: (_) => CalendarDetailScreen(initialDate: date),
        ),
      );
    }
  }

  /// Tombol panah atas: balik ke paling atas, kalender otomatis mekar lagi.
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  /// Ambil jadwal hari ini, diurutkan berdasarkan jam mulai.
  List<_DummySchedule> get _todaySchedules {
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    return [
      _DummySchedule(
        title: 'Kalkulus & Aljabar Linear',
        location: 'Gedung D (R. 302)',
        category: 'KULIAH',
        iconAsset: 'assets/svg/ic_book_open.svg',
        accentColor: const Color(0xFF2563EB),
        start: at(8, 0),
        end: at(9, 40),
      ),
      _DummySchedule(
        title: 'Algoritma & Pemrograman II',
        location: 'Lab Komputer 4',
        category: 'KULIAH',
        iconAsset: 'assets/svg/ic_cpu.svg',
        accentColor: const Color(0xFF2563EB),
        start: at(10, 0),
        end: at(11, 40),
      ),
      _DummySchedule(
        title: 'Rapat Finalisasi Rundown Dies Natalis',
        location: 'Sekre BEM Gedung F',
        category: 'ORGANISASI',
        iconAsset: 'assets/svg/ic_users.svg',
        accentColor: const Color(0xFFD97706),
        start: at(13, 30),
        end: at(15, 0),
      ),
      _DummySchedule(
        title: 'Flutter & Mobile Development',
        location: 'Online (Google Meet)',
        category: 'BOOTCAMP',
        iconAsset: 'assets/svg/ic_cpu.svg',
        accentColor: const Color(0xFF059669),
        start: at(19, 30),
        end: at(21, 0),
      ),
    ];
  }

  /// Jadwal yang sedang berlangsung atau yang berikutnya HARI INI.
  /// Jika semua sudah lewat atau kosong, kembalikan null.
  _DummySchedule? get _activeHighlightSchedule {
    final now = DateTime.now();
    final list = _todaySchedules;

    // 1. Sedang berlangsung sekarang
    for (final s in list) {
      if (now.isAfter(s.start) && now.isBefore(s.end)) return s;
    }
    // 2. Berikutnya yang belum mulai
    for (final s in list) {
      if (now.isBefore(s.start)) return s;
    }
    // 3. Jangan fallback ke list.last (agar tidak muncul kartu abu-abu selesai)
    return null;
  }

  /// True jika seluruh jadwal hari ini sudah lewat jamnya.
  bool get _isAllDoneToday {
    if (_todaySchedules.isEmpty) return false;
    final now = DateTime.now();
    return _todaySchedules.every((s) => now.isAfter(s.end));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCanvasBg,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, _) {
            final offset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
            final progress = _progressForOffset(offset);
            final translateY = _translateForOffset(offset);
            final isPinned = offset >= _pinReachOffset;

            return Stack(
              children: [
                // Lapisan 1: Scrollable content (Header User + Spacer Kalender + Jadwal)
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header User
                      _headerUser(),
                      const SizedBox(height: 16),

                      // Spacer cadangan tempat kalender saat posisi normal.
                      // Tinggi spacer mengecil seiring kalender mengkerut agar jadwal
                      // naik secara mulus mengikuti jari tanpa loncat.
                      SizedBox(
                        height: 126.0 + (progress * (318.0 - 126.0)) + 18.0,
                      ),

                      // Live Highlight Spotlight
                      // 1. Sedang ada agenda live / berikutnya -> kartu live aktif
                      if (_activeHighlightSchedule != null) ...[
                        _reveal(
                          0,
                          LiveHighlightCard(
                            title: _activeHighlightSchedule!.title,
                            location: _activeHighlightSchedule!.location,
                            start: _activeHighlightSchedule!.start,
                            end: _activeHighlightSchedule!.end,
                            category: _activeHighlightSchedule!.category,
                            iconAsset: _activeHighlightSchedule!.iconAsset,
                            accentColor: _activeHighlightSchedule!.accentColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]
                      // 2. Semua agenda hari ini selesai -> kartu sukses hijau reward
                      else if (_isAllDoneToday) ...[
                        _reveal(
                          0,
                          AllDoneCard(
                            totalCompleted: _todaySchedules.length,
                            onViewTomorrow: () {
                              final tomorrow =
                                  DateTime.now().add(const Duration(days: 1));
                              setState(() {
                                _selectedDate = tomorrow;
                                _currentMonth =
                                    DateTime(tomorrow.year, tomorrow.month);
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]
                      // 3. Memang belum ada jadwal hari ini -> kartu ajakan buat jadwal
                      else ...[
                        _reveal(0, const EmptyHighlightCard()),
                        const SizedBox(height: 24),
                      ],

                      // Sesi Pagi
                      _reveal(
                        1,
                        _sessionHeader(
                          title: 'Sesi Pagi',
                          timeRange: '05:00 - 11:59',
                          iconAsset: 'assets/svg/ic_sunrise.svg',
                          iconColor: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        2,
                        _scheduleCard(
                          category: 'KULIAH',
                          tagBg: const Color(0xFFEEF4FF),
                          tagColor: const Color(0xFF2563EB),
                          accentColor: const Color(0xFF2563EB),
                          title: 'Kalkulus & Aljabar Linear',
                          startTime: '08:00',
                          endTime: '09:40',
                          location: 'Gedung D (R. 302)',
                          startHour: 8,
                          statusLabel: 'Selesai',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        3,
                        _scheduleCard(
                          category: 'KULIAH',
                          tagBg: const Color(0xFFEEF4FF),
                          tagColor: const Color(0xFF2563EB),
                          accentColor: const Color(0xFF2563EB),
                          title: 'Algoritma & Pemrograman II',
                          startTime: '10:00',
                          endTime: '11:40',
                          location: 'Lab Komputer 4',
                          startHour: 10,
                          statusLabel: 'Berlangsung',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sesi Siang
                      _reveal(
                        4,
                        _sessionHeader(
                          title: 'Sesi Siang',
                          timeRange: '12:00 - 17:59',
                          iconAsset: 'assets/svg/ic_sun.svg',
                          iconColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        5,
                        _scheduleCard(
                          category: 'ORGANISASI',
                          tagBg: const Color(0xFFFFF7ED),
                          tagColor: const Color(0xFFD97706),
                          accentColor: const Color(0xFFD97706),
                          title: 'Rapat Finalisasi Rundown Dies Natalis',
                          startTime: '13:30',
                          endTime: '15:00',
                          location: 'Sekre BEM Gedung F',
                          startHour: 13,
                          startMinute: 30,
                          isConflict: true,
                          statusLabel: 'Bentrok jadwal',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sesi Malam
                      _reveal(
                        6,
                        _sessionHeader(
                          title: 'Sesi Malam',
                          timeRange: '18:00 - 23:59',
                          iconAsset: 'assets/svg/ic_moon.svg',
                          iconColor: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        7,
                        _scheduleCard(
                          category: 'BOOTCAMP',
                          tagBg: const Color(0xFFECFDF5),
                          tagColor: const Color(0xFF059669),
                          accentColor: const Color(0xFF059669),
                          title: 'Flutter & Mobile Development',
                          startTime: '19:30',
                          endTime: '21:00',
                          location: 'Online (Google Meet)',
                          startHour: 19,
                          startMinute: 30,
                          statusLabel: 'Nanti',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        8,
                        _scheduleCard(
                          category: 'BOOTCAMP',
                          tagBg: const Color(0xFFECFDF5),
                          tagColor: const Color(0xFF059669),
                          accentColor: const Color(0xFF059669),
                          title: 'Flutter & Mobile Development',
                          startTime: '22:00',
                          endTime: '23:00',
                          location: 'Online (Google Meet)',
                          startHour: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lapisan 2: SATU-SATUNYA Kalender.
                // Naik perlahan dari top 74 ke top 10 saat scroll, lalu berhenti nempel (pinned).
                Positioned(
                  top: _pinnedTop + translateY,
                  left: 20,
                  right: 20,
                  child: MiniCalendar(
                    initialMonth: _currentMonth,
                    selectedDate: _selectedDate,
                    expandProgressOverride: progress,
                    pinned: isPinned,
                    onMonthChanged: (m) => setState(() => _currentMonth = m),
                    onToggleRequested: _scrollToTop,
                    onDateSelected: _onDateSelected,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerUser() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Lingkaran Oat Milk
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: oatMilkPill,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEADBCE), width: 1),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svg/ic_user.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting & Info Kampus
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Halo, Doni!',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkEspresso,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Universitas Dian Nuswantor • Smstr 1',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: mutedTaupe,
                ),
              ),
            ],
          ),
        ),
        // Tombol Pengaturan
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFEADBCE), width: 1),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svg/ic_settings.svg',
            width: 19,
            height: 19,
            colorFilter: const ColorFilter.mode(mutedTaupe, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }

  /// 3. Section Session Header — Icon SVG + Judul + Garis Pembatas + Pill Jam di kanan
  Widget _sessionHeader({
    required String title,
    required String timeRange,
    required String iconAsset,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon lingkaran dengan warna lembut
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 8),

          // Judul Sesi (Sesi Pagi, Sesi Siang, Sesi Malam)
          Text(
            title,
            style: smBold.copyWith(
              color: darkEspresso,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),

          // Garis tipis divider pembatas horizontal
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEADBCE),
                    Color(0x30EADBCE),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pill badge jam di kanan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: oatMilkPill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCE), width: 0.8),
            ),
            child: Text(
              timeRange,
              style: xxxsSemiBold.copyWith(
                color: mutedTaupe,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Schedule Card — strip kiri rapi (ikut radius kartu),
  /// badge kategori di kiri atas, dan label status di kanan atas.
  Widget _scheduleCard({
    required String category,
    required Color tagBg,
    required Color tagColor,
    required Color accentColor,
    required String title,
    required String startTime,
    required String endTime,
    required String location,
    required int startHour,
    int startMinute = 0,
    bool isConflict = false,
    String? statusLabel,
  }) {
    final effectiveAccent = isConflict ? errorColor : accentColor;

    return BouncingTap(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openScheduleDetail(startHour, startMinute),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isConflict
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFEADBCE),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Strip aksen kiri. Ikut ter-clip oleh radius kartu karena
                  // `clipBehavior: Clip.antiAlias` pada Container luar.
                  Container(width: 5, color: effectiveAccent),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris atas: badge kategori + status di kanan
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _pill(
                                label: category,
                                bg: tagBg,
                                fg: tagColor,
                              ),
                              if (isConflict) ...[
                                const SizedBox(width: 6),
                                _pill(
                                  label: 'Bentrok',
                                  bg: const Color(0xFFFEE2E2),
                                  fg: errorColor,
                                  iconAsset: 'assets/svg/ic_triangle_alert.svg',
                                ),
                              ],
                              const Spacer(),
                              if (statusLabel != null)
                                Text(
                                  statusLabel,
                                  style:
                                      xxxsSemiBold.copyWith(color: mutedTaupe),
                                ),
                            ],
                          ),
                          const SizedBox(height: 9),

                          // Judul
                          Text(
                            title,
                            style: smBold.copyWith(
                              color: darkEspresso,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 7),

                          // Baris waktu
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svg/ic_clock.svg',
                                width: 13,
                                height: 13,
                                colorFilter: ColorFilter.mode(
                                  effectiveAccent,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$startTime - $endTime WIB',
                                style: xsSemiBold.copyWith(
                                  color: effectiveAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Baris lokasi
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svg/ic_location.svg',
                                width: 13,
                                height: 13,
                                colorFilter: const ColorFilter.mode(
                                  mutedTaupe,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: xsRegular.copyWith(color: mutedTaupe),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bungkus konten dengan animasi masuk bertingkat (staggered fade+slide).
  Widget _reveal(int index, Widget child) => StaggeredEntrance(
        delay: Duration(milliseconds: 40 * index),
        child: child,
      );

  /// Buka layar detail kalender & fokus ke jam jadwal yang diketuk.
  void _openScheduleDetail(int hour, int minute) {
    final date = _selectedDate ?? DateTime.now();
    Navigator.of(context).push(
      SharedAxisPageRoute(
        builder: (_) => CalendarDetailScreen(
          initialDate: date,
          focusHour: hour,
          focusMinute: minute,
        ),
      ),
    );
  }

  /// Badge kecil (kategori / bentrok) dengan opsi ikon SVG.
  Widget _pill({
    required String label,
    required Color bg,
    required Color fg,
    String? iconAsset,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(iconAsset == null ? 7 : 5, 3, 7, 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              width: 10,
              height: 10,
              colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: xxxsBold.copyWith(
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
