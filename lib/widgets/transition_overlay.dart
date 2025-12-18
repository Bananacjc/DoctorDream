import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constant.dart';

class TransitionOverlay extends StatefulWidget {
  final Widget nextScreen;
  final String message;
  final IconData icon;
  final bool waitForLoad; // New param

  const TransitionOverlay({
    super.key,
    required this.nextScreen,
    required this.message,
    required this.icon,
    this.waitForLoad = false, // Default false
  });

  @override
  State<TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Increased from 1500 to 3000
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _startTransition();
  }

  void _startTransition() async {
    // Start animation
    await _controller.forward();
    
    // Minimum wait time for the message to be read
    await Future.delayed(const Duration(milliseconds: 1000));

    if (widget.waitForLoad) {
      // If we need to wait for data (like HotlineScreen), 
      // we can add a small extra buffer or just proceed since HotlineScreen handles its own loading state.
      // However, to truly "wait until ready", we would need to preload data which is complex.
      // For now, let's give it a bit more time to feel "prepared".
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.surfaceContainerLowest,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ColorConstant.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 64,
                      color: ColorConstant.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    color: ColorConstant.secondary,
                    strokeWidth: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

