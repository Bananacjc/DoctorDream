import '../constants/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ButtonType {
  cancel(
    backgroundColor: ColorConstant.secondaryContainer,
    textColor: ColorConstant.onSecondaryContainer,
  ),
  navigate(backgroundColor: ColorConstant.success, textColor: ColorConstant.onSuccess);

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        )
      ),
      child: Text(
        buttonText,
        style: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: type.textColor,
        ),
      ),
    );
  }
}
