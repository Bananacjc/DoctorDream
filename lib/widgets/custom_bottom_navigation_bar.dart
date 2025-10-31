import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/review_screen.dart';
import '../screens/diagnosis_screen.dart';
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
    ReviewScreen(),
    DiagnosisScreen(),
    RecommendScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        color: Theme.of(context).colorScheme.primary,
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          selectedItemColor: Theme.of(context).colorScheme.onPrimary,
          unselectedItemColor: Theme.of(context).colorScheme.onPrimary,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: SvgPicture.asset(
                  "assets/icons/home_light.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                selected: _currentIndex == 0,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: SvgPicture.asset(
                  "assets/icons/stethoscope_light.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                selected: _currentIndex == 1,
              ),
              label: 'Diagnosis',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: SvgPicture.asset(
                  "assets/icons/compass_light.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                selected: _currentIndex == 2,
              ),
              label: 'Recommend',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: SvgPicture.asset(
                  "assets/icons/chat_light.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                selected: _currentIndex == 3,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: SvgPicture.asset(
                  "assets/icons/user_light.svg",
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                selected: _currentIndex == 4,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomBarIcon extends StatelessWidget {
  final Widget icon;
  final bool selected;

  const _CustomBottomBarIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (selected) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
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
            // Inner circle
            // Container(
            //   width: 40,
            //   height: 40,
            //   decoration: BoxDecoration(
            //     color: Colors.transparent,
            //     border: Border.all(color: Colors.white, width: 1.5),
            //     shape: BoxShape.circle,
            //   ),
            // ),
            // Icon
            SizedBox(width: 36, height: 36, child: icon),
          ],
        ),
      );
    } else {
      return SizedBox(width: 36, height: 36, child: icon);
    }
  }
}
