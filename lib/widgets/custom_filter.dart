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
      color: ColorConstant.secondary,
      borderRadius: BorderRadius.circular(16),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: ColorConstant.onSecondary,
            displayColor: ColorConstant.onSecondary,
          ),
          popupMenuTheme: PopupMenuThemeData(
            textStyle: GoogleFonts.robotoFlex(),
            color: ColorConstant.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ColorConstant.onSecondary)
            ), ),
        ),
        child: PopupMenuButton<T>(
          offset: const Offset(0, 45),
          elevation: 4,
          icon:
              icon ??
              SvgPicture.asset(
                "assets/icons/filter_light.svg",
                colorFilter: ColorFilter.mode(
                  ColorConstant.onSecondary,
                  BlendMode.srcIn,
                ),
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
