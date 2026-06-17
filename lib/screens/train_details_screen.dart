import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/providers/train_provider.dart';
import 'package:rail_live/screens/train_chat_screen.dart';

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
  Timer? _refreshTimer;
  Timer? _clockTimer;
  late Map<String, dynamic> _currentData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  TimeOfDay _now = TimeOfDay.now();

  // Live status
  Map<String, dynamic>? liveStatus;
  bool liveLoading = false;
  String? liveError;

  // Coach composition
  List<Map<String, dynamic>> coachComposition = [];
  bool coachLoading = false;
  String? coachError;
  int _selectedCoachIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentData = widget.trainData;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = TimeOfDay.now());
    });

    _pulseController.repeat(reverse: true);
    _fetchLiveStatus();
    _fetchCoachComposition();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  // ══════════════════════════════════════════════════════════════════
  //  FETCH LIVE STATUS
  // ══════════════════════════════════════════════════════════════════

  Future<void> _fetchLiveStatus() async {
    if (!mounted) return;
    setState(() {
      liveLoading = true;
      liveError = null;
    });

    try {
      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final uri = Uri.https(
        'indian-railway-irctc.p.rapidapi.com',
        '/api/trains/v1/train/status',
        {
          'departure_date': today,
          'isH5': 'true',
          'client': 'web',
          'train_number': widget.trainNumber,
        },
      );

      final response = await http.get(uri, headers: {
        'x-rapidapi-host': 'indian-railway-irctc.p.rapidapi.com',
        'x-rapidapi-key': 'f6e08704ecmsha3ab93df2f22de0p1cf569jsnf7a107f723ae',
      });

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          jsonData['status']?['result'] == 'success') {
        final stations = jsonData['body']?['stations'] as List?;
        if (stations != null && stations.length > 1) {
          debugPrint('STATION FIELDS: ${stations[1]}');
        }
        if (mounted) setState(() => liveStatus = jsonData);
      } else {
        if (mounted) {
          setState(() {
            liveError = jsonData['status']?['message']?['message'] ??
                'Unable to fetch live status';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => liveError = e.toString());
    }

    if (mounted) setState(() => liveLoading = false);
  }

  // ══════════════════════════════════════════════════════════════════
  //  FETCH COACH COMPOSITION
  // ══════════════════════════════════════════════════════════════════

  Future<void> _fetchCoachComposition() async {
    if (!mounted) return;
    setState(() {
      coachLoading = true;
      coachError = null;
    });

    try {
      final uri = Uri.https(
        'indian-railway-irctc.p.rapidapi.com',
        '/api/trains/v1/train/coach-composition',
        {'train_number': widget.trainNumber},
      );

      final response = await http.get(uri, headers: {
        'x-rapidapi-host': 'indian-railway-irctc.p.rapidapi.com',
        'x-rapidapi-key': 'f6e08704ecmsha3ab93df2f22de0p1cf569jsnf7a107f723ae',
      });

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          jsonData['status']?['result'] == 'success') {
        final coaches = jsonData['body']?['coaches'] as List? ?? [];
        if (mounted) {
          setState(() {
            coachComposition =
                coaches.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      } else {
        if (mounted) {
          setState(() => coachComposition = _buildFallbackComposition());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          coachComposition = _buildFallbackComposition();
          coachError = null;
        });
      }
    }

    if (mounted) setState(() => coachLoading = false);
  }

  List<Map<String, dynamic>> _buildFallbackComposition() {
    return [
      {'coachName': 'ENG', 'coachType': 'ENG', 'seatCapacity': 0},
      {'coachName': 'H1',  'coachType': 'EOG', 'seatCapacity': 0},
      {'coachName': 'A1',  'coachType': '1A',  'seatCapacity': 18},
      {'coachName': 'B1',  'coachType': '2A',  'seatCapacity': 46},
      {'coachName': 'B2',  'coachType': '2A',  'seatCapacity': 46},
      {'coachName': 'B3',  'coachType': '2A',  'seatCapacity': 46},
      {'coachName': 'C1',  'coachType': '3A',  'seatCapacity': 64},
      {'coachName': 'C2',  'coachType': '3A',  'seatCapacity': 64},
      {'coachName': 'C3',  'coachType': '3A',  'seatCapacity': 64},
      {'coachName': 'C4',  'coachType': '3A',  'seatCapacity': 64},
      {'coachName': 'S1',  'coachType': 'SL',  'seatCapacity': 72},
      {'coachName': 'S2',  'coachType': 'SL',  'seatCapacity': 72},
      {'coachName': 'GS',  'coachType': 'GEN', 'seatCapacity': 0},
      {'coachName': 'EOG', 'coachType': 'EOG', 'seatCapacity': 0},
    ];
  }

  Future<void> _refresh() async {
    await _fetchLiveStatus();
    await _fetchCoachComposition();
    if (!mounted) return;
    final provider = context.read<TrainProvider>();
    await provider.fetchTrain(widget.trainNumber);
    if (provider.trainData != null && mounted) {
      setState(() {
        _currentData = provider.trainData!;
        _now = TimeOfDay.now();
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  DATA HELPERS
  // ══════════════════════════════════════════════════════════════════

  String get trainName =>
      _currentData['trainName']?.toString() ??
          _currentData['train_name']?.toString() ??
          'Unknown Train';

  String get trainNumber =>
      _currentData['trainNumber']?.toString() ??
          _currentData['train_number']?.toString() ??
          widget.trainNumber;

  String get origin => _currentData['origin']?.toString() ?? '';
  String get destination => _currentData['destination']?.toString() ?? '';

  String get trainType =>
      _currentData['trainType']?.toString() ??
          _currentData['train_type']?.toString() ??
          '';

  String get runningDays {
    final days = _currentData['runningDays'];
    if (days == null) return '';
    if (days is List) return days.join(', ');
    return days.toString();
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIVE STATUS HELPERS
  // ══════════════════════════════════════════════════════════════════

  List<dynamic> get liveStations {
    try {
      return (liveStatus?['body']?['stations'] as List?) ?? [];
    } catch (_) {
      return [];
    }
  }

  String get liveTrainStatusMessage {
    final raw = liveStatus?['body']?['train_status_message']?.toString() ?? '';
    return raw.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get liveCurrentStation =>
      liveStatus?['body']?['current_station']?.toString() ?? '';

  bool get liveTerminated => liveStatus?['body']?['terminated'] == true;

  String get liveTimeOfAvailability =>
      liveStatus?['body']?['time_of_availability']?.toString() ?? '';

  // ══════════════════════════════════════════════════════════════════
  //  TIME HELPERS
  // ══════════════════════════════════════════════════════════════════

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '--') return null;
    final s = raw.trim();
    try {
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) {
        final parts = s.split(':');
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateFormat('hh:mm a').parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtTime(String? raw) {
    final dt = _parseTime(raw);
    if (dt == null) return '--';
    return DateFormat('hh:mm a').format(dt);
  }

  // ══════════════════════════════════════════════════════════════════
  //  STATION STATE HELPERS
  // ══════════════════════════════════════════════════════════════════

  bool _stationHasDeparted(Map<String, dynamic> s) {
    final d = s['actual_departure_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }

  bool _stationHasArrived(Map<String, dynamic> s) {
    final d = s['actual_arrival_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }

  // ══════════════════════════════════════════════════════════════════
  //  TRAIN INFO CARD HELPERS
  // ══════════════════════════════════════════════════════════════════

  String get departureTime {
    if (liveStations.isNotEmpty) {
      final src = liveStations.first as Map<String, dynamic>;
      final actual = src['actual_departure_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return _fmtTime(actual);
      return _fmtTime(src['departureTime']?.toString());
    }
    return _currentData['departureTime']?.toString() ??
        _currentData['departure_time']?.toString() ??
        '--';
  }

  String get arrivalTime {
    if (liveStations.isNotEmpty) {
      final dst = liveStations.last as Map<String, dynamic>;
      final actual = dst['actual_arrival_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return _fmtTime(actual);
      return _fmtTime(dst['arrivalTime']?.toString());
    }
    return _currentData['arrivalTime']?.toString() ??
        _currentData['arrival_time']?.toString() ??
        '--';
  }

  String get status {
    if (liveTerminated) return 'Terminated';
    if (_liveIsOnTime) return 'On Time';
    return '$_liveCurrentDelayText min late';
  }

  String get duration {
    if (liveStations.length >= 2) {
      final depRaw = (liveStations.first as Map<String, dynamic>)['departureTime']?.toString();
      final arrRaw = (liveStations.last as Map<String, dynamic>)['arrivalTime']?.toString();
      final dep = _parseTime(depRaw);
      final arr = _parseTime(arrRaw);
      if (dep != null && arr != null) {
        int mins = arr.difference(dep).inMinutes;
        if (mins < 0) mins += 24 * 60;
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0 ? '${h}h' : '${h}h ${m}m';
      }
    }
    return _currentData['duration']?.toString() ?? '--';
  }

  int get _currentStationIndex {
    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      if (_stationHasArrived(s) && !_stationHasDeparted(s)) return i;
    }
    return -1;
  }

  int get _lastDepartedIndex {
    int last = -1;
    for (int i = 0; i < liveStations.length; i++) {
      if (_stationHasDeparted(liveStations[i] as Map<String, dynamic>)) {
        last = i;
      }
    }
    return last;
  }

  bool get isTrainAtStation => _currentStationIndex >= 0;

  int get _activeIndex =>
      isTrainAtStation ? _currentStationIndex : _lastDepartedIndex;

  double get _trainProgressBetweenStations {
    final depIdx = _lastDepartedIndex;
    if (depIdx < 0 || depIdx >= liveStations.length - 1) return 0.0;
    final nextIdx = depIdx + 1;
    final depStation = liveStations[depIdx] as Map<String, dynamic>;
    final nextStation = liveStations[nextIdx] as Map<String, dynamic>;
    final depTime = _parseTime(
        depStation['actual_departure_time']?.toString() ??
            depStation['departureTime']?.toString());
    final arrTime = _parseTime(nextStation['arrivalTime']?.toString());
    if (depTime == null || arrTime == null) return 0.5;
    final now = DateTime.now();
    final total = arrTime.difference(depTime).inSeconds;
    final elapsed = now.difference(depTime).inSeconds;
    if (total <= 0) return 0.5;
    return (elapsed / total).clamp(0.05, 0.95);
  }

  int? _delayMinutes(String? scheduled, String? actual) {
    final sch = _parseTime(scheduled);
    final act = _parseTime(actual);
    if (sch == null || act == null) return null;
    final diff = act.difference(sch).inMinutes;
    return diff <= 0 ? null : diff;
  }

  String? _getHaltTime(Map<String, dynamic> station) {
    final candidates = [
      station['haltTime'],
      station['halt_time'],
      station['halt'],
      station['haltDuration'],
      station['halt_duration'],
      station['stopTime'],
      station['stop_time'],
    ];
    for (final val in candidates) {
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str != '0' && str != '--' && str != 'null') {
          return str;
        }
      }
    }
    final arr = _parseTime(station['arrivalTime']?.toString());
    final dep = _parseTime(station['departureTime']?.toString());
    if (arr != null && dep != null) {
      final diff = dep.difference(arr).inMinutes;
      if (diff > 0) return diff.toString();
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════
  //  SUMMARY GETTERS
  // ══════════════════════════════════════════════════════════════════

  String get _liveCurrentDelayText {
    final idx = _activeIndex;
    if (idx < 0) return '0';
    final s = liveStations[idx] as Map<String, dynamic>;
    final dep = _delayMinutes(
        s['departureTime']?.toString(), s['actual_departure_time']?.toString());
    if (dep != null && dep > 0) return dep.toString();
    final arr = _delayMinutes(
        s['arrivalTime']?.toString(), s['actual_arrival_time']?.toString());
    if (arr != null && arr > 0) return arr.toString();
    return '0';
  }

  bool get _liveIsOnTime {
    final d = _liveCurrentDelayText.trim();
    return d == '0' || d.isEmpty;
  }

  String get _liveNextStationName {
    final nextIdx =
    isTrainAtStation ? _currentStationIndex + 1 : _lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      return (liveStations[nextIdx] as Map<String, dynamic>)['stationName']
          ?.toString() ??
          '—';
    }
    return '—';
  }

  String get _liveEtaForNext {
    final nextIdx =
    isTrainAtStation ? _currentStationIndex + 1 : _lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      final s = liveStations[nextIdx] as Map<String, dynamic>;
      return _fmtTime(s['arrivalTime']?.toString());
    }
    return '—';
  }

  int get _livePassedCount {
    int count = 0;
    for (final s in liveStations) {
      if (_stationHasDeparted(s as Map<String, dynamic>)) count++;
    }
    return count;
  }

  // ══════════════════════════════════════════════════════════════════
  //  COACH COLOR HELPERS
  // ══════════════════════════════════════════════════════════════════

  Color _coachBgColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':  return RailLiveColors.qaPurple;
      case '2A':  return RailLiveColors.qaGreen;
      case '3A':  return RailLiveColors.qaBlue;
      case 'SL':  return RailLiveColors.qaAmber;
      case 'GEN':
      case 'GS':  return RailLiveColors.qaPink;
      case 'ENG': return RailLiveColors.primary;
      case 'EOG': return RailLiveColors.surface2;
      default:    return RailLiveColors.border;
    }
  }

  Color _coachBorderColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':  return RailLiveColors.languageIcon;
      case '2A':  return RailLiveColors.success;
      case '3A':  return RailLiveColors.primary2;
      case 'SL':  return RailLiveColors.notifIcon;
      case 'GEN':
      case 'GS':  return RailLiveColors.accent;
      case 'ENG': return RailLiveColors.primary;
      case 'EOG': return RailLiveColors.border;
      default:    return RailLiveColors.border;
    }
  }

  Color _coachTextColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':  return RailLiveColors.languageIcon;
      case '2A':  return RailLiveColors.success;
      case '3A':  return RailLiveColors.primary2;
      case 'SL':  return RailLiveColors.warning;
      case 'GEN':
      case 'GS':  return RailLiveColors.accent;
      case 'ENG': return RailLiveColors.surface;
      case 'EOG': return RailLiveColors.textSecondary;
      default:    return RailLiveColors.textHint;
    }
  }

  String _coachTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case '1A':  return 'First AC';
      case '2A':  return 'Second AC';
      case '3A':  return 'Third AC';
      case 'SL':  return 'Sleeper';
      case 'GEN':
      case 'GS':  return 'General';
      case 'ENG': return 'Locomotive';
      case 'EOG': return 'Power Car';
      default:    return type;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrainInfoCard(),
                    const SizedBox(height: 12),
                    if (coachComposition.isNotEmpty || coachLoading)
                      _buildCoachPositionCard(),
                    if (coachComposition.isNotEmpty || coachLoading)
                      const SizedBox(height: 12),
                    if (liveLoading) _buildLoadingCard(),
                    if (!liveLoading && liveError != null) _buildErrorCard(),
                    if (!liveLoading && liveError == null && liveStatus != null) ...[
                      _buildLiveTrackingCard(),
                      const SizedBox(height: 12),
                      if (liveStations.isNotEmpty) ...[
                        _buildStatusSummaryCard(),
                        const SizedBox(height: 16),
                        _buildRouteTimeline(),
                      ],
                    ],
                    if (!liveLoading &&
                        liveError == null &&
                        liveStations.isEmpty)
                      _buildNoDataCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RailLiveColors.primary2, RailLiveColors.primary3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _headerIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trainNumber} · $trainName',
                      style: const TextStyle(
                          color: RailLiveColors.surface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: RailLiveColors.liveGreen,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Text('LIVE · Auto-refresh every 60s',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.wechat_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainChatScreen(
                        trainNumber: trainNumber,
                        trainName: trainName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LOADING CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLoadingCard() {
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
          Text('Fetching live train status…',
              style:
              TextStyle(color: RailLiveColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  ERROR CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildErrorCard() {
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
          Icon(Icons.error_outline, color: RailLiveColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(liveError!,
                style: TextStyle(
                    color: RailLiveColors.error, fontSize: 13)),
          ),
          TextButton(
            onPressed: _fetchLiveStatus,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  NO DATA CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.alertWarnBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: RailLiveColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: RailLiveColors.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Live schedule data is not available for this train right now.',
              style: TextStyle(
                  color: RailLiveColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TRAIN INFO CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTrainInfoCard() {
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
                trainName,
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
                  trainNumber,
                  style: const TextStyle(
                      fontSize: 12, color: RailLiveColors.textSecondary),
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
                    _stationDot(filled: true),
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
                              RailLiveColors.border
                                  .withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _stationDot(filled: false),
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
                          Text(origin,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: RailLiveColors.textPrimary)),
                          Text('DEP · $departureTime',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: RailLiveColors.textHint)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destination,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: RailLiveColors.textPrimary)),
                          Text('ARR · $arrivalTime',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: RailLiveColors.textHint)),
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
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _liveIsOnTime
                            ? RailLiveColors.success
                            : RailLiveColors.warning,
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                          fontSize: 12, color: RailLiveColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trainType.isNotEmpty || runningDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: RailLiveColors.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (trainType.isNotEmpty)
                  _infoBadge(Icons.train_outlined, trainType),
                if (runningDays.isNotEmpty)
                  _infoBadge(Icons.calendar_today_outlined, runningDays),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationDot({required bool filled}) {
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

  Widget _infoBadge(IconData icon, String label) {
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RailLiveColors.primary2)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  COACH POSITION CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildCoachPositionCard() {
    if (coachLoading) {
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

    if (coachComposition.isEmpty) return const SizedBox();

    final seenTypes = <String>{};
    final legendTypes = <String>[];
    for (final c in coachComposition) {
      final t = c['coachType']?.toString().toUpperCase() ?? '';
      if (t != 'ENG' && t != 'EOG' && seenTypes.add(t)) legendTypes.add(t);
    }

    final selectedCoach = (_selectedCoachIndex >= 0 &&
        _selectedCoachIndex < coachComposition.length)
        ? coachComposition[_selectedCoachIndex]
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
                    '${coachComposition.length} coaches',
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
                  children: List.generate(coachComposition.length, (i) {
                    final coach = coachComposition[i];
                    final type =
                        coach['coachType']?.toString().toUpperCase() ?? '';
                    final name = coach['coachName']?.toString() ?? '';
                    final isSelected = i == _selectedCoachIndex;
                    final isEngine = type == 'ENG';
                    final isEog = type == 'EOG';

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCoachIndex = isSelected ? -1 : i;
                      }),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: i < coachComposition.length - 1 ? 4 : 0),
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
                                    : _coachBgColor(type),
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
                                      : _coachBorderColor(type),
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
                                        : _coachTextColor(type),
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
                  width: coachComposition.fold<double>(
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
                  Text(origin,
                      style: const TextStyle(
                          fontSize: 10,
                          color: RailLiveColors.textHint,
                          fontWeight: FontWeight.w600)),
                ]),
                Row(children: [
                  Text(destination,
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
                          _coachTypeLabel(
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
                          '${_selectedCoachIndex + 1} / ${coachComposition.length}',
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
                                ' ${_selectedCoachIndex + 1} from the engine end',
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
                      color: _coachBgColor(type),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: _coachBorderColor(type),
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
  //  LIVE TRACKING CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLiveTrackingCard() {
    final body = liveStatus?['body'] as Map<String, dynamic>?;
    if (body == null) return const SizedBox();

    final currentCode = liveCurrentStation;
    final message = liveTrainStatusMessage;
    final timeAvail = liveTimeOfAvailability;
    final terminated = liveTerminated;

    Map<String, dynamic>? currentStn;
    for (final s in liveStations) {
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
                  scale: _pulseAnimation,
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
                  value: '$_livePassedCount',
                  color: RailLiveColors.liveGreen,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.schedule,
                  label: 'Delay',
                  value: _liveIsOnTime
                      ? 'On Time'
                      : '$_liveCurrentDelayText min',
                  color: _liveIsOnTime
                      ? RailLiveColors.liveGreen
                      : RailLiveColors.warning,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.arrow_forward,
                  label: 'Next',
                  value: _liveNextStationName,
                  color: Colors.white,
                  maxLines: 1,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: _liveEtaForNext,
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
  //  STATUS SUMMARY CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildStatusSummaryCard() {
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
                      _liveIsOnTime
                          ? 'On Time'
                          : '$_liveCurrentDelayText min',
                      style: TextStyle(
                          color: _liveIsOnTime
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
                            _liveIsOnTime
                                ? Icons.check_circle_outline
                                : Icons.access_time,
                            color: _liveIsOnTime
                                ? RailLiveColors.liveGreen
                                : RailLiveColors.accent2,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _liveIsOnTime ? 'ON TIME' : 'DELAYED',
                            style: TextStyle(
                                color: _liveIsOnTime
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
                      _liveNextStationName,
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
                          _liveEtaForNext,
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
                '$_livePassedCount / ${liveStations.length} stations',
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
              value: liveStations.isEmpty
                  ? 0
                  : _livePassedCount / liveStations.length,
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
  //  ROUTE TIMELINE
  // ══════════════════════════════════════════════════════════════════

  Widget _buildRouteTimeline() {
    final stations = liveStations;
    if (stations.isEmpty) return const SizedBox();

    final currentIdx = _currentStationIndex;
    final lastDepIdx = _lastDepartedIndex;
    final trainProgress = _trainProgressBetweenStations;

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
                    'Now ${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
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
            separatorBuilder: (_, __) => const Divider(
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
              isTrainAtStation ? currentIdx + 1 : lastDepIdx + 1;
              final isNextStation =
                  !isCurrentStation && index == nextIdx;
              final isPassed = _stationHasDeparted(station);
              final showTrainOnConnector =
                  !isTrainAtStation && index == lastDepIdx && !isLast;

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
    _delayMinutes(scheduledArr, hasActualArr ? actualArr : null);
    final depDelay =
    _delayMinutes(scheduledDep, hasActualDep ? actualDep : null);

    final haltTime = _getHaltTime(station);
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
    final primaryTime = hasActual ? _fmtTime(actual) : _fmtTime(scheduled);
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
              ? 'SCH ${_fmtTime(scheduled)}'
              : 'TT ${_fmtTime(scheduled)}',
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
        scale: _pulseAnimation,
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
              scale: _pulseAnimation,
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






















/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/providers/clock_provider.dart';
import 'package:rail_live/providers/live_status_provider.dart';
import 'package:rail_live/providers/train_provider.dart';
import 'package:rail_live/screens/train_chat_screen.dart';

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveStatusProvider>().init(widget.trainNumber);
      context.read<ClockProvider>().startClock();
    });
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<LiveStatusProvider>().stopAutoRefresh();
      context.read<ClockProvider>().stopClock();
    }
    _pulseController.dispose();
    super.dispose();
  }

  // ── Data helpers (from TrainProvider / widget.trainData) ─────────

  String get trainName =>
      widget.trainData['trainName']?.toString() ??
          widget.trainData['train_name']?.toString() ??
          'Unknown Train';

  String get trainNumber =>
      widget.trainData['trainNumber']?.toString() ??
          widget.trainData['train_number']?.toString() ??
          widget.trainNumber;

  String get origin => widget.trainData['origin']?.toString() ?? '';
  String get destination => widget.trainData['destination']?.toString() ?? '';

  String get trainType =>
      widget.trainData['trainType']?.toString() ??
          widget.trainData['train_type']?.toString() ??
          '';

  String get runningDays {
    final days = widget.trainData['runningDays'];
    if (days == null) return '';
    if (days is List) return days.join(', ');
    return days.toString();
  }

  // ── Refresh ──────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final liveProvider = context.read<LiveStatusProvider>();
    final trainProvider = context.read<TrainProvider>();

    await liveProvider.fetchLiveStatus();
    await trainProvider.fetchTrain(widget.trainNumber);
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<LiveStatusProvider>(
              builder: (context, live, _) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTrainInfoCard(live),
                        const SizedBox(height: 12),
                        if (live.liveLoading) _buildLoadingCard(),
                        if (!live.liveLoading && live.liveError != null)
                          _buildErrorCard(live),
                        if (!live.liveLoading &&
                            live.liveError == null &&
                            live.liveStatus != null) ...[
                          _buildLiveTrackingCard(live),
                          const SizedBox(height: 12),
                          if (live.liveStations.isNotEmpty) ...[
                            _buildStatusSummaryCard(live),
                            const SizedBox(height: 16),
                            _buildRouteTimeline(live),
                          ],
                        ],
                        if (!live.liveLoading &&
                            live.liveError == null &&
                            live.liveStations.isEmpty)
                          _buildNoDataCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RailLiveColors.primary2, RailLiveColors.primary3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _headerIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trainNumber} · $trainName',
                      style: const TextStyle(
                          color: RailLiveColors.surface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: RailLiveColors.liveGreen,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Text('LIVE · Auto-refresh every 60s',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.wechat_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainChatScreen(
                        trainNumber: trainNumber,
                        trainName: trainName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LOADING / ERROR / NO-DATA CARDS
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLoadingCard() {
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
          Text('Fetching live train status…',
              style:
              TextStyle(color: RailLiveColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(LiveStatusProvider live) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(live.liveError!,
                style:
                const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          TextButton(
            onPressed: () =>
                context.read<LiveStatusProvider>().fetchLiveStatus(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live schedule data is not available for this train right now.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TRAIN INFO CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTrainInfoCard(LiveStatusProvider live) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
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
                trainName,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  trainNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                // Timeline column
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stationDot(filled: true),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _stationDot(filled: false),
                  ],
                ),
                const SizedBox(width: 12),
                // Station names + times
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(origin,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: RailLiveColors.textPrimary)),
                          Text(
                            'DEP · ${live.departureTime}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destination,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: RailLiveColors.textPrimary)),
                          Text(
                            'ARR · ${live.arrivalTime}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status + duration
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      live.status,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D9E75)),
                    ),
                    Text(
                      live.duration,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trainType.isNotEmpty || runningDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.red),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (trainType.isNotEmpty)
                  _infoBadge(Icons.train_outlined, trainType),
                if (runningDays.isNotEmpty)
                  _infoBadge(Icons.calendar_today_outlined, runningDays),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationDot({required bool filled}) {
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

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RailLiveColors.primary2.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: RailLiveColors.primary2),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RailLiveColors.primary2)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIVE TRACKING CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLiveTrackingCard(LiveStatusProvider live) {
    final body = live.liveStatus?['body'] as Map<String, dynamic>?;
    if (body == null) return const SizedBox();

    final currentCode = live.liveCurrentStation;
    final message = live.liveTrainStatusMessage;
    final timeAvail = live.liveTimeOfAvailability;
    final terminated = live.liveTerminated;

    Map<String, dynamic>? currentStn;
    for (final s in live.liveStations) {
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                              ? Colors.orange
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
          // Current position
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
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
                            color:
                            Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.15)),
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
          // Stats row
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
                  value: '${live.livePassedCount}',
                  color: RailLiveColors.liveGreen,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.schedule,
                  label: 'Delay',
                  value: live.liveIsOnTime
                      ? 'On Time'
                      : '${live.liveCurrentDelayText} min',
                  color: live.liveIsOnTime
                      ? RailLiveColors.liveGreen
                      : RailLiveColors.warning,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.arrow_forward,
                  label: 'Next',
                  value: live.liveNextStationName,
                  color: Colors.white,
                  maxLines: 1,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: live.liveEtaForNext,
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
  //  STATUS SUMMARY CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildStatusSummaryCard(LiveStatusProvider live) {
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
              // Delay block
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
                      live.liveIsOnTime
                          ? 'On Time'
                          : '${live.liveCurrentDelayText} min',
                      style: TextStyle(
                          color: live.liveIsOnTime
                              ? RailLiveColors.liveGreen
                              : RailLiveColors.warning,
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
                            live.liveIsOnTime
                                ? Icons.check_circle_outline
                                : Icons.access_time,
                            color: live.liveIsOnTime
                                ? RailLiveColors.liveGreen
                                : RailLiveColors.warning,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            live.liveIsOnTime ? 'ON TIME' : 'DELAYED',
                            style: TextStyle(
                                color: live.liveIsOnTime
                                    ? RailLiveColors.liveGreen
                                    : RailLiveColors.warning,
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
              // Next station + ETA
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
                      live.liveNextStationName,
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
                          live.liveEtaForNext,
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
                '${live.livePassedCount} / ${live.liveStations.length} stations',
                style:
                const TextStyle(color: Colors.white54, fontSize: 11),
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
              value: live.liveStations.isEmpty
                  ? 0
                  : live.livePassedCount / live.liveStations.length,
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
  //  ROUTE TIMELINE
  // ══════════════════════════════════════════════════════════════════

  Widget _buildRouteTimeline(LiveStatusProvider live) {
    final stations = live.liveStations;
    if (stations.isEmpty) return const SizedBox();

    final currentIdx = live.currentStationIndex;
    final lastDepIdx = live.lastDepartedIndex;
    final trainProgress = live.trainProgressBetweenStations;

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
          // Header
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
                    color:
                    RailLiveColors.primary2.withValues(alpha: 0.08),
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
                // Clock badge — reads from ClockProvider
                Consumer<ClockProvider>(
                  builder: (context, clock, _) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RailLiveColors.primary2
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Now ${clock.now.hour.toString().padLeft(2, '0')}:${clock.now.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: RailLiveColors.primary2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Column labels
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
          const Divider(height: 1, thickness: 0.5),
          // Station list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 0.4, indent: 76, endIndent: 76),
            itemBuilder: (context, index) {
              final station =
              stations[index] as Map<String, dynamic>;
              final isLast = index == stations.length - 1;
              final isCurrentStation = index == currentIdx;
              final nextIdx = live.isTrainAtStation
                  ? currentIdx + 1
                  : lastDepIdx + 1;
              final isNextStation =
                  !isCurrentStation && index == nextIdx;
              final isPassed = live.stationHasDeparted(station);
              final showTrainOnConnector =
                  !live.isTrainAtStation &&
                      index == lastDepIdx &&
                      !isLast;

              return _buildStationRow(
                live: live,
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
    required LiveStatusProvider live,
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
    final expectedPlatform =
        station['expected_platform']?.toString() ?? '';

    final hasActualArr =
        actualArr != null && actualArr.isNotEmpty && actualArr != '--';
    final hasActualDep =
        actualDep != null && actualDep.isNotEmpty && actualDep != '--';

    final arrDelay = live.delayMinutes(
        scheduledArr, hasActualArr ? actualArr : null);
    final depDelay = live.delayMinutes(
        scheduledDep, hasActualDep ? actualDep : null);

    final haltTime = live.getHaltTime(station);
    final connectorHeight = showTrainOnConnector ? 80.0 : 56.0;

    Color rowBg = Colors.transparent;
    if (isCurrentStation) {
      rowBg = RailLiveColors.primary2.withValues(alpha: 0.05);
    }

    return ColoredBox(
      color: rowBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Arrival
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, left: 6, right: 4, bottom: 8),
              child: isSource
                  ? const SizedBox()
                  : _buildTimeColumn(
                live: live,
                scheduled: scheduledArr,
                actual: hasActualArr ? actualArr : null,
                delay: arrDelay,
                isPassed: isPassed || isCurrentStation,
                haltTime: null,
              ),
            ),
          ),

          // CENTER: Timeline spine + station info
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spine
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

                // Station details
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
                              _smallBadge(
                                  'CURRENT', RailLiveColors.primary2),
                            if (isNextStation)
                              _smallBadge(
                                  'NEXT', RailLiveColors.primary2),
                            if (isSource)
                              _smallBadge('ORIGIN', Colors.green),
                            if (isDestination)
                              _smallBadge(
                                  'DEST', Colors.red.shade400),
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
                                  const Icon(
                                      Icons.directions_transit,
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
                        if (!isLast)
                          SizedBox(height: connectorHeight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: Departure
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, right: 6, left: 4, bottom: 8),
              child: isDestination
                  ? const SizedBox()
                  : _buildTimeColumn(
                live: live,
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
    required LiveStatusProvider live,
    required String? scheduled,
    required String? actual,
    required int? delay,
    required bool isPassed,
    String? haltTime,
  }) {
    final hasActual =
        actual != null && actual.isNotEmpty && actual != '--';
    final primaryTime =
    hasActual ? live.fmtTime(actual) : live.fmtTime(scheduled);
    final primaryColor = hasActual
        ? (delay != null && delay > 0
        ? RailLiveColors.warning
        : RailLiveColors.liveGreen)
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
              ? 'SCH ${live.fmtTime(scheduled)}'
              : 'TT ${live.fmtTime(scheduled)}',
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
            padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 8, color: Colors.blue),
                const SizedBox(width: 2),
                Text(
                  '${haltTime}m halt',
                  style: const TextStyle(
                      color: Colors.blue,
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
            padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.warning.withValues(alpha: 0.12),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.liveGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('On Time',
                style: TextStyle(
                    color: RailLiveColors.liveGreen,
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
        scale: _pulseAnimation,
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
          child:
          const Icon(Icons.train, color: Colors.white, size: 15),
        ),
      );
    }
    if (isSource) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.circle, color: Colors.white, size: 10),
      );
    }
    if (isDestination) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: isPassed
                ? RailLiveColors.primary2
                : RailLiveColors.border,
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
              height:
              (totalH - (topOffset + iconSize / 2)).clamp(0.0, totalH),
              color: RailLiveColors.border,
            ),
          ),
          Positioned(
            top: topOffset,
            left: 2,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: RailLiveColors.primary2,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                      RailLiveColors.primary2.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.train,
                    color: Colors.white, size: 14),
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
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 9, color: Colors.blue),
          const SizedBox(width: 3),
          Text(
            '${minutes}m halt',
            style: const TextStyle(
                color: Colors.blue,
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



*/
























/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/providers/train_provider.dart';
import 'package:rail_live/screens/train_chat_screen.dart';

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
  Timer? _refreshTimer;
  Timer? _clockTimer;
  late Map<String, dynamic> _currentData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  TimeOfDay _now = TimeOfDay.now();
  Map<String, dynamic>? liveStatus;
  bool liveLoading = false;
  String? liveError;

  @override
  void initState() {
    super.initState();
    _currentData = widget.trainData;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = TimeOfDay.now());
    });

    _pulseController.repeat(reverse: true);
    _fetchLiveStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  Future<void> _fetchLiveStatus() async {
    if (!mounted) return;
    setState(() {
      liveLoading = true;
      liveError = null;
    });

    try {
      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final uri = Uri.https(
        'indian-railway-irctc.p.rapidapi.com',
        '/api/trains/v1/train/status',
        {
          'departure_date': today,
          'isH5': 'true',
          'client': 'web',
          'train_number': widget.trainNumber,
        },
      );

      debugPrint("TRAIN NUMBER = ${widget.trainNumber}");

      final response = await http.get(uri, headers: {
        'x-rapidapi-host': 'indian-railway-irctc.p.rapidapi.com',
        'x-rapidapi-key': 'f6e08704ecmsha3ab93df2f22de0p1cf569jsnf7a107f723ae',
      });

      debugPrint("STATUS CODE: ${response.statusCode}");
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          jsonData['status']?['result'] == 'success') {
        // Debug: print first intermediate station fields
        final stations = jsonData['body']?['stations'] as List?;
        if (stations != null && stations.length > 1) {
          debugPrint("STATION FIELDS: ${stations[1]}");
        }
        if (mounted) setState(() => liveStatus = jsonData);
      } else {
        if (mounted) {
          setState(() {
            liveError = jsonData['status']?['message']?['message'] ??
                'Unable to fetch live status';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => liveError = e.toString());
    }

    if (mounted) setState(() => liveLoading = false);
  }

  Future<void> _refresh() async {
    await _fetchLiveStatus();
    if (!mounted) return;
    final provider = context.read<TrainProvider>();
    await provider.fetchTrain(widget.trainNumber);
    if (provider.trainData != null && mounted) {
      setState(() {
        _currentData = provider.trainData!;
        _now = TimeOfDay.now();
      });
    }
  }

  // ── Data helpers ─────────────────────────────────────────────────

  String get trainName =>
      _currentData['trainName']?.toString() ??
      _currentData['train_name']?.toString() ??
      'Unknown Train';

  String get trainNumber =>
      _currentData['trainNumber']?.toString() ??
      _currentData['train_number']?.toString() ??
      widget.trainNumber;

  String get origin => _currentData['origin']?.toString() ?? '';
  String get destination => _currentData['destination']?.toString() ?? '';

  String get trainType =>
      _currentData['trainType']?.toString() ??
      _currentData['train_type']?.toString() ??
      '';

  String get runningDays {
    final days = _currentData['runningDays'];
    if (days == null) return '';
    if (days is List) return days.join(', ');
    return days.toString();
  }

  // ── Live status helpers ──────────────────────────────────────────

  List<dynamic> get liveStations {
    try {
      return (liveStatus?['body']?['stations'] as List?) ?? [];
    } catch (_) {
      return [];
    }
  }

  String get liveTrainStatusMessage {
    final raw = liveStatus?['body']?['train_status_message']?.toString() ?? '';
    return raw.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get liveCurrentStation =>
      liveStatus?['body']?['current_station']?.toString() ?? '';

  bool get liveTerminated => liveStatus?['body']?['terminated'] == true;

  String get liveTimeOfAvailability =>
      liveStatus?['body']?['time_of_availability']?.toString() ?? '';

  // ── Time helpers ─────────────────────────────────────────────────

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '--') return null;
    final s = raw.trim();
    try {
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) {
        final parts = s.split(':');
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateFormat('hh:mm a').parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtTime(String? raw) {
    final dt = _parseTime(raw);
    if (dt == null) return '--';
    return DateFormat('hh:mm a').format(dt);
  }

  // ── Station state helpers ────────────────────────────────────────

  bool _stationHasDeparted(Map<String, dynamic> s) {
    final d = s['actual_departure_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }

  bool _stationHasArrived(Map<String, dynamic> s) {
    final d = s['actual_arrival_time']?.toString() ?? '';
    return d.isNotEmpty && d != '--';
  }
// ── Train Info Card helpers ──────────────────────────────────────

  String get departureTime {
    if (liveStations.isNotEmpty) {
      final src = liveStations.first as Map<String, dynamic>;
      final actual = src['actual_departure_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return _fmtTime(actual);
      return _fmtTime(src['departureTime']?.toString());
    }
    return _currentData['departureTime']?.toString() ??
        _currentData['departure_time']?.toString() ?? '--';
  }

  String get arrivalTime {
    if (liveStations.isNotEmpty) {
      final dst = liveStations.last as Map<String, dynamic>;
      final actual = dst['actual_arrival_time']?.toString() ?? '';
      if (actual.isNotEmpty && actual != '--') return _fmtTime(actual);
      return _fmtTime(dst['arrivalTime']?.toString());
    }
    return _currentData['arrivalTime']?.toString() ??
        _currentData['arrival_time']?.toString() ?? '--';
  }

  String get status {
    if (liveTerminated) return 'Terminated';
    if (_liveIsOnTime) return 'On Time';
    return '$_liveCurrentDelayText min late';
  }

  String get duration {
    if (liveStations.length >= 2) {
      final depRaw = (liveStations.first as Map<String, dynamic>)['departureTime']?.toString();
      final arrRaw = (liveStations.last as Map<String, dynamic>)['arrivalTime']?.toString();
      final dep = _parseTime(depRaw);
      final arr = _parseTime(arrRaw);
      if (dep != null && arr != null) {
        int mins = arr.difference(dep).inMinutes;
        if (mins < 0) mins += 24 * 60; // overnight trains
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0 ? '${h}h' : '${h}h ${m}m';
      }
    }
    return _currentData['duration']?.toString() ?? '--';
  }
  int get _currentStationIndex {
    for (int i = 0; i < liveStations.length; i++) {
      final s = liveStations[i] as Map<String, dynamic>;
      if (_stationHasArrived(s) && !_stationHasDeparted(s)) return i;
    }
    return -1;
  }

  int get _lastDepartedIndex {
    int last = -1;
    for (int i = 0; i < liveStations.length; i++) {
      if (_stationHasDeparted(liveStations[i] as Map<String, dynamic>)) {
        last = i;
      }
    }
    return last;
  }

  bool get isTrainAtStation => _currentStationIndex >= 0;

  int get _activeIndex =>
      isTrainAtStation ? _currentStationIndex : _lastDepartedIndex;

  double get _trainProgressBetweenStations {
    final depIdx = _lastDepartedIndex;
    if (depIdx < 0 || depIdx >= liveStations.length - 1) return 0.0;
    final nextIdx = depIdx + 1;

    final depStation = liveStations[depIdx] as Map<String, dynamic>;
    final nextStation = liveStations[nextIdx] as Map<String, dynamic>;

    final depTime = _parseTime(
        depStation['actual_departure_time']?.toString() ??
            depStation['departureTime']?.toString());
    final arrTime = _parseTime(nextStation['arrivalTime']?.toString());

    if (depTime == null || arrTime == null) return 0.5;
    final now = DateTime.now();
    final total = arrTime.difference(depTime).inSeconds;
    final elapsed = now.difference(depTime).inSeconds;
    if (total <= 0) return 0.5;
    return (elapsed / total).clamp(0.05, 0.95);
  }

  int? _delayMinutes(String? scheduled, String? actual) {
    final sch = _parseTime(scheduled);
    final act = _parseTime(actual);
    if (sch == null || act == null) return null;
    final diff = act.difference(sch).inMinutes;
    return diff <= 0 ? null : diff;
  }

  // ── Halt time helper ─────────────────────────────────────────────

  /// Returns halt duration in minutes for a station.
  /// Tries multiple possible field names from the API.
  String? _getHaltTime(Map<String, dynamic> station) {
    // Try all common field names the API might return
    final candidates = [
      station['haltTime'],
      station['halt_time'],
      station['halt'],
      station['haltDuration'],
      station['halt_duration'],
      station['stopTime'],
      station['stop_time'],
    ];

    for (final val in candidates) {
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str != '0' && str != '--' && str != 'null') {
          return str;
        }
      }
    }

    // Calculate halt from scheduled arrival and departure if available
    final arr = _parseTime(station['arrivalTime']?.toString());
    final dep = _parseTime(station['departureTime']?.toString());
    if (arr != null && dep != null) {
      final diff = dep.difference(arr).inMinutes;
      if (diff > 0) return diff.toString();
    }

    return null;
  }

  // ── Summary getters ──────────────────────────────────────────────

  String get _liveCurrentDelayText {
    final idx = _activeIndex;
    if (idx < 0) return '0';
    final s = liveStations[idx] as Map<String, dynamic>;
    final dep = _delayMinutes(
        s['departureTime']?.toString(), s['actual_departure_time']?.toString());
    if (dep != null && dep > 0) return dep.toString();
    final arr = _delayMinutes(
        s['arrivalTime']?.toString(), s['actual_arrival_time']?.toString());
    if (arr != null && arr > 0) return arr.toString();
    return '0';
  }

  bool get _liveIsOnTime {
    final d = _liveCurrentDelayText.trim();
    return d == '0' || d.isEmpty;
  }

  String get _liveNextStationName {
    final nextIdx =
        isTrainAtStation ? _currentStationIndex + 1 : _lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      return (liveStations[nextIdx] as Map<String, dynamic>)['stationName']
              ?.toString() ??
          '—';
    }
    return '—';
  }

  String get _liveEtaForNext {
    final nextIdx =
        isTrainAtStation ? _currentStationIndex + 1 : _lastDepartedIndex + 1;
    if (nextIdx >= 0 && nextIdx < liveStations.length) {
      final s = liveStations[nextIdx] as Map<String, dynamic>;
      return _fmtTime(s['arrivalTime']?.toString());
    }
    return '—';
  }

  int get _livePassedCount {
    int count = 0;
    for (final s in liveStations) {
      if (_stationHasDeparted(s as Map<String, dynamic>)) count++;
    }
    return count;
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrainInfoCard(),
                    const SizedBox(height: 12),
                    if (liveLoading) _buildLoadingCard(),
                    if (!liveLoading && liveError != null) _buildErrorCard(),
                    if (!liveLoading && liveError == null && liveStatus != null)
                      ...[
                        _buildLiveTrackingCard(),
                        const SizedBox(height: 12),
                        if (liveStations.isNotEmpty) ...[
                          _buildStatusSummaryCard(),
                          const SizedBox(height: 16),
                          _buildRouteTimeline(),
                        ],
                      ],
                    if (!liveLoading &&
                        liveError == null &&
                        liveStations.isEmpty)
                      _buildNoDataCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RailLiveColors.primary2, RailLiveColors.primary3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _headerIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trainNumber} · $trainName',
                      style: const TextStyle(
                          color: RailLiveColors.surface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: RailLiveColors.liveGreen,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Text('LIVE · Auto-refresh every 60s',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.wechat_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainChatScreen(
                        trainNumber: trainNumber,
                        trainName: trainName,
                      ),
                    ),
                  );
                },
              ),
                 // icon: Icons.refresh_rounded, onTap: _refresh),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LOADING CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLoadingCard() {
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
          Text('Fetching live train status…',
              style: TextStyle(color: RailLiveColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  ERROR CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(liveError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          TextButton(
            onPressed: _fetchLiveStatus,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  NO DATA CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live schedule data is not available for this train right now.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TRAIN INFO CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTrainInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
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
          // Train name + number header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trainName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: RailLiveColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  trainNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Route section
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline column
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stationDot(filled: true),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _stationDot(filled: false),
                  ],
                ),
                const SizedBox(width: 12),

                // Station names + times
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: RailLiveColors.textPrimary,
                            ),
                          ),
                          Text(
                            'DEP · $departureTime',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: RailLiveColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ARR · $arrivalTime',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status + duration column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status, // e.g. 'On Time'
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D9E75),
                      ),
                    ),
                    Text(
                      duration, // e.g. '15h 40m'
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (trainType.isNotEmpty || runningDays.isNotEmpty) ...[
            const SizedBox(height: 14),
         //   Divider(height: 1, color: Colors.grey.shade100),
            Divider(height: 1, color: Colors.red),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (trainType.isNotEmpty)
                  _infoBadge(Icons.train_outlined, trainType),
                if (runningDays.isNotEmpty)
                  _infoBadge(Icons.calendar_today_outlined, runningDays),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationDot({required bool filled}) {
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

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RailLiveColors.primary2.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: RailLiveColors.primary2),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RailLiveColors.primary2)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIVE TRACKING CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLiveTrackingCard() {
    final body = liveStatus?['body'] as Map<String, dynamic>?;
    if (body == null) return const SizedBox();

    final currentCode = liveCurrentStation;
    final message = liveTrainStatusMessage;
    final timeAvail = liveTimeOfAvailability;
    final terminated = liveTerminated;

    Map<String, dynamic>? currentStn;
    for (final s in liveStations) {
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: terminated
                              ? Colors.orange
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

          // Current position
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child:
                        const Icon(Icons.train, color: Colors.white, size: 26),
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
                                color: Colors.white.withValues(alpha: 0.2)),
                            if (currentStn?['distance'] != null) ...[
                              const SizedBox(width: 6),
                              _livePill(
                                  '${currentStn!['distance']} km from origin',
                                  color:
                                      Colors.white.withValues(alpha: 0.2)),
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
                                color: Colors.white.withValues(alpha: 0.15)),
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

          // Stats row
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
                  value: '$_livePassedCount',
                  color: RailLiveColors.liveGreen,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.schedule,
                  label: 'Delay',
                  value: _liveIsOnTime
                      ? 'On Time'
                      : '$_liveCurrentDelayText min',
                  color: _liveIsOnTime
                      ? RailLiveColors.liveGreen
                      : RailLiveColors.warning,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.arrow_forward,
                  label: 'Next',
                  value: _liveNextStationName,
                  color: Colors.white,
                  maxLines: 1,
                ),
                _trackingStatDivider(),
                _trackingStat(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: _liveEtaForNext,
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
                color: color, fontSize: 12, fontWeight: FontWeight.w700),
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
  //  STATUS SUMMARY CARD
  // ══════════════════════════════════════════════════════════════════

  Widget _buildStatusSummaryCard() {
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
              // Delay block
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
                      _liveIsOnTime
                          ? 'On Time'
                          : '$_liveCurrentDelayText min',
                      style: TextStyle(
                          color: _liveIsOnTime
                              ? RailLiveColors.liveGreen
                              : RailLiveColors.warning,
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
                            _liveIsOnTime
                                ? Icons.check_circle_outline
                                : Icons.access_time,
                            color: _liveIsOnTime
                                ? RailLiveColors.liveGreen
                                : RailLiveColors.warning,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _liveIsOnTime ? 'ON TIME' : 'DELAYED',
                            style: TextStyle(
                                color: _liveIsOnTime
                                    ? RailLiveColors.liveGreen
                                    : RailLiveColors.warning,
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
              // Next station + ETA
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
                      _liveNextStationName,
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
                          _liveEtaForNext,
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
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '$_livePassedCount / ${liveStations.length} stations',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Text('End',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: liveStations.isEmpty
                  ? 0
                  : _livePassedCount / liveStations.length,
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
  //  ROUTE TIMELINE
  // ══════════════════════════════════════════════════════════════════

  Widget _buildRouteTimeline() {
    final stations = liveStations;
    if (stations.isEmpty) return const SizedBox();

    final currentIdx = _currentStationIndex;
    final lastDepIdx = _lastDepartedIndex;
    final trainProgress = _trainProgressBetweenStations;

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
          // Header
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
                // Station count badge
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RailLiveColors.primary2.withValues(alpha: 0.08),
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
                    color:
                        RailLiveColors.primary2.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Now ${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: RailLiveColors.primary2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Column labels
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

          const Divider(height: 1, thickness: 0.5),

          // Station list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 0.4, indent: 76, endIndent: 76),
            itemBuilder: (context, index) {
              final station = stations[index] as Map<String, dynamic>;
              final isLast = index == stations.length - 1;
              final isCurrentStation = index == currentIdx;
              final nextIdx =
                  isTrainAtStation ? currentIdx + 1 : lastDepIdx + 1;
              final isNextStation =
                  !isCurrentStation && index == nextIdx;
              final isPassed = _stationHasDeparted(station);
              final showTrainOnConnector =
                  !isTrainAtStation && index == lastDepIdx && !isLast;

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
        _delayMinutes(scheduledArr, hasActualArr ? actualArr : null);
    final depDelay =
        _delayMinutes(scheduledDep, hasActualDep ? actualDep : null);

    // ── Halt time ────────────────────────────────────────────────
    final haltTime = _getHaltTime(station);

    final connectorHeight = showTrainOnConnector ? 80.0 : 56.0;

    Color rowBg = Colors.transparent;
    if (isCurrentStation) {
      rowBg = RailLiveColors.primary2.withValues(alpha: 0.05);
    }

    return ColoredBox(
      color: rowBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Arrival
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
                      haltTime: null, // halt shown on departure side only
                    ),
            ),
          ),

          // CENTER: Timeline spine + station info
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spine
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

                // Station details
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
                        // Name + badges
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
                              _smallBadge(
                                  'CURRENT', RailLiveColors.primary2),
                            if (isNextStation)
                              _smallBadge('NEXT', RailLiveColors.primary2),
                            if (isSource)
                              _smallBadge('ORIGIN', Colors.green),
                            if (isDestination)
                              _smallBadge('DEST', Colors.red.shade400),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Code · distance · platform · halt
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
                            // ── Halt time badge ──────────────────
                            if (haltTime != null &&
                                !isSource &&
                                !isDestination)
                              _haltBadge(haltTime),
                          ],
                        ),

                        // "Train is here" indicator
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

          // RIGHT: Departure
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
                      haltTime: haltTime, // ✅ halt shown on departure side
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TIME COLUMN — updated with haltTime support
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTimeColumn({
    required String? scheduled,
    required String? actual,
    required int? delay,
    required bool isPassed,
    String? haltTime, // ✅ NEW optional param
  }) {
    final hasActual = actual != null && actual.isNotEmpty && actual != '--';
    final primaryTime = hasActual ? _fmtTime(actual) : _fmtTime(scheduled);
    final primaryColor = hasActual
        ? (delay != null && delay > 0
            ? RailLiveColors.warning
            : RailLiveColors.liveGreen)
        : RailLiveColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primary time (actual if available, else timetable)
        Text(
          primaryTime,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor),
          textAlign: TextAlign.center,
        ),

        // Scheduled time below
        const SizedBox(height: 2),
        Text(
          hasActual
              ? 'SCH ${_fmtTime(scheduled)}'
              : 'TT ${_fmtTime(scheduled)}',
          style: TextStyle(
              color: hasActual
                  ? RailLiveColors.textHint
                  : RailLiveColors.textHint.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),

        // ── Halt time badge ──────────────────────────────────────
        if (haltTime != null && haltTime.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 8, color: Colors.blue),
                const SizedBox(width: 2),
                Text(
                  '${haltTime}m halt',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],

        // Delay badge
        if (delay != null && delay > 0) ...[
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('+$delay m',
                style: const TextStyle(
                    color: RailLiveColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],

        // On-time badge
        if (isPassed && (delay == null || delay <= 0) && hasActual) ...[
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: RailLiveColors.liveGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('On Time',
                style: TextStyle(
                    color: RailLiveColors.liveGreen,
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
        scale: _pulseAnimation,
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
          child:
              const Icon(Icons.train, color: Colors.white, size: 15),
        ),
      );
    }

    if (isSource) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.circle, color: Colors.white, size: 10),
      );
    }

    if (isDestination) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: isPassed
                ? RailLiveColors.primary2
                : RailLiveColors.border,
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
              height:
                  (totalH - (topOffset + iconSize / 2)).clamp(0.0, totalH),
              color: RailLiveColors.border,
            ),
          ),
          Positioned(
            top: topOffset,
            left: 2,
            child: ScaleTransition(
              scale: _pulseAnimation,
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
                child: const Icon(Icons.train,
                    color: Colors.white, size: 14),
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

  // ── NEW: Halt badge shown inline in station meta row ─────────────
  Widget _haltBadge(String minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 9, color: Colors.blue),
          const SizedBox(width: 3),
          Text(
            '${minutes}m halt',
            style: const TextStyle(
                color: Colors.blue,
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
*/