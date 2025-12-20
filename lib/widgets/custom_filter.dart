import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';

class CustomFilter<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> filterOptions;
  final Function(T) onFilterSelected;
  final Widget? icon;

  const CustomFilter({
    super.key,
    required this.filterOptions,
    required this.onFilterSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorConstant.inverseSurface,
      borderRadius: BorderRadius.circular(50),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: ColorConstant.onInverseSurface,
            displayColor: ColorConstant.onInverseSurface,
          ),
          popupMenuTheme: PopupMenuThemeData(
            textStyle: GoogleFonts.robotoFlex(),
            color: ColorConstant.inverseSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: ColorConstant.onInverseSurface),
            ),
          ),
        ),
        child: PopupMenuButton<T>(
          offset: const Offset(0, 45),
          elevation: 6,
          icon:
              icon ??
              Icon(
                Icons.tune_rounded,
                color: ColorConstant.onInverseSurface,
                size: 24,
              ),
          onSelected: (T value) {
            onFilterSelected(value);
          },
          itemBuilder: (BuildContext context) => filterOptions,
        ),
      ),
    );
  }
}
