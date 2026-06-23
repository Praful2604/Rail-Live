import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';

class TrainDetailLoadingCard extends StatelessWidget {
  const TrainDetailLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            'Fetching live train status…',
            style: TextStyle(color: RailLiveColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class TrainDetailErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TrainDetailErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.alertErrorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RailLiveColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: RailLiveColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: RailLiveColors.error, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class TrainDetailNoDataCard extends StatelessWidget {
  const TrainDetailNoDataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.alertWarnBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RailLiveColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: RailLiveColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live schedule data is not available for this train right now.',
              style: TextStyle(color: RailLiveColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
