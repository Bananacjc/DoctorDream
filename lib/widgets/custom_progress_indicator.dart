import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';

class CustomProgressIndicator extends StatelessWidget {
  final Color? backgroundColor;
  final Color? progressIndicatorColor;
  final Icon? icon;
  final Text? indicatorText;

  const CustomProgressIndicator({
    super.key,
    this.backgroundColor,
    this.progressIndicatorColor,
    this.icon,
    this.indicatorText,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = this.backgroundColor ?? ColorConstant.surface;
    final Color progressIndicatorColor =
        this.progressIndicatorColor ?? ColorConstant.primary;
    final Icon icon =
        this.icon ??
        Icon(
          Icons.hourglass_empty_rounded,
          color: ColorConstant.onSurface,
          size: 18,
        );
    final Text indicatorText =
        this.indicatorText ??
        Text(
          "Loading...",
          style: GoogleFonts.robotoFlex(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorConstant.onSurface,
          ),
        );

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: progressIndicatorColor),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon, SizedBox(width: 8), indicatorText],
            ),
          ],
        ),
      ),
    );
  }
}
