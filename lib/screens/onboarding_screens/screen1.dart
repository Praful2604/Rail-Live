import 'package:flutter/material.dart';
import 'package:rail_live/screens/auth_screen.dart';
import 'package:rail_live/screens/onboarding_screens/screen2.dart';

class Screen1 extends StatelessWidget {
  const Screen1({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Deep gradient background (top) ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Container(
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
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
              child: CustomPaint(painter: _TrackLinesPainter()),
            ),
          ),

          // ── Gradient fade: deep blue → light bg ──────────────────────
          Positioned(
            top: size.height * 0.38,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFFEEF4FF)],
                ),
              ),
            ),
          ),

          // ── White bottom area ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.44,
            child: const ColoredBox(color: Color(0xFFEEF4FF)),
          ),

          // ── Full content ──────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _TopBar(onSkip: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                  );
                }),

                const Spacer(),

                // ── Glassmorphic status card ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _LiveStatusCard(),
                ),

                const SizedBox(height: 24),

                // ── Headline ──────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Text(
                        'Real-Time Railways\nat Your Fingertips.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A2B5E),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Track live train locations, monitor delays,\n'
                            'check arrivals & stay updated\nthroughout your journey.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A6A8A),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Page dots ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dot(active: true),
                    _Dot(active: false),
                    _Dot(active: false),
                    _Dot(active: false),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Next button ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3FAA), Color(0xFF2557D6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A3FAA).withOpacity(0.40),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => Screen2()),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Track Lines Painter ───────────────────────────────────────────────────────

class _TrackLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final railPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Two rails converging toward top (perspective)
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.3, size.height * 0.2);
    final path2 = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.2);
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Sleepers (cross ties)
    for (int i = 0; i < 6; i++) {
      final t = i / 5;
      final y = size.height * (0.2 + t * 0.8);
      final x1 = lerpDouble(size.width * 0.3, 0, t)!;
      final x2 = lerpDouble(size.width * 0.38, size.width * 0.18, t)!;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), railPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onSkip;
  const _TopBar({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Glassmorphic logo box
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.train_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'RailLive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Smart Railway Companion',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Skip pill
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Status Card ──────────────────────────────────────────────────────────

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3FAA).withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF1A3FAA).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '12951  ·  Mumbai Rajdhani Express',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A9BB5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mumbai → New Delhi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B5E),
                      ),
                    ),
                  ],
                ),
              ),
              const _LiveBadge(),
            ],
          ),

          const SizedBox(height: 12),

          // Route bar
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFF1A3FAA)),
              const SizedBox(width: 6),
              const Text(
                'MMCT',
                style: TextStyle(fontSize: 11, color: Color(0xFF5A6A8A)),
              ),
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3FAA), Color(0xFFE53E3E)],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const Text(
                'NDLS',
                style: TextStyle(fontSize: 11, color: Color(0xFF5A6A8A)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.location_on, size: 8, color: Color(0xFFE53E3E)),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDF0F7), height: 1),
          const SizedBox(height: 12),

          // Current location
          Row(
            children: const [
              Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF1A3FAA)),
              SizedBox(width: 6),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A9BB5),
                ),
              ),
              Spacer(),
              Text(
                'Updated 2 min ago',
                style: TextStyle(fontSize: 10, color: Color(0xFFB0BCD4)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Near Vadodara Jn.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B5E),
            ),
          ),

          const SizedBox(height: 14),

          // Stats
          Row(
            children: const [
              _StatItem(label: 'Speed', value: '110 km/h'),
              _VertDivider(),
              _StatItem(label: 'Next Stop', value: 'Vadodara Jn.'),
              _VertDivider(),
              _StatItem(label: 'ETA NDLS', value: '12:15 PM'),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row: delay + platform
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7D7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Color(0xFFE53E3E)),
                    SizedBox(width: 5),
                    Text(
                      'Running 10 min late',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.train_outlined, size: 12, color: Color(0xFF1A3FAA)),
                    SizedBox(width: 4),
                    Text(
                      'Platform TBD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3FAA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Live Badge with Pulse Animation ──────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Opacity(
              opacity: _anim.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFB0BCD4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B5E),
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFEDF0F7),
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A3FAA) : const Color(0xFFCDD5E8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}