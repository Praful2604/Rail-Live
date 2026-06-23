import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/screens/Bottom_NavigationBar_screens/train_between_stations/display_all_stations.dart';

import '../../models/train_result.dart';
import '../../Providers/station_search_provider.dart';
import '../../app_constant.dart';

class StationSearchScreen extends StatefulWidget {
  const StationSearchScreen({super.key});

  @override
  State<StationSearchScreen> createState() => _StationSearchScreenState();
}

class _StationSearchScreenState extends State<StationSearchScreen> {
  final TextEditingController _sourceCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final FocusNode _sourceFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationSearchProvider>().loadStations();
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _destCtrl.dispose();
    _sourceFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Trains Between Stations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchCard(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  // ── Search card ────────────────────────────────────────────────────

  Widget _buildSearchCard() {
    final provider = context.watch<StationSearchProvider>();

    return Container(
      color: RailLiveColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          // Source field
          _StationInputField(
            controller: _sourceCtrl,
            focusNode: _sourceFocus,
            label: 'From Station',
            icon: Icons.circle_outlined,
            suggestions: provider.sourceSuggestions,
            selected: provider.selectedSource,
            onChanged: (val) => provider.searchSourceStation(val),
            onSelected: (station) {
              _sourceCtrl.text = station.toString();
              provider.selectSource(station);
              _sourceFocus.unfocus();
            },
            onClear: () {
              _sourceCtrl.clear();
              provider.clearSource();
            },
          ),

          const SizedBox(height: 8),

          // Swap button row
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white38)),
              GestureDetector(
                onTap: () {
                  provider.swapStations();
                  _sourceCtrl.text = provider.selectedSource?.toString() ?? '';
                  _destCtrl.text = provider.selectedDest?.toString() ?? '';
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.white38)),
            ],
          ),

          const SizedBox(height: 8),

          // Destination field
          _StationInputField(
            controller: _destCtrl,
            focusNode: _destFocus,
            label: 'To Station',
            icon: Icons.location_on,
            suggestions: provider.destSuggestions,
            selected: provider.selectedDest,
            onChanged: (val) => provider.searchDestStation(val),
            onSelected: (station) {
              _destCtrl.text = station.toString();
              provider.selectDest(station);
              _destFocus.unfocus();
            },
            onClear: () {
              _destCtrl.clear();
              provider.clearDest();
            },
          ),

          const SizedBox(height: 16),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: RailLiveColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search_rounded, size: 22),
              label: const Text(
                'Search Trains',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                provider.fetchTrainsBetweenStations();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Results area ───────────────────────────────────────────────────

  Widget _buildResults() {
    final provider = context.watch<StationSearchProvider>();

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching trains…', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 15),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => provider.fetchTrainsBetweenStations(),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.trains.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.train_rounded,
              size: 64,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search for trains between\ntwo stations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Result count header
        Container(
          width: double.infinity,
          color: RailLiveColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '${provider.trains.length} trains found  •  '
            '${provider.selectedSource!.stationName} → ${provider.selectedDest!.stationName}',
            style: TextStyle(
              color: RailLiveColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Train list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: provider.trains.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _TrainCard(
              train: provider.trains[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DisplayAllStations(train: provider.trains[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Station Input Field ────────────────────────────────────────────────────────

class _StationInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final List<StationSuggestion> suggestions;
  final StationSuggestion? selected;
  final ValueChanged<String> onChanged;
  final ValueChanged<StationSuggestion> onSelected;
  final VoidCallback onClear;

  const _StationInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.suggestions,
    required this.selected,
    required this.onChanged,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white54, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          onChanged: onChanged,
        ),

        // Dropdown suggestions
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return ListTile(
                  leading: const Icon(
                    Icons.train_rounded,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  title: Text(
                    s.stationName,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  subtitle: Text(
                    s.stationCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                  dense: true,
                  onTap: () => onSelected(s),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Train Card ─────────────────────────────────────────────────────────────────

class _TrainCard extends StatelessWidget {
  final TrainResult train;
  final VoidCallback onTap;

  const _TrainCard({required this.train, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header row ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: RailLiveColors.primary.withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.train_rounded,
                      size: 18,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        train.trainName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: RailLiveColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${train.trainNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),

              // ── Route row (no times available — show stations + hops) ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // From
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            train.fromStation,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: RailLiveColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stop ${train.fromIndex + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle: hop count
                    Column(
                      children: [
                        Text(
                          train.stopsBetween > 0
                              ? '${train.stopsBetween} stop${train.stopsBetween == 1 ? '' : 's'}'
                              : 'Direct',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 50,
                              child: CustomPaint(painter: _DashedLinePainter()),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ],
                    ),

                    // To
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            train.toStation,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stop ${train.toIndex + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer: running days ───────────────────────────────
              if (train.runningDays.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    ),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: train.runningDays.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed line painter ────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.2;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
