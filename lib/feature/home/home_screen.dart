import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/feature/calendar/calendar_detail_screen.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/shared_widget/live_highlight_card.dart';
import 'package:jadwalin/ui/shared_widget/mini_calendar.dart';

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

    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    if (offset < 8) {
      Navigator.of(context).push(
        MaterialPageRoute(
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

  /// Jadwal yang sedang berlangsung, atau yang berikutnya kalau tidak ada.
  _DummySchedule? get _highlightSchedule {
    final now = DateTime.now();
    final list = _todaySchedules;

    for (final s in list) {
      if (now.isAfter(s.start) && now.isBefore(s.end)) return s;
    }
    for (final s in list) {
      if (now.isBefore(s.start)) return s;
    }
    return list.isEmpty ? null : list.last;
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
                      if (_highlightSchedule != null) ...[
                        LiveHighlightCard(
                          title: _highlightSchedule!.title,
                          location: _highlightSchedule!.location,
                          start: _highlightSchedule!.start,
                          end: _highlightSchedule!.end,
                          category: _highlightSchedule!.category,
                          iconAsset: _highlightSchedule!.iconAsset,
                          accentColor: _highlightSchedule!.accentColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Sesi Pagi
                      _sessionHeader('🌅 Sesi Pagi (05:00 - 11:59)'),
                      const SizedBox(height: 10),
                      _scheduleCard(
                        category: 'KULIAH',
                        tagBg: const Color(0xFFEEF4FF),
                        tagColor: const Color(0xFF2563EB),
                        accentColor: const Color(0xFF2563EB),
                        title: 'Kalkulus & Aljabar Linear',
                        subtitle: '08:00 - 09:40 WIB • Gedung D (R. 302)',
                      ),
                      const SizedBox(height: 10),
                      _scheduleCard(
                        category: 'KULIAH',
                        tagBg: const Color(0xFFEEF4FF),
                        tagColor: const Color(0xFF2563EB),
                        accentColor: const Color(0xFF2563EB),
                        title: 'Algoritma & Pemrograman II',
                        subtitle: '10:00 - 11:40 WIB • Lab Komputer 4',
                      ),
                      const SizedBox(height: 24),

                      // Sesi Siang
                      _sessionHeader('☀️ Sesi Siang (12:00 - 17:59)'),
                      const SizedBox(height: 10),
                      _scheduleCard(
                        category: 'ORGANISASI',
                        tagBg: const Color(0xFFFFF7ED),
                        tagColor: const Color(0xFFD97706),
                        accentColor: const Color(0xFFD97706),
                        title: 'Rapat Finalisasi Rundown Dies Natalis',
                        subtitle: '13:30 - 15:00 WIB • Sekre BEM Gedung F',
                        isConflict: true,
                      ),
                      const SizedBox(height: 24),

                      // Sesi Malam
                      _sessionHeader('🌙 Sesi Malam (18:00 - 23:59)'),
                      const SizedBox(height: 10),
                      _scheduleCard(
                        category: 'BOOTCAMP',
                        tagBg: const Color(0xFFECFDF5),
                        tagColor: const Color(0xFF059669),
                        accentColor: const Color(0xFF059669),
                        title: 'Flutter & Mobile Development',
                        subtitle: '19:30 - 21:00 WIB • Online (Google Meet)',
                      ),
                      const SizedBox(height: 10),
                      _scheduleCard(
                        category: 'BOOTCAMP',
                        tagBg: const Color(0xFFECFDF5),
                        tagColor: const Color(0xFF059669),
                        accentColor: const Color(0xFF059669),
                        title: 'Flutter & Mobile Development',
                        subtitle: '22.00 - 23:00 WIB • Online (Google Meet)',
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

  /// 3. Section Session Header (Simple text, no visual noise)
  Widget _sessionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: darkEspresso,
        letterSpacing: -0.1,
      ),
    );
  }

  /// 5. Clean Minimalist Schedule Card
  Widget _scheduleCard({
    required String category,
    required Color tagBg,
    required Color tagColor,
    required Color accentColor,
    required String title,
    required String subtitle,
    bool isConflict = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConflict ? const Color(0xFFFCA5A5) : const Color(0xFFEADBCE),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left vertical accent indicator bar
            Container(
              width: 4.5,
              color: isConflict ? errorColor : accentColor,
            ),

            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: tagColor,
                            ),
                          ),
                        ),
                        if (isConflict) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Bentrok',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: errorColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: darkEspresso,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Subtitle (Time & Location)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: mutedTaupe,
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
}
