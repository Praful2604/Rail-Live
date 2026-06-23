import 'package:flutter/material.dart';

import '../../../models/train_result.dart';
import '../../../app_constant.dart';
import '../../../widgets/stop_row_widget.dart';
import '../../train_details/train_details_screen.dart';

class DisplayAllStations extends StatelessWidget {
  final TrainResult train;

  const DisplayAllStations({super.key, required this.train});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          train.trainName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          Expanded(child: _buildStopsList()),
          _buildTrackButton(context),
        ],
      ),
    );
  }

  // ── Header summary card ─────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      color: RailLiveColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${train.trainNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      train.fromStation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stop ${train.fromIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      train.stopsBetween > 0
                          ? '${train.stopsBetween} stop${train.stopsBetween == 1 ? '' : 's'}'
                          : 'Direct',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      train.toStation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stop ${train.toIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (train.runningDays.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: train.runningDays.map((day) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Full stop list ───────────────────────────────────────────────────

  Widget _buildStopsList() {
    final stops = train.allStops;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final isSource = index == train.fromIndex;
        final isDest = index == train.toIndex;
        final isHighlighted = isSource || isDest;
        final isWithinJourney =
            index > train.fromIndex && index < train.toIndex;
        final isLast = index == stops.length - 1;

        return StopRowWidget(
          stationName: stops[index],
          stopNumber: index + 1,
          isSource: isSource,
          isDest: isDest,
          isHighlighted: isHighlighted,
          isWithinJourney: isWithinJourney,
          isLast: isLast,
        );
      },
    );
  }

  // ── Track Live Status button ────────────────────────────────────────

  Widget _buildTrackButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: RailLiveColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: RailLiveColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.gps_fixed_rounded, size: 20),
          label: const Text(
            'Track Live Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),

          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainDetailScreen(
                  trainData: {
                    'trainName': train.trainName,
                    'trainNumber': train.trainNumber,
                    'origin': train.fromStation,
                    'destination': train.toStation,
                  },
                  trainNumber: train.trainNumber,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
