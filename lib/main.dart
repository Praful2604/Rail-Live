import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/Providers/station_search_provider.dart';
import 'package:rail_live/screens/onboarding_screens/splash_screen.dart';
import 'package:rail_live/services/notification_service.dart';
import 'Providers/clock_provider.dart';
import 'Providers/live_status_provider.dart';
import 'Providers/pnr_provider.dart';
import 'Providers/restaurant_provider.dart';
import 'Providers/train_provider.dart';
import 'bottom_navigation_bar.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Init notification service
  NotificationService.navigatorKey = navigatorKey;
  await NotificationService.instance.init();
  await NotificationService.instance.subscribeToGeneralAlerts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrainProvider()..loadTrains()),
        ChangeNotifierProvider(create: (_) => PnrProvider()),
        ChangeNotifierProvider(create: (_) => LiveStatusProvider()),
        ChangeNotifierProvider(create: (_) => ClockProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => StationSearchProvider()),
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
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase still initializing
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Already logged in → go to home
          if (snapshot.hasData && snapshot.data != null) {
            return BottomNavigationBarPage();
          }

          // Not logged in → show splash
          return const SplashScreen();
        },
      ),
    );
  }
}