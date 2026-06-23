import 'package:flutter/material.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/app_constant.dart';

class StatusSummaryCard extends StatelessWidget {
  final TrainDetailProvider provider;
  const StatusSummaryCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RailLiveColors.primary2, RailLiveColors.primary3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.primary2.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT DELAY',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      provider.liveIsOnTime
                          ? 'On Time'
                          : '$provider.liveCurrentDelayText min',
                      style: TextStyle(
                          color: provider.liveIsOnTime
                              ? RailLiveColors.liveGreen
                              : RailLiveColors.accent2,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.liveIsOnTime
                                ? Icons.check_circle_outline
                                : Icons.access_time,
                            color: provider.liveIsOnTime
                                ? RailLiveColors.liveGreen
                                : RailLiveColors.accent2,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            provider.liveIsOnTime ? 'ON TIME' : 'DELAYED',
                            style: TextStyle(
                                color: provider.liveIsOnTime
                                    ? RailLiveColors.liveGreen
                                    : RailLiveColors.accent2,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('NEXT STATION',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: Text(
                      provider.liveNextStationName,
                      style: const TextStyle(
                          color: RailLiveColors.surface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        const Text('ETA',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(
                          provider.liveEtaForNext,
                          style: const TextStyle(
                              color: RailLiveColors.surface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Start',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '$provider.livePassedCount / ${provider.liveStations.length} stations',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
              const Text('End',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.liveStations.isEmpty
                  ? 0
                  : provider.livePassedCount / provider.liveStations.length,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  
}
