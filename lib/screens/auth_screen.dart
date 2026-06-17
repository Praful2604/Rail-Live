import 'package:firebase_auth_kit/firebase_auth_kit.dart';
import 'package:flutter/material.dart';

import '../bottom_navigation_bar.dart';
import 'Bottom_NavigationBar_screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          //   • Any widget      → e.g. a video player, animated canvas, etc.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          AuthLoginScreen(
            config: AuthUIConfig(
              enableOtp: true,
              enableEmailPassword: true,
              backgroundColor: Colors.transparent
            ),
            onSuccess: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BottomNavigationBarPage()),
            ),
            onSignupTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => Scaffold(
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Signup background (required inside Stack) ──
                      // Use the same background as the login screen, or
                      // swap it for a different one.
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // ── Signup screen (required) ───────────────────
                      AuthSignupScreen(
                        config: const AuthUIConfig(
                          enableEmailPassword: true,
                          enableOtp: true,
                          enableGoogle: true,


                          backgroundColor: Colors.transparent,
                          headerBackground:
                          BoxDecoration(color: Colors.transparent),


                        ),

                      
                        onSuccess: () => Navigator.pushAndRemoveUntil(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => BottomNavigationBarPage()),
                              (_) => false,
                        ),

                        // ── Called when "Already have an account?" is tapped
                        // (optional) — remove to hide the footer link.
                        onLoginTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
