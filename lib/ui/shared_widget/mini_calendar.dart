import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jadwalin/ui/color.dart';
import 'package:jadwalin/ui/typography.dart';

/// Data agenda dummy per tanggal.
class CalendarEventDummy {
  CalendarEventDummy._();

  static const Set<int> eventDayNumbers = {
    1, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 18, 19, 21, 22, 25, 26, 27, 28,
  };

  static Set<int> eventDatesForMonth(int year, int month) {
    return eventDayNumbers;
  }
}

/// Kontrol eksternal untuk memaksa [MiniCalendar] collapse / expand.
class MiniCalendarController extends ChangeNotifier {
  bool _requestedCollapsed = false;

  /// True kalau parent (misal HomeScreen) minta kalender jadi 1 baris.
  bool get requestedCollapsed => _requestedCollapsed;

  void requestCollapse() {
    if (_requestedCollapsed) return;
    _requestedCollapsed = true;
    notifyListeners();
  }

  void requestExpand() {
    if (!_requestedCollapsed) return;
    _requestedCollapsed = false;
    notifyListeners();
  }
}

/// Kalender Custom dengan animasi Collapse/Expand yang mengikuti jari baris per baris.
///
/// - Geser ke atas: baris 5, 4, 3, dst ketutup bertahap sampai sisa 1 baris
/// - Baris yang tersisa adalah baris tempat tanggal aktif berada
/// - Mode 1 baris: bisa scroll horizontal untuk melihat hari sebelumnya/sesudahnya
class MiniCalendar extends StatefulWidget {
  const MiniCalendar({
    super.key,
    this.initialMonth,
    this.selectedDate,
    this.eventDates,
    this.onDateSelected,
    this.onMonthChanged,
    this.today,
    this.controller,
    this.onExpandToggled,
    this.pinned = false,
    this.onToggleRequested,
    this.borderless = false,
    this.expandProgressOverride,
  });

  final DateTime? initialMonth;
  final DateTime? selectedDate;
  final Set<int>? eventDates;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<DateTime>? onMonthChanged;
  final DateTime? today;
  final MiniCalendarController? controller;

  /// Callback saat user menekan tombol toggle panah atas/bawah.
  /// Parameter [isExpanded] adalah status BARU setelah ditekan.
  final ValueChanged<bool>? onExpandToggled;

  /// Mode sticky: kalender dipaksa 1 baris dan tampil sebagai kartu compact.
  final bool pinned;

  /// Dipanggil saat user menekan tombol panah di mode [pinned].
  /// Parent yang mengurus scroll ke atas + unlock mode sticky.
  final VoidCallback? onToggleRequested;

  /// Sudut & border kartu disembunyikan (sudah dibungkus oleh parent).
  final bool borderless;

