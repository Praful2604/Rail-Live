import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/screens/auth_screen.dart';
import 'package:rail_live/screens/onboarding_screens/screen1.dart';
import 'Providers/clock_provider.dart';
import 'Providers/live_status_provider.dart';
import 'Providers/pnr_provider.dart';
import 'Providers/train_provider.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Screen1());
        //home: AuthScreen());
  }
}
