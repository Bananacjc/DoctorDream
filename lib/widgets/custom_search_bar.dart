import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';

class CustomSearchBar extends StatefulWidget {
  final Size? size;
  final Function(String) onSearch;

  const CustomSearchBar({super.key, this.size, required this.onSearch});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    final Size size = widget.size ?? Size(256, 40);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: SearchBar(
        constraints: BoxConstraints(
          minHeight: size.height,
          minWidth: size.width * 0.6,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(ColorConstant.inverseSurface),
        trailing: [
          Icon(
            Icons.search_rounded,
            color: ColorConstant.onInverseSurface,
            size: 24,
          ),
        ],
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.robotoFlex(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: ColorConstant.onInverseSurface,
          ),
        ),
        hintText: "Search your memories...",
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.robotoFlex(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: ColorConstant.onInverseSurface.withAlpha(90),
          ),
        ),
        onChanged: (value) {
          widget.onSearch(value);
        },
      ),
    );
  }
}
