import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';

class FeedbackPopup extends StatefulWidget {
  final String title;
  final Function(int rating, String? comment) onSubmit;

  const FeedbackPopup({
    super.key,
    required this.title,
    required this.onSubmit,
  });

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent, // Handled by Material container
      child: Material(
        color: ColorConstant.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Container(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstant.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rate_review_rounded,
                    size: 40,
                    color: ColorConstant.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Feedback',
                style: GoogleFonts.robotoFlex(
                  color: ColorConstant.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'How was "${widget.title}"?',
                style: GoogleFonts.robotoFlex(
                  color: ColorConstant.onSurfaceVariant,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          key: ValueKey<bool>(index < _rating),
                          color: index < _rating ? Colors.amber : ColorConstant.outline,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              // Comment Input
              TextField(
                autofocus: false,
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts (optional)...',
                  hintStyle: TextStyle(color: ColorConstant.onSurfaceVariant.withOpacity(0.5)),
                  filled: true,
                  fillColor: ColorConstant.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: ColorConstant.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(color: ColorConstant.onSurface),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Skip', 
                        style: GoogleFonts.robotoFlex(
                          color: ColorConstant.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rating > 0
                          ? () {
                              widget.onSubmit(_rating, _commentController.text);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.primary,
                        foregroundColor: ColorConstant.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: ColorConstant.onSurface.withOpacity(0.12),
                        disabledForegroundColor: ColorConstant.onSurface.withOpacity(0.38),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}