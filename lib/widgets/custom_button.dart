import '../constants/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ButtonType {
  cancel(
    backgroundColor: ColorConstant.secondaryContainer,
    textColor: ColorConstant.onSecondaryContainer,
  ),
  confirm(
    backgroundColor: ColorConstant.primary,
    textColor: ColorConstant.onPrimary,
  ),
  warning(
    backgroundColor: ColorConstant.errorContainer,
    textColor: ColorConstant.onErrorContainer,
  );

  final Color backgroundColor;
  final Color textColor;

  const ButtonType({required this.backgroundColor, required this.textColor});
}

class CustomTextButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final ButtonType type;

  const CustomTextButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: type.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        buttonText,
        style: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: type.textColor,
        ),
      ),
    );
  }
}

class CustomPillButton extends StatelessWidget {
  final String labelText;
  final VoidCallback? onPressed;
  final IconData? icon;

  const CustomPillButton({
    super.key,
    required this.labelText,
    this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      label: Text(
        labelText,
        style: GoogleFonts.robotoFlex(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ColorConstant.onPrimaryContainer,
        ),
      ),
      icon: Icon(icon, size: 24, color: ColorConstant.onPrimaryContainer),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstant.primaryContainer,
        foregroundColor: ColorConstant.onPrimaryContainer,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
    );
  }
}

class CustomIconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomIconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? ColorConstant.primaryContainer,
          foregroundColor: foregroundColor ?? ColorConstant.onPrimaryContainer,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
