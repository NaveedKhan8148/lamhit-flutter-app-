import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'Home Section Screens/FeaturedImagesScreen.dart';
import 'Profile Section Screens/ProfileScreen.dart';
import 'Upload Section Screens/ImageUploadScreen.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  int _currentIndex = 0;

  final List _screens = [
    FeaturedImagesScreen(),
    ImageUploadScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ── iPad / large screen detection ─────────────────────────
    // On iPad, MediaQuery.size.shortestSide is > 600.
    // We use this to adjust padding and tab sizing so the Upload
    // button (and all tabs) are always visible and tappable.
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // Horizontal padding: give tablets more breathing room
    final double hPadding = isTablet ? 40 : 15;

    // Vertical padding: add bottom safe area so nothing hides
    // behind the iPad home indicator
    final double vPadding = isTablet ? 12 : 5;

    // Tab icon/text size scaling for tablet
    final double iconSize = isTablet ? 28 : 24;
    final double gap = isTablet ? 8 : 2;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        // SafeArea ensures the bar is never hidden behind the
        // iPad home bar or notch areas
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: hPadding,
              vertical: vPadding,
            ),
            child: GNav(
              haptic: false,
              gap: gap,
              color: Colors.black,
              backgroundColor: Colors.white,
              activeColor: Colors.black,
              tabBackgroundColor: Colors.black12,
              iconSize: iconSize,
              // Ensure each tab has enough width on all screen sizes
              tabMargin: EdgeInsets.symmetric(
                horizontal: isTablet ? 8 : 4,
                vertical: 4,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 14 : 10,
              ),
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              tabs: const [
                GButton(icon: Icons.home, text: "Home"),
                GButton(icon: Icons.upload, text: "Upload"),
                GButton(icon: Icons.person, text: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}