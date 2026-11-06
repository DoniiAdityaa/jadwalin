// import 'dart:math' as math;
// import 'package:flutter/material.dart';

// class GradientCircularProgressIndicator extends StatefulWidget {
//   final double size;
//   final double strokeWidth;
//   final Color? color;
//   final int durationMs;

//   const GradientCircularProgressIndicator({
//     super.key,
//     this.size = 40,
//     this.strokeWidth = 5,
//     this.color,
//     this.durationMs = 1000,
//   });

//   @override
//   State<GradientCircularProgressIndicator> createState() =>
//       _GradientCircularProgressIndicatorState();
// }

// class _GradientCircularProgressIndicatorState
//     extends State<GradientCircularProgressIndicator>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: widget.durationMs),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final color = widget.color ?? Theme.of(context).colorScheme.primary;

//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (_, _) {
//         return Transform.rotate(
//           angle: _controller.value * 2 * math.pi,
//           child: CustomPaint(
//             size: Size.square(widget.size),
//             painter: _GradientArcPainter(
//               color: color,
//               strokeWidth: widget.strokeWidth,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _GradientArcPainter extends CustomPainter {
//   final Color color;
//   final double strokeWidth;

//   const _GradientArcPainter({required this.color, required this.strokeWidth});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final radius = (size.width - strokeWidth) / 2;

//     final rect = Rect.fromCircle(
//       center: Offset(size.width / 2, size.height / 2),
//       radius: radius,
//     );

//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round
//       ..isAntiAlias = true;

//     paint.shader = SweepGradient(
//       startAngle: 0,
//       endAngle: 2 * math.pi,
//       transform: const GradientRotation(-math.pi / 2),
//       colors: [
//         color.withValues(alpha: 0), // Tosca transparan (bukan hitam!)
//         color.withValues(alpha: 0.15),
//         color.withValues(alpha: 0.35),
//         color.withValues(alpha: 0.65),
//         color.withValues(alpha: 0.9),
//         color,
//       ],
//       stops: const [0.00, 0.55, 0.72, 0.84, 0.93, 1.00],
//     ).createShader(rect);

//     canvas.drawArc(
//       rect,
//       -math.pi / 2,
//       math.pi * 1.7, // ±306°
//       false,
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _GradientArcPainter oldDelegate) {
//     return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
//   }
// }
