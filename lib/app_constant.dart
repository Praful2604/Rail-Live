import 'package:flutter/material.dart';


class RailLiveColors {
  RailLiveColors._();

  // ── Primary (Navy → Sky Blue) ──────────────
  static const Color primary2        = Color(0xFF0A2463); // --p2
  static const Color primary       = Color(0xFF1565C0); // --p
  static const Color primary3       = Color(0xFF1E88E5); // --p3
  static const Color primary4       = Color(0xFFE3F2FD); // --p4  (light tint)

  // ── Accent (Amber / Orange) ────────────────
  static const Color accent         = Color(0xFFFF8C00); // --acc
  static const Color accent2        = Color(0xFFFFB300); // --acc2
  static const Color accent3        = Color(0xFFFFF3E0); // --acc3 (light tint)

  // ── Semantic / Status ──────────────────────
  static const Color success        = Color(0xFF00897B); // --ok   (teal green)
  static const Color warning        = Color(0xFFE65100); // --warn (deep orange)
  static const Color error          = Color(0xFFC62828); // --err  (crimson)
  static const Color liveGreen      = Color(0xFF69F0AE); // live-pill / online badge

  // ── Backgrounds & Surfaces ─────────────────
  static const Color background     = Color(0xFFF0F4FF); // --bg   (page bg)
  static const Color surface        = Color(0xFFFFFFFF); // --surf (card bg)
  static const Color surface2       = Color(0xFFF7F9FF); // --surf2 (secondary surface)
  static const Color mapBackground  = Color(0xFFE8EFF8); // map placeholder bg

  // ── Text ───────────────────────────────────
  static const Color textPrimary    = Color(0xFF0A1628); // --tx
  static const Color textSecondary  = Color(0xFF4A5568); // --tx2
  static const Color textHint       = Color(0xFF8896A8); // --tx3

  // ── Border ────────────────────────────────
  static const Color border         = Color(0xFFE2E8F5); // --bdr

  // ── Misc / One-offs ────────────────────────
  static const Color phoneFrame     = Color(0xFF1A2F5A); // device bezel
  static const Color languageIcon   = Color(0xFF6A1B9A); // purple (language row)
  static const Color notifIcon      = Color(0xFFF57F17); // notification bell icon
  static const Color emergencyArrow = Color(0xFFEF9A9A); // emergency chevron

  // ── Quick-action card icon backgrounds ─────
  static const Color qaBlue         = Color(0xFFE3F2FD); // Live Status
  static const Color qaGreen        = Color(0xFFE8F5E9); // Schedule
  static const Color qaAmber        = Color(0xFFFFF8E1); // Seat Avail
  static const Color qaPink         = Color(0xFFFCE4EC); // Alerts
  static const Color qaPurple       = Color(0xFFEDE7F6); // Coach Position
  static const Color qaCyan         = Color(0xFFE0F7FA); // Platform Info

  // ── Alert accent borders ───────────────────
  static const Color alertErrorBg   = Color(0xFFFFEBEE);
  static const Color alertWarnBg    = Color(0xFFFFF8E1);
  static const Color alertSuccessBg = Color(0xFFE8F5E9);

  // ── Coach heatmap bars ─────────────────────
  static const Color heatLow        = Color(0xFFA5D6A7); // light green
  static const Color heatMid        = Color(0xFFFFD54F); // yellow
  static const Color heatHigh       = Color(0xFFFF8C00); // accent orange
  static const Color heatRed        = Color(0xFFEF9A9A); // light red

  // ── Insight band ──────────────────────────
  static const Color insightBg      = Color(0xFFE3F2FD); // primary4 alias
  static const Color insightBorder  = Color(0xFFBBDEFB);
  static const Color insightHead    = Color(0xFF0C447C);

// ── Timeline nodes ────────────────────────
// done  → success  (#00897B)
// now   → primary  (#0A2463)
// next  → surface2 (#F7F9FF) + border
}

// ─────────────────────────────────────────────
//  RailLive ThemeData
// ─────────────────────────────────────────────

class RailLiveTheme {
  RailLiveTheme._();

  static ThemeData get light {
    const primarySwatch = MaterialColor(
      0xFF0A2463,
      <int, Color>{
        50:  Color(0xFFE3F2FD),
        100: Color(0xFFBBDEFB),
        200: Color(0xFF90CAF9),
        300: Color(0xFF64B5F6),
        400: Color(0xFF1E88E5),
        500: Color(0xFF1565C0),
        600: Color(0xFF1565C0),
        700: Color(0xFF0A2463),
        800: Color(0xFF0A2463),
        900: Color(0xFF0A1628),
      },
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PlusJakartaSans', // add to pubspec.yaml
      colorScheme: const ColorScheme.light(
        primary:          RailLiveColors.primary,
        onPrimary:        Colors.white,
        primaryContainer: RailLiveColors.primary4,
        onPrimaryContainer: RailLiveColors.primary2,
        secondary:        RailLiveColors.accent,
        onSecondary:      Colors.white,
        secondaryContainer: RailLiveColors.accent3,
        onSecondaryContainer: RailLiveColors.warning,
        error:            RailLiveColors.error,
        onError:          Colors.white,
        errorContainer:   Color(0xFFFFEBEE),
        onErrorContainer: RailLiveColors.error,
        background:       RailLiveColors.background,
        onBackground:     RailLiveColors.textPrimary,
        surface:          RailLiveColors.surface,
        onSurface:        RailLiveColors.textPrimary,
        surfaceVariant:   RailLiveColors.surface2,
        onSurfaceVariant: RailLiveColors.textSecondary,
        outline:          RailLiveColors.border,
        outlineVariant:   RailLiveColors.primary4,
      ),
      scaffoldBackgroundColor: RailLiveColors.background,
      cardColor: RailLiveColors.surface,
      dividerColor: RailLiveColors.border,
      primarySwatch: primarySwatch,

      // ── AppBar ──


      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RailLiveColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'PlusJakartaSans',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RailLiveColors.primary,
          side: const BorderSide(color: RailLiveColors.primary2, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'PlusJakartaSans',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),

      // ── Input / Search Field ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RailLiveColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RailLiveColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RailLiveColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RailLiveColors.primary2, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: RailLiveColors.textHint,
          fontSize: 14,
        ),
      ),



      // ── BottomNavigationBar ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RailLiveColors.surface,
        selectedItemColor: RailLiveColors.primary,
        unselectedItemColor: RailLiveColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'PlusJakartaSans',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'PlusJakartaSans',
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: RailLiveColors.surface,
        side: const BorderSide(color: RailLiveColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: RailLiveColors.textPrimary,
          fontFamily: 'PlusJakartaSans',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Text ──
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: RailLiveColors.textPrimary),
        titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: RailLiveColors.textPrimary),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RailLiveColors.textPrimary),
        titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RailLiveColors.textPrimary),
        bodyLarge:      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: RailLiveColors.textPrimary),
        bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: RailLiveColors.textPrimary),
        bodySmall:      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: RailLiveColors.textSecondary),
        labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RailLiveColors.textPrimary),
        labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RailLiveColors.textHint, letterSpacing: 0.7),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: RailLiveColors.accent,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
    );
  }
}