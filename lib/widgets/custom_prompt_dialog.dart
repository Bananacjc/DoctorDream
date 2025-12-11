import 'package:doctor_dream/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';

class CustomPromptDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String description;
  final bool isClosable;
  final List<CustomTextButton> actions;

  const CustomPromptDialog({
    super.key,
    required this.title,
    this.icon,
    required this.description,
    this.isClosable = false,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: ColorConstant.inverseSurface,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: icon != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      color: ColorConstant.onInverseSurface,
                                      size: 26,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.robotoFlex(
                                          color: ColorConstant.onInverseSurface,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  title,
                                  style: GoogleFonts.robotoFlex(
                                    color: ColorConstant.onInverseSurface,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        isClosable
                            ? IconButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: ColorConstant.onInverseSurface,
                                  size: 20,
                                ),
                              )
                            : Container(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      description,
                      style: GoogleFonts.robotoFlex(
                        color: ColorConstant.onInverseSurface.withAlpha(230),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 21),
                    // Actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(actions.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: actions[index],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
