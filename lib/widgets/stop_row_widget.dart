import 'package:flutter/material.dart';

import '../app_constant.dart';

class StopRowWidget extends StatelessWidget {
  final String stationName;
  final int stopNumber;
  final bool isSource;
  final bool isDest;
  final bool isHighlighted;
  final bool isWithinJourney;
  final bool isLast;

  const StopRowWidget({
    super.key,
    required this.stationName,
    required this.stopNumber,
    required this.isSource,
    required this.isDest,
    required this.isHighlighted,
    required this.isWithinJourney,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isHighlighted
        ? RailLiveColors.primary
        : (isWithinJourney ? RailLiveColors.primary : Colors.grey.shade400);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ──────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: isHighlighted ? 14 : 10,
                  height: isHighlighted ? 14 : 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHighlighted ? dotColor : Colors.white,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isWithinJourney || isSource
                          ? RailLiveColors.primary.withOpacity(0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Station info ─────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stationName,
                      style: TextStyle(
                        fontSize: isHighlighted ? 16 : 14,
                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                        color: isHighlighted ? Colors.black87 : Colors.black54,
                      ),
                    ),
                  ),
                  if (isSource)
                    _buildTag('FROM', RailLiveColors.primary),
                  if (isDest)
                    _buildTag('TO', Colors.green.shade700),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
