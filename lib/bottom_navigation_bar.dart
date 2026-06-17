import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/pnr_screen.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/chat_screens.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/home_screen.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/tracking_screen.dart';
import 'package:rail_live/screens/Profiles_pages/profile_screen.dart';
import '';


class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({Key? key}) : super(key: key);

  @override
  State<BottomNavigationBarPage> createState() => _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const TrackingScreen(),
    const ChatScreens(),
   PnrScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      extendBody: true, // To show nav bar above transparent backgrounds
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: RailLiveColors.primary2,
        color: Colors.transparent, // Fixed color selection
        buttonBackgroundColor:RailLiveColors.primary,
        height: 60,
        index: _selectedIndex,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.track_changes, size: 30, color: Colors.white),
          Icon(Icons.wechat_sharp, size: 30, color: Colors.white),
          Icon(Icons.confirmation_num_outlined, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}