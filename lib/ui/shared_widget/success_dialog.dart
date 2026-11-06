// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:app_berita/ui/color.dart';
// import 'package:app_berita/ui/typography.dart';
// import 'package:app_berita/ui/shared_widget/loading_indicator.dart';

// class SuccessDialog extends StatelessWidget {
//   final String title;
//   final String subtitle;

//   const SuccessDialog({super.key, required this.title, required this.subtitle});

//   /// Helper static method untuk mempermudah pemanggilan dialog dari screen mana saja
//   static Future<void> show(
//     BuildContext context, {
//     String title = 'Sign in Successful!',
//     String subtitle = 'Please wait...\nYou will be directed to the homepage.',
//   }) {
//     return showDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withValues(
//         alpha: 0.3,
//       ), // Background gelap transparan tipis sebelum diblur
//       builder: (context) => SuccessDialog(title: title, subtitle: subtitle),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BackdropFilter(
//       filter: ImageFilter.blur(
//         sigmaX: 5.0,
//         sigmaY: 5.0,
//       ), // Efek blur di latar belakang
//       child: Dialog(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset("assets/images/icon_user.png", width: 220),
//               // 2. Judul Sukses
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontFamily: 'poppins',
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                   color: primaryColor,
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // 3. Subtitle / Deskripsi
//               Text(
//                 subtitle,
//                 textAlign: TextAlign.center,
//                 style: smRegular.copyWith(
//                   color: textNeutralSecondary,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 32),

//               // 4. Loading Indicator memutar
//               const GradientCircularProgressIndicator(
//                 size: 40,
//                 strokeWidth: 4.5,
//                 color: primaryColor,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
