import 'package:flutter/material.dart';
import 'package:rail_live/screens/auth_screen.dart';
import 'package:rail_live/screens/onboarding_screens/screen4.dart';

class Screen3 extends StatelessWidget {
  const Screen3({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1F5C),
              Color(0xFF1A3FAA),
              Color(0xFF2557D6),
              Color(0xFF3B73F5),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────
              _TopBar(onSkip: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                );
              }),

              const SizedBox(height: 10),

              // ── AI Chat Card ─────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: const _AiChatMockup(),
                ),
              ),

              const SizedBox(height: 16),

              // ── AI badge ─────────────────────────────────────────
              const _AiBadge(),

              const SizedBox(height: 10),

              // ── Text block ───────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Meet Your\nAI Travel Assistant.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.22,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Instant answers on trains, routes, delays,\nplatforms and your full journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xADFFFFFF),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Page dots ────────────────────────────────────────
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: false),
                  _Dot(active: false),
                  _Dot(active: true),
                  _Dot(active: false),
                ],
              ),

              const SizedBox(height: 18),

              // ── Next button ──────────────────────────────────────
              _NextButton(onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen4()),
                      (route) => false,
                );
              }),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Badge ──────────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 13),
          SizedBox(width: 5),
          Text(
            'Powered by AI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Chat Mockup ────────────────────────────────────────────────────────────

class _AiChatMockup extends StatelessWidget {
  const _AiChatMockup();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── Main card ────────────────────────────────────────────
        Positioned(
          top: 46,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1F5C).withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 36),

                // ── Card header ──────────────────────────────────
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFEEF4FF), width: 1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'RailLive AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2B5E),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text('✨', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.circle, color: Color(0xFF48BB78), size: 7),
                          SizedBox(width: 5),
                          Text(
                            'Always online · Instant answers',
                            style: TextStyle(
                                fontSize: 10.5, color: Color(0xFF8A9BB5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Chat messages ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // User message
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 9),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A3FAA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'When will Train 12951 arrive at NDLS?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // AI answer card
                        _AiAnswerCard(),
                      ],
                    ),
                  ),
                ),

                // ── Quick chips ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['PNR Status', 'Coach position', 'Seat availability']
                          .map((t) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFC7D8FF),
                              width: 0.5),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3FAA),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Input bar ────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(28),
                    border:
                    Border.all(color: const Color(0xFFD6E4FF), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ask anything about your journey...',
                          style: TextStyle(
                              color: Color(0xFFB0BCD4), fontSize: 11.5),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A3FAA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Floating robot avatar ────────────────────────────────
        Positioned(
          top: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1F5C).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child:Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3FAA).withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A3FAA), Color(0xFF3B73F5)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(

                    backgroundImage: const AssetImage('assets/onboarding/robot.png'),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── "AI Powered" badge ───────────────────────────────────
        Positioned(
          top: 4,
          right: 10,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, color: Color(0xFFFFD700), size: 5),
                SizedBox(width: 4),
                Text(
                  'AI Powered',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── AI Answer Card ────────────────────────────────────────────────────────────

class _AiAnswerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFD6E4FF), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF4FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                    bottom: BorderSide(color: Color(0xFFD6E4FF), width: 0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: Color(0xFF1A3FAA)),
                  SizedBox(width: 6),
                  Text(
                    'Live Train Status',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3FAA),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expected at New Delhi (NDLS) — 18:42 PM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B5E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFFCDD0), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            size: 11, color: Color(0xFFE53E3E)),
                        SizedBox(width: 4),
                        Text(
                          'Running 12 min late',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      color: const Color(0xFF1A3FAA),
                      text: 'Near Vadodara Jn.',
                      icon: Icons.location_on_rounded),
                  const SizedBox(height: 5),
                  _InfoRow(
                      color: const Color(0xFF1A3FAA),
                      text: 'Next stop: Ratlam Junction',
                      icon: Icons.train_rounded),
                  const SizedBox(height: 5),
                  _InfoRow(
                      color: const Color(0xFFF6AD55),
                      text: 'Platform: Will be updated soon',
                      icon: Icons.info_outline_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color color;
  final String text;
  final IconData icon;

  const _InfoRow({
    required this.color,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onSkip;
  const _TopBar({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(Icons.train_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RailLive',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Smart Railway Companion',
                    style: TextStyle(
                        fontSize: 10.5, color: Color(0x99FFFFFF)),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A3FAA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3FAA),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Color(0xFF1A3FAA)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      width: active ? 20 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}