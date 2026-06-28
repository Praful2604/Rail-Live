import 'package:flutter/material.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/utils/train_utils.dart';

class RouteTimelineCard extends StatelessWidget {
  final TrainDetailProvider provider;
  final Animation<double> pulseAnimation;
  final TimeOfDay now;

  const RouteTimelineCard({
    super.key,
    required this.provider,
    required this.pulseAnimation,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final stations = provider.liveStations;
    if (stations.isEmpty) return const SizedBox();

    final currentIdx = provider.currentStationIndex;
    final lastDepIdx = provider.lastDepartedIndex;
    final trainProgress = provider.trainProgressBetweenStations;

    return Container(
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text('ROUTE TIMELINE',
                    style: TextStyle(
                        color: RailLiveColors.primary2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RailLiveColors.primary4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stations.length} stations',
                    style: const TextStyle(
                        color: RailLiveColors.primary2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RailLiveColors.primary4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Now ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: RailLiveColors.primary2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Center(
                    child: Text('ARRIVAL',
                        style: TextStyle(
                            color: RailLiveColors.textHint,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                  ),
                ),
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 76,
                  child: Center(
                    child: Text('DEPARTURE',
                        style: TextStyle(
                            color: RailLiveColors.textHint,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
              height: 1,
              thickness: 0.5,
              color: RailLiveColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 0.4,
                indent: 76,
                endIndent: 76,
                color: RailLiveColors.border),
            itemBuilder: (context, index) {
              final station = stations[index] as Map<String, dynamic>;
              final isLast = index == stations.length - 1;
              final isCurrentStation = index == currentIdx;
              final nextIdx =
              provider.isTrainAtStation ? currentIdx + 1 : lastDepIdx + 1;
              final isNextStation =
                  !isCurrentStation && index == nextIdx;
              final isPassed = provider.stationIsPassed(index);
              final showTrainOnConnector =
                  !provider.isTrainAtStation && index == lastDepIdx && !isLast;

              return _buildStationRow(
                station: station,
                index: index,
                isLast: isLast,
                isPassed: isPassed,
                isCurrentStation: isCurrentStation,
                isNextStation: isNextStation,
                showTrainOnConnector: showTrainOnConnector,
                trainProgress: trainProgress,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  STATION ROW
  // ══════════════════════════════════════════════════════════════════

  Widget _buildStationRow({
    required Map<String, dynamic> station,
    required int index,
    required bool isLast,
    required bool isPassed,
    required bool isCurrentStation,
    required bool isNextStation,
    required bool showTrainOnConnector,
    required double trainProgress,
  }) {
    final stnSerial = station['stnSerialNumber']?.toString() ?? '';
    final isSource = stnSerial == '1';
    final isDestination = isLast;

    final scheduledArr = station['arrivalTime']?.toString();
    final scheduledDep = station['departureTime']?.toString();
    final actualArr = station['actual_arrival_time']?.toString();
    final actualDep = station['actual_departure_time']?.toString();

    final stationName = station['stationName']?.toString() ?? '—';
    final stationCode = station['stationCode']?.toString() ?? '';
    final distance = station['distance']?.toString() ?? '';
    final expectedPlatform = station['expected_platform']?.toString() ?? '';

    final hasActualArr =
        actualArr != null && actualArr.isNotEmpty && actualArr != '--';
    final hasActualDep =
        actualDep != null && actualDep.isNotEmpty && actualDep != '--';

    final arrDelay =
    TrainUtils.delayMinutes(scheduledArr, hasActualArr ? actualArr : null);
    final depDelay =
    TrainUtils.delayMinutes(scheduledDep, hasActualDep ? actualDep : null);

    final haltTime = TrainUtils.getHaltTime(station);
    final connectorHeight = showTrainOnConnector ? 80.0 : 56.0;

    Color rowBg = Colors.transparent;
    if (isCurrentStation) {
      rowBg = RailLiveColors.primary4.withValues(alpha: 0.5);
    }

    return ColoredBox(
      color: rowBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, left: 6, right: 4, bottom: 8),
              child: isSource
                  ? const SizedBox()
                  : _buildTimeColumn(
                scheduled: scheduledArr,
                actual: hasActualArr ? actualArr : null,
                delay: arrDelay,
                isPassed: isPassed || isCurrentStation,
                haltTime: null,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildTimelineNode(
                        isPassed: isPassed,
                        isCurrentStation: isCurrentStation,
                        isNextStation: isNextStation,
                        isSource: isSource,
                        isDestination: isDestination,
                      ),
                      if (!isLast)
                        SizedBox(
                          height: connectorHeight,
                          child: showTrainOnConnector
                              ? _buildAnimatedConnector(trainProgress)
                              : _buildConnectorLine(isPassed),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: isLast ? 14 : 0,
                      right: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                stationName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  (isCurrentStation || isNextStation)
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isCurrentStation
                                      ? RailLiveColors.primary2
                                      : isPassed
                                      ? RailLiveColors.textSecondary
                                      : RailLiveColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentStation)
                              _smallBadge('CURRENT', RailLiveColors.primary2),
                            if (isNextStation)
                              _smallBadge('NEXT', RailLiveColors.primary2),
                            if (isSource)
                              _smallBadge('ORIGIN', RailLiveColors.success),
                            if (isDestination)
                              _smallBadge('DEST', RailLiveColors.error),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            if (stationCode.isNotEmpty)
                              _metaText(stationCode),
                            if (distance.isNotEmpty &&
                                distance != '-' &&
                                distance != '0')
                              _metaText('$distance km'),
                            if (expectedPlatform.isNotEmpty &&
                                expectedPlatform != '0')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_transit,
                                      size: 10,
                                      color: RailLiveColors.textHint),
                                  const SizedBox(width: 2),
                                  _metaText('Pf $expectedPlatform'),
                                ],
                              ),
                            if (haltTime != null &&
                                !isSource &&
                                !isDestination)
                              _haltBadge(haltTime),
                          ],
                        ),
                        if (isCurrentStation) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: RailLiveColors.liveGreen,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              const Text('Train is here',
                                  style: TextStyle(
                                      color: RailLiveColors.liveGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                        if (!isLast) SizedBox(height: connectorHeight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, right: 6, left: 4, bottom: 8),
              child: isDestination
                  ? const SizedBox()
                  : _buildTimeColumn(
                scheduled: scheduledDep,
                actual: hasActualDep ? actualDep : null,
                delay: depDelay,
                isPassed: isPassed,
                haltTime: haltTime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TIME COLUMN
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTimeColumn({
    required String? scheduled,
    required String? actual,
    required int? delay,
    required bool isPassed,
    String? haltTime,
  }) {
    final hasActual = actual != null && actual.isNotEmpty && actual != '--';
    final primaryTime = hasActual ? TrainUtils.formatTime(actual) : TrainUtils.formatTime(scheduled);
    final primaryColor = hasActual
        ? (delay != null && delay > 0
        ? RailLiveColors.warning
        : RailLiveColors.success)
        : RailLiveColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          primaryTime,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          hasActual
              ? 'SCH ${TrainUtils.formatTime(scheduled)}'
              : 'TT ${TrainUtils.formatTime(scheduled)}',
          style: TextStyle(
              color: hasActual
                  ? RailLiveColors.textHint
                  : RailLiveColors.textHint.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        if (haltTime != null && haltTime.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.qaBlue,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RailLiveColors.primary3.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined,
                    size: 8, color: RailLiveColors.primary2),
                const SizedBox(width: 2),
                Text(
                  '${haltTime}m halt',
                  style: const TextStyle(
                      color: RailLiveColors.primary2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        if (delay != null && delay > 0) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.alertWarnBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('+$delay m',
                style: const TextStyle(
                    color: RailLiveColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],
        if (isPassed && (delay == null || delay <= 0) && hasActual) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.alertSuccessBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('On Time',
                style: TextStyle(
                    color: RailLiveColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TIMELINE NODES
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTimelineNode({
    required bool isPassed,
    required bool isCurrentStation,
    required bool isNextStation,
    required bool isSource,
    required bool isDestination,
  }) {
    if (isCurrentStation) {
      return ScaleTransition(
        scale: pulseAnimation,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: RailLiveColors.primary2,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: RailLiveColors.primary2.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.train, color: Colors.white, size: 15),
        ),
      );
    }
    if (isSource) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: RailLiveColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.circle, color: Colors.white, size: 10),
      );
    }
    if (isDestination) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: isPassed ? RailLiveColors.primary2 : RailLiveColors.border,
            shape: BoxShape.circle),
        child: const Icon(Icons.flag, color: Colors.white, size: 13),
      );
    }
    if (isPassed) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: RailLiveColors.primary2, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }
    if (isNextStation) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: RailLiveColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: RailLiveColors.primary2, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: RailLiveColors.primary2, shape: BoxShape.circle),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: RailLiveColors.border, width: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  CONNECTORS
  // ══════════════════════════════════════════════════════════════════

  Widget _buildConnectorLine(bool isPassed) {
    return Center(
      child: Container(
        width: 2,
        color: isPassed ? RailLiveColors.primary2 : RailLiveColors.border,
      ),
    );
  }

  Widget _buildAnimatedConnector(double progress) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalH = constraints.maxHeight;
      const iconSize = 26.0;
      final topOffset =
      ((totalH - iconSize) * progress).clamp(0.0, totalH - iconSize);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 15,
            child: Container(
              width: 2,
              height: topOffset + iconSize / 2,
              color: RailLiveColors.primary2,
            ),
          ),
          Positioned(
            top: topOffset + iconSize / 2,
            left: 15,
            child: Container(
              width: 2,
              height: (totalH - (topOffset + iconSize / 2))
                  .clamp(0.0, totalH),
              color: RailLiveColors.border,
            ),
          ),
          Positioned(
            top: topOffset,
            left: 2,
            child: ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: RailLiveColors.primary2,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: RailLiveColors.primary2.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                const Icon(Icons.train, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  MICRO-WIDGETS
  // ══════════════════════════════════════════════════════════════════

  Widget _smallBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4),
      ),
    );
  }

  Widget _haltBadge(String minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: RailLiveColors.qaBlue,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: RailLiveColors.primary3.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 9, color: RailLiveColors.primary2),
          const SizedBox(width: 3),
          Text(
            '${minutes}m halt',
            style: const TextStyle(
                color: RailLiveColors.primary2,
                fontSize: 9,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _metaText(String text) {
    return Text(text,
        style: const TextStyle(
            color: RailLiveColors.textHint, fontSize: 11));
  }
}
