import 'package:doctor_dream/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomPromptDialog extends StatelessWidget {
  final String title;
  final String description;
  final bool isClosable;
  final List<CustomTextButton> actions;

  const CustomPromptDialog({
    super.key,
    required this.title,
    required this.description,
    this.isClosable = false,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Theme.of(context).colorScheme.secondaryContainer,
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
              Text(
                title,
                style: GoogleFonts.robotoFlex(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              isClosable
                  ? IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
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
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 20,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [...actions.map((e) => Expanded(child: e))],
          ),
        ],
      ),
    );
  }
}
