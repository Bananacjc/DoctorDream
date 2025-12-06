import 'package:doctor_dream/constants/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/dream_diagnosis_screen.dart';
import '../screens/dream_review_screen.dart';
import '../screens/recommend_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0; // Default to home screen

  final List<Widget> _pages = const <Widget>[
    DreamReviewScreen(),
    DreamDiagnosisScreen(),
    RecommendScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final Color activeColor = ColorConstant.primaryContainer;
    final Color inactiveColor = ColorConstant.secondaryContainer;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        color: ColorConstant.primary,
        child: SafeArea(
          child: BottomNavigationBar(
            backgroundColor: ColorConstant.primary,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            iconSize: 24,
            items: [
              BottomNavigationBarItem(
                icon: _CustomBottomBarIcon(
                  icon: Icon(Icons.book_rounded),
                  selected: _currentIndex == 0,
                  defaultIconColor: inactiveColor,
                  selectedIconColor: ColorConstant.primary,
                ),
                label: "Journal",
              ),
              BottomNavigationBarItem(
                icon: _CustomBottomBarIcon(
                  icon: Icon(Icons.monitor_heart_rounded),
                  selected: _currentIndex == 1,
                  defaultIconColor: inactiveColor,
                  selectedIconColor: ColorConstant.primary,
                ),
                label: 'Diagnosis',
              ),
              BottomNavigationBarItem(
                icon: _CustomBottomBarIcon(
                  icon: Icon(Icons.lightbulb_rounded),
                  selected: _currentIndex == 2,
                  defaultIconColor: inactiveColor,
                  selectedIconColor: ColorConstant.primary,
                ),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: _CustomBottomBarIcon(
                  icon: Icon(Icons.forum_rounded),
                  selected: _currentIndex == 3,
                  defaultIconColor: inactiveColor,
                  selectedIconColor: ColorConstant.primary,
                ),
                label: 'Talk',
              ),
              BottomNavigationBarItem(
                icon: _CustomBottomBarIcon(
                  icon: Icon(Icons.person_rounded),
                  selected: _currentIndex == 4,
                  defaultIconColor: inactiveColor,
                  selectedIconColor: ColorConstant.primary,
                ),
                label: 'Me',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomBottomBarIcon extends StatelessWidget {
  final Widget icon;
  final bool selected;
  final Color defaultIconColor;
  final Color selectedIconColor;

  const _CustomBottomBarIcon({
    required this.icon,
    required this.selected,
    required this.defaultIconColor,
    required this.selectedIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color finalIconColor = selected
        ? selectedIconColor
        : defaultIconColor;

    Widget coloredIcon = SizedBox(
      width: 36,
      height: 36,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(finalIconColor, BlendMode.srcIn),
        child: icon,
      ),
    );

    if (selected) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ColorConstant.primaryContainer,
          // background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer rounded square
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            coloredIcon,
          ],
        ),
      );
    } else {
      return coloredIcon;
    }
  }
}
