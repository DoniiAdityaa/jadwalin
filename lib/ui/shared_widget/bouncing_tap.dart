import 'package:flutter/material.dart';

/// Wrapper yang memberi efek scale-down pegas saat ditekan, TANPA
/// merebut tap dari child.
///
/// Memakai [Listener] (pointer events) alih-alih [GestureDetector] agar
/// tidak bentrok gesture arena dengan [InkWell] di dalamnya, sehingga
/// splash Material tetap berfungsi.
class BouncingTap extends StatefulWidget {
  const BouncingTap({
    super.key,
    required this.child,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 110),
    this.enabled = true,
  });

  final Widget child;
  final double scaleDown;
  final Duration duration;
  final bool enabled;

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 170),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _release() {
    if (!widget.enabled) return;
    if (_controller.isAnimating || _controller.value > 0) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
