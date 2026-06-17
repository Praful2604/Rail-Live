import 'package:flutter/material.dart';
import 'package:rail_live/screens/auth_screen.dart';
import 'package:rail_live/screens/onboarding_screens/screen3.dart';

class Screen2 extends StatelessWidget {
  const Screen2({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        // ── 4-stop gradient background ──────────────────────────────
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
              // ── Top bar ─────────────────────────────────────────
              _TopBar(
                onSkip: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                  );
                },
              ),

              const SizedBox(height: 12),

              // ── Chat mockup card ─────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _ChatMockupCard(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Live badge ───────────────────────────────────────
              const _LiveBadge(),

              const SizedBox(height: 10),

              // ── Text block ───────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Travel Together,\nStay Connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.22,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Join live train chats, share updates &\nconnect with fellow passengers on your route.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xB3FFFFFF), // white 70%
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Page dots ────────────────────────────────────────
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: false),
                  _Dot(active: true),
                  _Dot(active: false),
                  _Dot(active: false),
                ],
              ),

              const SizedBox(height: 20),

              // ── Next button ──────────────────────────────────────
              _NextButton(onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen3()),
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

// ── Live Badge ────────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF48BB78),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Live Chat Active',
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

// ── Chat Mockup Card ──────────────────────────────────────────────────────────

class _ChatMockupCard extends StatelessWidget {
  const _ChatMockupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E4FF), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1F5C).withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Chat header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3FAA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.train_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '12951 Mumbai Rajdhani Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFF48BB78), size: 7),
                          SizedBox(width: 4),
                          Text(
                            '234 Travelers Online',
                            style: TextStyle(color: Color(0xFFB3C8FF), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: Color(0xFFB3C8FF), size: 20),
              ],
            ),
          ),

          // ── Messages ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: const [
                _ChatBubble(avatar: '👨', name: 'Ravi', message: 'Platform changed to 4 🚉', time: '09:20 AM', isMe: false),
                SizedBox(height: 10),
                _ChatBubble(avatar: '👩', name: 'Meera', message: 'Train departed from Surat. On time now ✅', time: '09:21 AM', isMe: false),
                SizedBox(height: 10),
                _ChatBubble(avatar: '🧑', name: 'Arjun (You)', message: 'Thanks for the update!', time: '09:22 AM', isMe: true),
                SizedBox(height: 10),
                _ChatBubble(avatar: '👦', name: 'Karan', message: 'Food available in B2 coach 🍱', time: '09:23 AM', isMe: false),
              ],
            ),
          ),

          // ── Input bar ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD6E4FF), width: 1),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Type a message...',
                    style: TextStyle(color: Color(0xFFB0BCD4), fontSize: 12.5),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A3FAA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String avatar;
  final String name;
  final String message;
  final String time;
  final bool isMe;

  const _ChatBubble({
    required this.avatar,
    required this.name,
    required this.message,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFEEF4FF),
            child: Text(avatar, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8A9BB5)),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF1A3FAA) : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 14),
                  ),
                  border: isMe ? null : Border.all(color: const Color(0xFFD6E4FF), width: 0.5),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isMe ? Colors.white : const Color(0xFF1A2B5E),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(time, style: const TextStyle(fontSize: 9.5, color: Color(0xFFB0BCD4))),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 7),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFEEF4FF),
            child: Text(avatar, style: const TextStyle(fontSize: 12)),
          ),
        ],
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
                child: const Icon(Icons.train_rounded, color: Colors.white, size: 22),
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
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    'Smart Railway Companion',
                    style: TextStyle(fontSize: 10.5, color: Color(0x99FFFFFF)),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xCCFFFFFF)),
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
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A3FAA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A3FAA)),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 19, color: Color(0xFF1A3FAA)),
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