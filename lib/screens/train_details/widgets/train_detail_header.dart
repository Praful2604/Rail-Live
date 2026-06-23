import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/screens/train_chat_screen.dart';

class TrainDetailHeader extends StatelessWidget {
  final String trainNumber;
  final String trainName;
  final VoidCallback onBack;

  const TrainDetailHeader({
    super.key,
    required this.trainNumber,
    required this.trainName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RailLiveColors.primary2, RailLiveColors.primary3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$trainNumber · $trainName',
                      style: const TextStyle(
                        color: RailLiveColors.surface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: RailLiveColors.liveGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE · Auto-refresh every 60s',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.wechat_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainChatScreen(
                        trainNumber: trainNumber,
                        trainName: trainName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
