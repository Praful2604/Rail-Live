import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/nearby_restaurant_screen.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/pnr_screen.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/chat_screens.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/home_screen.dart';

import 'package:rail_live/screens/Bottom_NavigationBar_screens/station_search_screen.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/tracking_screen.dart';
import 'package:rail_live/screens/Profiles_pages/profile_screen.dart';

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({Key? key}) : super(key: key);

  @override
  State<BottomNavigationBarPage> createState() => _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
     HomeScreen(),
    StationSearchScreen(),
    PnrScreen(),
    NearbyRestaurantsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: RailLiveColors.primary,
        color: Colors.transparent, // Fixed color selection
        buttonBackgroundColor:RailLiveColors.primary,
        height: 60,
        index: _selectedIndex,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white,),
          Icon(Icons.train, size: 30, color: Colors.white),
          Icon(Icons.confirmation_num_outlined, size: 30, color: Colors.white),
          Icon(Icons.fastfood_rounded, size: 30, color: Colors.white),

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