import 'package:flutter/material.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/app_constant.dart';

class TrainInfoCard extends StatelessWidget {
  final TrainDetailProvider provider;

  const TrainInfoCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RailLiveColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.trainName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: RailLiveColors.textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: RailLiveColors.surface2,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: RailLiveColors.border),
                ),
                child: Text(
                  provider.trainNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RailLiveColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _StationDot(filled: true),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              RailLiveColors.border,
                              RailLiveColors.border.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const _StationDot(filled: false),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.origin,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: RailLiveColors.textPrimary,
                            ),
                          ),
                          Text(
                            'DEP · ${provider.departureTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RailLiveColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.destination,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: RailLiveColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ARR · ${provider.arrivalTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RailLiveColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: provider.liveIsOnTime
                            ? RailLiveColors.success
                            : RailLiveColors.warning,
                      ),
                    ),
                    Text(
                      provider.duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RailLiveColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (provider.trainType.isNotEmpty ||
              provider.runningDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: RailLiveColors.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (provider.trainType.isNotEmpty)
                  _InfoBadge(Icons.train_outlined, provider.trainType),
                if (provider.runningDays.isNotEmpty)
                  _InfoBadge(
                    Icons.calendar_today_outlined,
                    provider.runningDays,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StationDot extends StatelessWidget {
  final bool filled;

  const _StationDot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? RailLiveColors.primary2 : Colors.transparent,
        border: Border.all(color: RailLiveColors.primary2, width: 2),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RailLiveColors.primary4,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: RailLiveColors.primary2),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: RailLiveColors.primary2,
            ),
          ),
        ],
      ),
    );
  }
}
