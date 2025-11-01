import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomFilter extends StatefulWidget {
  const CustomFilter({super.key});

  @override
  State<CustomFilter> createState() => _CustomFilterState();
}

class _CustomFilterState extends State<CustomFilter> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Ink(
          height: 40,
          decoration: ShapeDecoration(shape: CircleBorder()),
          child: IconButton(
            icon: SvgPicture.asset(
              "assets/icons/filter_light.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSecondary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: (){
              debugPrint("Filter pressed");
            },
          ),
        ),
      ),
    );
  }
}