  /// Nilai 0..1 dari parent untuk mengontrol tinggi secara langsung
  /// (dipakai saat kalender di dalam SliverPersistentHeader).
  /// Null = widget mengurus animasinya sendiri.
  final double? expandProgressOverride;

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar>
    with SingleTickerProviderStateMixin {
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _weekdayLabels = [
    'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab',
  ];

  static const double _rowHeight = 44.0;
  static const double _rowSpacing = 4.0;
  static const double _effectiveRowHeight = _rowHeight + _rowSpacing;

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  /// Progress expand/collapse: 1.0 = full month, 0.0 = 1 row (week)
  double _expandProgress = 1.0;
  bool _isExpanded = true;

  late final AnimationController _animController;
  Animation<double>? _anim;

  /// PageController untuk horizontal swipe saat mode 1 baris
  late PageController _weekPageController;
  final int _weekPageIndex = 1000; // Baseline tengah untuk infinite scroll
  DateTime get _today {
    final now = widget.today ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Set<int> get _eventDates =>
      widget.eventDates ??
      CalendarEventDummy.eventDatesForMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? _today;
    _visibleMonth = DateTime(initial.year, initial.month);
    _selectedDate = widget.selectedDate ?? _today;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() {
          _expandProgress = _anim?.value ?? _expandProgress;
        });
      });

    _weekPageController = PageController(initialPage: _weekPageIndex);
    widget.controller?.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final requested = widget.controller?.requestedCollapsed ?? false;
    if (requested && _isExpanded) {
      _animateToProgress(0.0);
    } else if (!requested && !_isExpanded) {
      _animateToProgress(1.0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _animController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MiniCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialMonth != null &&
        oldWidget.initialMonth != widget.initialMonth) {
      final m = widget.initialMonth!;
      if (m.year != _visibleMonth.year || m.month != _visibleMonth.month) {
        setState(() {
          _visibleMonth = DateTime(m.year, m.month);
        });
      }
    }

    if (widget.selectedDate != null &&
        !_isSameDay(widget.selectedDate!, _selectedDate)) {
      setState(() {
        _selectedDate = widget.selectedDate!;
        if (_selectedDate.year != _visibleMonth.year ||
            _selectedDate.month != _visibleMonth.month) {
          _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
        }
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Matrix hari dalam 1 bulan, per minggu (tiap minggu 7 hari)
  List<List<DateTime>> _getMonthMatrix(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingOffset = firstDay.weekday % 7; // Min = 0 ... Sab = 6

    final List<List<DateTime>> weeks = [];
    List<DateTime> currentWeek = [];

    // Hari dari bulan sebelumnya
    final prevMonthEnd = DateTime(month.year, month.month, 0);
    for (int i = leadingOffset - 1; i >= 0; i--) {
      currentWeek.add(
        DateTime(prevMonthEnd.year, prevMonthEnd.month, prevMonthEnd.day - i),
      );
    }

    // Hari bulan ini
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(DateTime(month.year, month.month, day));
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Sisa hari untuk bulan depan
    if (currentWeek.isNotEmpty) {
      int nextMonthDay = 1;
      while (currentWeek.length < 7) {
        currentWeek.add(
          DateTime(month.year, month.month + 1, nextMonthDay++),
        );
      }
      weeks.add(currentWeek);
    }

    return weeks;
  }

  /// Mengetahui baris ke berapa yang memuat tanggal terpilih
  int _getSelectedRowIndex(List<List<DateTime>> matrix) {
    for (int r = 0; r < matrix.length; r++) {
      for (final date in matrix[r]) {
        if (_isSameDay(date, _selectedDate)) return r;
      }
    }
    return 0;
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.year != _visibleMonth.year || date.month != _visibleMonth.month) {
        _visibleMonth = DateTime(date.year, date.month);
      }
    });
    widget.onDateSelected?.call(date);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    widget.onMonthChanged?.call(_visibleMonth);
  }

  void _toggleFormat() {
    if (widget.pinned) {
      widget.onToggleRequested?.call();
      return;
    }
    final nextExpanded = !_isExpanded;
    widget.onExpandToggled?.call(nextExpanded);
    _animateToProgress(nextExpanded ? 1.0 : 0.0);
  }

  Future<void> _animateToProgress(double target) {
    _anim = Tween<double>(
      begin: _expandProgress,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    return _animController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _isExpanded = target == 1.0;
        _expandProgress = target;
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GESTURE DRAG TRACKING (BERTURUT-TURUT MENUTUP BARIS)
  // ─────────────────────────────────────────────────────────────────────────

  void _onVerticalDragUpdate(
    DragUpdateDetails details,
    double totalCollapseDistance,
  ) {
    if (totalCollapseDistance <= 0) return;
    setState(() {
      // Drag ke atas (delta minus) -> kurangi progress
      _expandProgress += details.primaryDelta! / totalCollapseDistance;
      _expandProgress = _expandProgress.clamp(0.0, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _animateToProgress(0.0); // Fling ke atas -> langsung collapse
    } else if (velocity > 300) {
      _animateToProgress(1.0); // Fling ke bawah -> langsung expand
    } else {
      // Snap ke posisi terdekat
      _animateToProgress(_expandProgress > 0.5 ? 1.0 : 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matrix = _getMonthMatrix(_visibleMonth);
    final rowCount = matrix.length; // biasanya 5 atau 6 baris
    final selectedRowIndex = _getSelectedRowIndex(matrix);

    // Tinggi mode full month dan mode 1 baris (week)
    // Grid: tiap baris punya Padding(bottom: _rowSpacing), termasuk baris terakhir
    final double fullMonthHeight =
        rowCount * _effectiveRowHeight;
    final double singleRowHeight = _effectiveRowHeight;
    final double totalCollapseDistance = fullMonthHeight - singleRowHeight;

    // Progress aktual: dari parent kalau di-override, kalau tidak pakai state lokal.
    final double progress =
        (widget.expandProgressOverride ?? _expandProgress).clamp(0.0, 1.0);

    // Tinggi saat ini yang sedang mengikuti jari / animasi
    final double currentHeight =
        singleRowHeight + (progress * totalCollapseDistance);

    // Offset vertical agar baris yang memuat tanggal aktif tetap terlihat saat collapse
    final double targetOffset = selectedRowIndex * _effectiveRowHeight;
    final double currentVerticalOffset = targetOffset * (1.0 - progress);

    final bool isFullyCollapsed = widget.pinned || progress <= 0.001;

    final bool pinnedMode = widget.pinned;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.borderless ? BorderRadius.zero : BorderRadius.circular(20),
        border: widget.borderless
            ? null
            : Border.all(color: const Color(0xFFEADBCE), width: 1),
        boxShadow: [
          if (!pinnedMode)
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header (Bulan + Chevron Navigasi + Toggle Icon)
          Padding(
            padding: pinnedMode
                ? const EdgeInsets.fromLTRB(14, 10, 10, 2)
                : const EdgeInsets.fromLTRB(18, 16, 14, 8),
            child: Row(
              children: [
                Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: (pinnedMode ? smBold : mdBold).copyWith(
                    color: darkEspresso,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                _navButton(
                  icon: 'assets/svg/ic_chevron_left.svg',
                  onTap: () {
                    if (isFullyCollapsed) {
                      _weekPageController.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _shiftMonth(-1);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _navButton(
                  icon: 'assets/svg/ic_chevron_right.svg',
                  onTap: () {
                    if (isFullyCollapsed) {
                      _weekPageController.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _shiftMonth(1);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _expandToggleButton(),
              ],
            ),
          ),

          // 2. Weekday Header Labels (Min, Sen, Sel, ...)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pinnedMode ? 10 : 14),
            child: Row(
              children: List.generate(_weekdayLabels.length, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabels[i],
                      style: xxsSemiBold.copyWith(color: mutedTaupe),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Area Grid Kalender (Bisa di-drag vertikal baris demi baris)
          GestureDetector(
            onVerticalDragUpdate: pinnedMode
                ? null
                : (d) => _onVerticalDragUpdate(d, totalCollapseDistance),
            onVerticalDragEnd: pinnedMode ? null : _onVerticalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pinnedMode ? 10 : 14),
              child: SizedBox(
                height: pinnedMode ? singleRowHeight : currentHeight,
                child: ClipRect(
                  child: (pinnedMode || isFullyCollapsed)
                      ? _buildHorizontalWeekPager()
                      : _buildSlidingMonthGrid(
                          matrix: matrix,
                          offsetY: currentVerticalOffset,
                        ),
                ),
              ),
            ),
          ),

          SizedBox(height: pinnedMode ? 6 : 8),
        ],
      ),
    );
  }

  /// Grid bulan yang bergeser ke atas saat drag (baris bawah ketutup duluan)
  Widget _buildSlidingMonthGrid({
    required List<List<DateTime>> matrix,
    required double offsetY,
  }) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -offsetY,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(matrix.length, (rIndex) {
              final week = matrix[rIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: _rowSpacing),
                child: SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: List.generate(week.length, (cIndex) {
                      final day = week[cIndex];
                      final isOutsideMonth = day.month != _visibleMonth.month;
                      return Expanded(
                        child: _buildDayCell(
                          day: day,
                          isSelected: _isSameDay(day, _selectedDate),
                          isToday: _isSameDay(day, _today),
                          isOutsideMonth: isOutsideMonth,
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Saat sudah 1 baris (collapsed penuh), user bisa geser horizontal bebas
  Widget _buildHorizontalWeekPager() {
    return PageView.builder(
      controller: _weekPageController,
      onPageChanged: (page) {
        final diff = page - _weekPageIndex;
        final newFocused = _selectedDate.add(Duration(days: 7 * diff));
        setState(() {
          _visibleMonth = DateTime(newFocused.year, newFocused.month);
        });
      },
      itemBuilder: (context, index) {
        final weekDiff = index - _weekPageIndex;
        // Hitung hari Minggu (awal minggu) dari selectedDate
        final sundayOfSelected = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday % 7),
        );
        final weekStart = sundayOfSelected.add(Duration(days: 7 * weekDiff));

        return SizedBox(
          height: _rowHeight,
          child: Row(
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isOutsideMonth = day.month != _visibleMonth.month;
              return Expanded(
                child: _buildDayCell(
                  day: day,
                  isSelected: _isSameDay(day, _selectedDate),
                  isToday: _isSameDay(day, _today),
                  isOutsideMonth: isOutsideMonth,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required bool isOutsideMonth,
  }) {
    final hasEvent = _eventDates.contains(day.day) && !isOutsideMonth;

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (isOutsideMonth) {
      textColor = const Color(0xFFD4D4D8);
    } else {
      textColor = darkEspresso;
    }

    final dotColor = isSelected ? oatMilkPill : secondaryColor;

    return Center(
      child: GestureDetector(
        onTap: () => _onDateTapped(day),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [primaryColor, Color(0xFF8B6B4D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
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
                  '${day.day}',
                  style: (isSelected ? xsBold : xsMedium).copyWith(
                    color: textColor,
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
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.5),
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
      ),
    );
  }

  Widget _navButton({required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: oatMilkPill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(mutedTaupe, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _expandToggleButton() {
    final effectiveProgress =
        widget.expandProgressOverride ?? (_isExpanded ? 1.0 : 0.0);
    final showUpArrow = widget.pinned || effectiveProgress < 0.5;
    return GestureDetector(
      onTap: _toggleFormat,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: showUpArrow ? 'Tampilkan bulan' : 'Tampilkan minggu',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 28,
          decoration: BoxDecoration(
            color: showUpArrow ? primaryColor : oatMilkPill,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: SvgPicture.asset(
                showUpArrow
                    ? 'assets/svg/ic_chevron_up.svg'
                    : 'assets/svg/ic_chevron_down.svg',
                key: ValueKey<bool>(showUpArrow),
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  showUpArrow ? Colors.white : mutedTaupe,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
