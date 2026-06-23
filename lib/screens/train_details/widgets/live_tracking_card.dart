import 'package:flutter/material.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/app_constant.dart';

class LiveTrackingCard extends StatelessWidget {
  final TrainDetailProvider provider;
  final Animation<double> pulseAnimation;
  const LiveTrackingCard({super.key, required this.provider, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final body = provider.liveStatus?['body'] as Map<String, dynamic>?;
    if (body == null) return const SizedBox();

    final currentCode = provider.liveCurrentStation;
    final message = provider.liveTrainStatusMessage;
    final timeAvail = provider.liveTimeOfAvailability;
    final terminated = provider.liveTerminated;

    Map<String, dynamic>? currentStn;
    for (final s in provider.liveStations) {
      final m = s as Map<String, dynamic>;
      if (m['stationCode']?.toString() == currentCode) {
        currentStn = m;
        break;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1a237e).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: terminated
                              ? RailLiveColors.warning
                              : RailLiveColors.liveGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        terminated ? 'TERMINATED' : 'LIVE TRACKING',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (timeAvail.isNotEmpty)
                  Text(
                    'Updated $timeAvail',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: pulseAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    child: const Icon(Icons.train,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRAIN IS CURRENTLY AT / NEAR',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStn != null
                            ? (currentStn['stationName']?.toString() ??
                            currentCode)
                            : (currentCode.isNotEmpty
                            ? currentCode
                            : 'Fetching…'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (currentCode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _livePill(currentCode,
                                color:
                                Colors.white.withValues(alpha: 0.2)),
                            if (currentStn?['distance'] != null) ...[
                              const SizedBox(width: 6),
                              _livePill(
                                  '${currentStn!['distance']} km from origin',
                                  color: Colors.white
                                      .withValues(alpha: 0.2)),
                            ],
                          ],
                        ),
                      ],
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _trackingStat(
                  icon: Icons.check_circle_outline,
                  label: 'Passed',
                  value: '$provider.livePassedCount',
                  color: RailLiveColors.liveGreen,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.schedule,
                  label: 'Delay',
                  value: provider.liveIsOnTime
                      ? 'On Time'
                      : '$provider.liveCurrentDelayText min',
                  color: provider.liveIsOnTime
                      ? RailLiveColors.liveGreen
                      : RailLiveColors.warning,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.arrow_forward,
                  label: 'Next',
                  value: provider.liveNextStationName,
                  color: Colors.white,
                  maxLines: 1,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: provider.liveEtaForNext,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePill(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _trackingStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int maxLines = 1,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _trackingStatDivider() {
    return Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.15));
  }

  // ══════════════════════════════════════════════════════════════════
  //  
}
