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
        backgroundColor: WidgetStatePropertyAll(ColorConstant.secondary),
        trailing: [
          SvgPicture.asset(
            "assets/icons/search_light.svg",
            colorFilter: ColorFilter.mode(
              ColorConstant.onSecondary,
              BlendMode.srcIn,
            ),
          ),
        ],
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: ColorConstant.onSecondary,
          ),
        ),
        hintText: "Find your previous dream...",
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onSecondary.withAlpha(90),
          ),
        ),
        onChanged: (value) {
          widget.onSearch(value);
        },
      ),
    );
  }
}
