import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rail_live/screens/auth_screen.dart';

class Screen4 extends StatelessWidget {
  const Screen4({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
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
              // ── Top bar ────────────────────────────────────────────

              // ── Phone mockup ───────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _PhoneMockup(screenHeight: size.height),
                ),
              ),

              const SizedBox(height: 18),

              // ── Headline ───────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Everything Railways.\nOne App.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Live tracking, PNR status, train schedules,\nstation information, traveler chat, and\nAI assistance—all in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xCCFFFFFF),
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Page dots ──────────────────────────────────────────
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: false),
                  _Dot(active: false),
                  _Dot(active: false),
                  _Dot(active: true),
                ],
              ),

              const SizedBox(height: 20),

              // ── Get Started button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A3FAA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      shadowColor: Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 25, color: Color(0xFF1A3FAA)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Sign In link ───────────────────────────────────────

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone Mockup ──────────────────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  final double screenHeight;
  const _PhoneMockup({required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
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
        border: Border.all(color: const Color(0xFF0A1540), width: 5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1F5C).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          children: [
            // ── Status bar ─────────────────────────────────────
            _StatusBar(),
            // ── Inner content ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Column(
                  children: [
                    // Greeting row
                    _GreetingRow(),
                    const SizedBox(height: 8),
                    // Train card
                    _TrainCard(),
                    const SizedBox(height: 8),
                    // Feature grid
                    Expanded(child: _FeatureGrid()),
                    const SizedBox(height: 6),
                    // Bottom nav
                    _BottomNav(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt,
                  color: Colors.white, size: 13),
              const SizedBox(width: 3),
              const Icon(Icons.wifi, color: Colors.white, size: 13),
              const SizedBox(width: 3),
              Container(
                width: 20,
                height: 11,
                decoration: BoxDecoration(
                  border:
                  Border.all(color: Colors.white, width: 1.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Greeting Row ──────────────────────────────────────────────────────────────

class _GreetingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Arjun 👋',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Where to next?',
              style: TextStyle(
                fontSize: 10,
                color: Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 16),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF1A3FAA), width: 1.2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Train Card ────────────────────────────────────────────────────────────────

class _TrainCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '12951 Mumbai Rajdhani Express',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2B5E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF48BB78), width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF48BB78),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F855A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BCT → NDLS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B5E),
                    ),
                  ),
                  Text(
                    'Near Vadodara Jn.',
                    style: TextStyle(
                        fontSize: 9, color: Color(0xFF8A9BB5)),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ETA',
                    style: TextStyle(
                        fontSize: 9, color: Color(0xFF8A9BB5)),
                  ),
                  Text(
                    '12:15 PM',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B5E),
                    ),
                  ),
                  Text(
                    'Running 10 min late',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feature Grid ──────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(
        icon: Icons.train_rounded,
        label: 'Live Train\nStatus',
        iconBg: const Color(0xFFEEF4FF),
        iconColor: const Color(0xFF1A3FAA),
      ),
      _GridItem(
        icon: Icons.confirmation_number_outlined,
        label: 'PNR\nStatus',
        iconBg: const Color(0xFFFFF0F6),
        iconColor: const Color(0xFFD4537E),
      ),
      _GridItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Train\nChat',
        iconBg: const Color(0xFFF0FFF4),
        iconColor: const Color(0xFF2F855A),
      ),
      _GridItem(
        icon: Icons.smart_toy_rounded,
        label: 'AI\nAssistant',
        iconBg: const Color(0xFFEEF4FF),
        iconColor: const Color(0xFF1A3FAA),
      ),
      _GridItem(
        icon: Icons.calendar_month_rounded,
        label: 'Train\nSchedule',
        iconBg: const Color(0xFFFFFBF0),
        iconColor: const Color(0xFFB7791F),
      ),
      _GridItem(
        icon: Icons.location_on_rounded,
        label: 'Station\nInfo',
        iconBg: const Color(0xFFFFF5F5),
        iconColor: const Color(0xFFE53E3E),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon,
                    size: 18, color: item.iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2B5E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _GridItem(
      {required this.icon,
        required this.label,
        required this.iconBg,
        required this.iconColor});
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Color(0x26FFFFFF), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
          _NavItem(icon: Icons.search_rounded, label: 'Search'),
          _NavItem(icon: Icons.group_outlined, label: 'Trips'),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: active
              ? Colors.white
              : Colors.white.withOpacity(0.45),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight:
            active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? Colors.white
                : Colors.white.withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
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
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
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
                        fontSize: 10.5,
                        color: Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ],
          ),
        ],
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
        color: active
            ? Colors.white
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}