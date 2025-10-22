import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/recommend_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0; // Default to home screen

  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    RecommendScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 82, 
        color: const Color(0xFF081944), // Dark navy background
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF081944),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: Icons.home_outlined,
                selected: _currentIndex == 0,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: Icons.spa_outlined,
                selected: _currentIndex == 1,
              ),
              label: 'Recommend',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: Icons.chat_bubble_outline,
                selected: _currentIndex == 2,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: _CustomBottomBarIcon(
                icon: Icons.person_outline,
                selected: _currentIndex == 3,
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
  final IconData icon;
  final bool selected;
  
  const _CustomBottomBarIcon({
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF8E8CF2), // Light purple background
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
                color: const Color(0xFF8E8CF2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Inner circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 1.5),
                shape: BoxShape.circle,
              ),
            ),
            // Icon
            Icon(
              icon,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      );
    } else {
      return Icon(
        icon,
        color: Colors.white,
      );
    }
  }
}
