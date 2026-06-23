import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/Providers/station_search_provider.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/home_screen.dart';
import 'package:rail_live/screens/auth_screen.dart';
import 'package:rail_live/screens/onboarding_screens/screen1.dart';
import 'Providers/clock_provider.dart';
import 'Providers/live_status_provider.dart';
import 'Providers/pnr_provider.dart';
import 'Providers/restaurant_provider.dart';
import 'Providers/train_provider.dart';
import 'bottom_navigation_bar.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrainProvider()..loadTrains()),
        ChangeNotifierProvider(create: (_) => PnrProvider()),
        ChangeNotifierProvider(create: (_) => LiveStatusProvider()),
        ChangeNotifierProvider(create: (_) => ClockProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) =>StationSearchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase still initializing
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ✅ Already logged in → skip onboarding, go to home
          if (snapshot.hasData && snapshot.data != null) {
            return BottomNavigationBarPage(); // 🔁 Replace with your HomeScreen
          }

          // 🔐 Not logged in → show auth
          return const Screen1();
        },
      ),
    );
  }
}