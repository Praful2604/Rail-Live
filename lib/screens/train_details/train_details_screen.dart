import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/Providers/train_provider.dart';
import 'package:rail_live/app_constant.dart';

import 'widgets/coach_position_card.dart';
import 'widgets/live_tracking_card.dart';
import 'widgets/route_timeline.dart';
import 'widgets/status_summary_card.dart';
import 'widgets/train_detail_header.dart';
import 'widgets/train_detail_status_cards.dart';
import 'widgets/train_info_card.dart';

class TrainDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trainData;
  final String trainNumber;

  const TrainDetailScreen({
    super.key,
    required this.trainData,
    required this.trainNumber,
  });

  @override
  State<TrainDetailScreen> createState() => _TrainDetailScreenState();
}

class _TrainDetailScreenState extends State<TrainDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TrainDetailProvider _detailProvider;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _clockTimer;
  TimeOfDay _now = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _detailProvider = TrainDetailProvider()
      ..init(
        trainNumber: widget.trainNumber,
        trainData: widget.trainData,
      );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = TimeOfDay.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    _detailProvider.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final trainProvider = context.read<TrainProvider>();
    await _detailProvider.refresh(trainProvider: trainProvider);
    if (mounted) setState(() => _now = TimeOfDay.now());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TrainDetailProvider>.value(
      value: _detailProvider,
      child: Consumer<TrainDetailProvider>(
        builder: (context, detail, _) {
          return Scaffold(
            backgroundColor: RailLiveColors.background,
            body: Column(
              children: [
                TrainDetailHeader(
                  trainNumber: detail.trainNumber,
                  trainName: detail.trainName,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrainInfoCard(provider: detail),
                          const SizedBox(height: 12),
                          if (detail.coachComposition.isNotEmpty ||
                              detail.coachLoading)
                            CoachPositionCard(provider: detail),
                          if (detail.coachComposition.isNotEmpty ||
                              detail.coachLoading)
                            const SizedBox(height: 12),
                          if (detail.liveLoading)
                            const TrainDetailLoadingCard(),
                          if (!detail.liveLoading && detail.liveError != null)
                            TrainDetailErrorCard(
                              message: detail.liveError!,
                              onRetry: detail.fetchLiveStatus,
                            ),
                          if (!detail.liveLoading &&
                              detail.liveError == null &&
                              detail.liveStatus != null) ...[
                            LiveTrackingCard(
                              provider: detail,
                              pulseAnimation: _pulseAnimation,
                            ),
                            const SizedBox(height: 12),
                            if (detail.liveStations.isNotEmpty) ...[
                              StatusSummaryCard(provider: detail),
                              const SizedBox(height: 16),
                              RouteTimelineCard(
                                provider: detail,
                                pulseAnimation: _pulseAnimation,
                                now: _now,
                              ),
                            ],
                          ],
                          if (!detail.liveLoading &&
                              detail.liveError == null &&
                              detail.liveStations.isEmpty)
                            const TrainDetailNoDataCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
