import 'package:flutter/material.dart';
import 'package:rail_live/Providers/train_detail_provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/utils/coach_utils.dart';

class CoachPositionCard extends StatefulWidget {
  final TrainDetailProvider provider;
  const CoachPositionCard({super.key, required this.provider});
  @override
  State<CoachPositionCard> createState() => _CoachPositionCardState();
}

class _CoachPositionCardState extends State<CoachPositionCard> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.provider.coachLoading) {
      return Container(
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
            Text('Loading coach composition…',
                style: TextStyle(
                    color: RailLiveColors.textHint, fontSize: 13)),
          ],
        ),
      );
    }

    if (widget.provider.coachComposition.isEmpty) return const SizedBox();

    final seenTypes = <String>{};
    final legendTypes = <String>[];
    for (final c in widget.provider.coachComposition) {
      final t = c['coachType']?.toString().toUpperCase() ?? '';
      if (t != 'ENG' && t != 'EOG' && seenTypes.add(t)) legendTypes.add(t);
    }

    final selectedCoach = (_selectedIndex >= 0 &&
        _selectedIndex < widget.provider.coachComposition.length)
        ? widget.provider.coachComposition[_selectedIndex]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COACH POSITION',
                  style: TextStyle(
                    color: RailLiveColors.primary2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RailLiveColors.primary4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.provider.coachComposition.length} coaches',
                    style: const TextStyle(
                      color: RailLiveColors.primary2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Scrollable formation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(widget.provider.coachComposition.length, (i) {
                    final coach = widget.provider.coachComposition[i];
                    final type =
                        coach['coachType']?.toString().toUpperCase() ?? '';
                    final name = coach['coachName']?.toString() ?? '';
                    final isSelected = i == _selectedIndex;
                    final isEngine = type == 'ENG';
                    final isEog = type == 'EOG';

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedIndex = isSelected ? -1 : i;
                      }),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: i < widget.provider.coachComposition.length - 1 ? 4 : 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // YOU pin
                            SizedBox(
                              height: 20,
                              child: isSelected
                                  ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RailLiveColors.primary2,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: RailLiveColors.surface,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                                  : const SizedBox(),
                            ),
                            const SizedBox(height: 2),

                            // Coach body
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isEngine || isEog ? 38 : 33,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected && !isEngine
                                    ? RailLiveColors.primary4
                                    : CoachUtils.bgColor(type),
                                borderRadius: isEngine
                                    ? const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                  topRight: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                )
                                    : isEog
                                    ? const BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                  topLeft: Radius.circular(3),
                                  bottomLeft: Radius.circular(3),
                                )
                                    : BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? RailLiveColors.primary2
                                      : CoachUtils.borderColor(type),
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: RailLiveColors.primary2
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  name.length > 4
                                      ? name.substring(0, 4)
                                      : name,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected && !isEngine
                                        ? RailLiveColors.primary2
                                        : CoachUtils.textColor(type),
                                  ),
                                ),
                              ),
                            ),

                            // Wheels
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _coachWheel(),
                                const SizedBox(width: 5),
                                _coachWheel(),
                              ],
                            ),

                            // Type label
                            const SizedBox(height: 2),
                            Text(
                              isEngine
                                  ? 'Loco'
                                  : isEog
                                  ? 'Guard'
                                  : type == 'GS'
                                  ? 'GEN'
                                  : type,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? RailLiveColors.primary2
                                    : RailLiveColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                // Track rail
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: widget.provider.coachComposition.fold<double>(
                    0,
                        (sum, c) {
                      final t =
                          c['coachType']?.toString().toUpperCase() ?? '';
                      return sum +
                          (t == 'ENG' || t == 'EOG' ? 42 : 37);
                    },
                  ),
                  decoration: BoxDecoration(
                    color: RailLiveColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Direction row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 10, color: RailLiveColors.textHint),
                  const SizedBox(width: 3),
                  Text(widget.provider.origin,
                      style: const TextStyle(
                          fontSize: 10,
                          color: RailLiveColors.textHint,
                          fontWeight: FontWeight.w600)),
                ]),
                Row(children: [
                  Text(widget.provider.destination,
                      style: const TextStyle(
                          fontSize: 10,
                          color: RailLiveColors.textHint,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 10, color: RailLiveColors.textHint),
                ]),
              ],
            ),
          ),

          // Selected coach detail
          if (selectedCoach != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RailLiveColors.primary4,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RailLiveColors.insightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coach ${selectedCoach['coachName']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RailLiveColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: RailLiveColors.primary2
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CoachUtils.typeLabel(
                              selectedCoach['coachType']?.toString() ?? ''),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: RailLiveColors.primary2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _coachDetailStat(
                          'POSITION',
                          '${_selectedIndex + 1} / ${widget.provider.coachComposition.length}',
                        ),
                        _coachDetailDivider(),
                        _coachDetailStat(
                          'CAPACITY',
                          selectedCoach['seatCapacity'] != null &&
                              selectedCoach['seatCapacity'] != 0
                              ? '${selectedCoach['seatCapacity']} seats'
                              : '—',
                        ),
                        _coachDetailDivider(),
                        _coachDetailStat(
                          'CLASS',
                          selectedCoach['coachType']?.toString() ?? '—',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: RailLiveColors.alertSuccessBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RailLiveColors.heatLow),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: RailLiveColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Coach ${selectedCoach['coachName']} is at position'
                                ' ${_selectedIndex + 1} from the engine end',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RailLiveColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Legend
          const SizedBox(height: 12),
          const Divider(
              height: 1, thickness: 0.5, color: RailLiveColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              children: legendTypes
                  .map((type) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: CoachUtils.bgColor(type),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: CoachUtils.borderColor(type),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == 'GS' ? 'GEN' : type,
                    style: const TextStyle(
                      fontSize: 10,
                      color: RailLiveColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ))
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Center(
              child: Text(
                'Swipe to see full formation · Tap any coach to inspect',
                style: TextStyle(
                  fontSize: 10,
                  color: RailLiveColors.textHint.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachWheel() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: RailLiveColors.textSecondary.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _coachDetailStat(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: RailLiveColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: RailLiveColors.textHint,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _coachDetailDivider() {
    return Container(
      width: 1,
      height: 32,
      color: RailLiveColors.insightBorder,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //
}
