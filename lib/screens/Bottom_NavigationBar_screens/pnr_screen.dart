import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Providers/pnr_provider.dart';
import '../../app_constant.dart';

class PnrScreen extends StatefulWidget {
  const PnrScreen({super.key});

  @override
  State<PnrScreen> createState() => _PnrScreenState();
}

class _PnrScreenState extends State<PnrScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _pnrError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s.startsWith('CNF')) return RailLiveColors.success;
    if (s.startsWith('RAC')) return RailLiveColors.accent2;
    if (s.contains('WL')) return RailLiveColors.warning;
    if (s.startsWith('CAN')) return RailLiveColors.error;
    return RailLiveColors.textHint;
  }

  Color _statusBgColor(String status) {
    final s = status.toUpperCase();
    if (s.startsWith('CNF')) return RailLiveColors.alertSuccessBg;
    if (s.startsWith('RAC')) return RailLiveColors.accent2;
    if (s.contains('WL')) return RailLiveColors.alertWarnBg;
    if (s.startsWith('CAN')) return RailLiveColors.alertErrorBg;
    return RailLiveColors.surface2;
  }

  /// Parses booking-status strings like "CNF/B2/54/UB/PT" into parts:
  /// status, coach, berth number, berth type, quota.
  Map<String, String> _parseBookingStatus(String bookingStatus) {
    if (bookingStatus.trim().isEmpty) {
      return {
        'status': '',
        'coach': '',
        'berth': '',
        'berthType': '',
        'quota': '',
      };
    }
    final parts = bookingStatus.split('/');
    return {
      'status': parts.isNotEmpty ? parts[0] : '',
      'coach': parts.length > 1 ? parts[1] : '',
      'berth': parts.length > 2 ? parts[2] : '',
      'berthType': parts.length > 3 ? parts[3] : '',
      'quota': parts.length > 4 ? parts[4] : '',
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PnrProvider>(context);
    final Map<String, dynamic>? pnrData = provider.data;

    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.train, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PNR Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Track your booking instantly',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(provider),
          const SizedBox(height: 16),

          // ── Error ──────────────────────────────────────────────────────────
          if (provider.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RailLiveColors.alertErrorBg,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: RailLiveColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: RailLiveColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style:
                      TextStyle(color: RailLiveColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── PNR Result ─────────────────────────────────────────────────────
          if (pnrData != null) ...[
            _buildPnrResultCard(pnrData),
            const SizedBox(height: 16),
            _buildPassengerCard(pnrData),
            const SizedBox(height: 16),
            _buildFareDetailsCard(pnrData),
            const SizedBox(height: 16),
            _buildAiAssistantBanner(),
            const SizedBox(height: 16),
          ],

          // ── Recent Searches ────────────────────────────────────────────────
          if (provider.searchHistory.isNotEmpty)
            _buildSearchHistoryCard(provider),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Input Card ─────────────────────────────────────────────────────────────

  Widget _buildInputCard(PnrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined,
                  color: RailLiveColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter 10 Digit PNR',
                      style: TextStyle(
                          color: RailLiveColors.textHint, fontSize: 11),
                    ),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (value) {
                        if (_pnrError != null) {
                          setState(() => _pnrError = null);
                        }
                      },
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: RailLiveColors.textPrimary,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '0000000000',
                        errorText: _pnrError,
                        hintStyle: TextStyle(
                          color: RailLiveColors.textHint.withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Divider(
                        height: 4,
                        thickness: 1.5,
                        color: RailLiveColors.primary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    final digits =
                    data!.text!.replaceAll(RegExp(r'\D'), '');
                    _controller.text = digits.length > 10
                        ? digits.substring(0, 10)
                        : digits;
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: RailLiveColors.primary3.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.content_paste,
                          size: 14, color: RailLiveColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Paste',
                        style: TextStyle(
                          color: RailLiveColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                FocusScope.of(context).unfocus();
                final pnr = _controller.text.trim();

                if (pnr.isEmpty) {
                  setState(() =>
                  _pnrError = 'Please enter PNR number');
                  return;
                }
                if (pnr.length != 10) {
                  setState(() =>
                  _pnrError = 'PNR must be exactly 10 digits');
                  return;
                }
                if (!RegExp(r'^\d{10}$').hasMatch(pnr)) {
                  setState(
                          () => _pnrError = 'Invalid PNR Number');
                  return;
                }

                setState(() => _pnrError = null);
                await provider.fetchPnr(pnr);

                if (provider.error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error!
                            .toLowerCase()
                            .contains('pnr')
                            ? provider.error!
                            : 'Invalid PNR Number',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RailLiveColors.primary,
                disabledBackgroundColor:
                RailLiveColors.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Check PNR Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security,
                  size: 14, color: RailLiveColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Your data is safe and secure with us',
                style: TextStyle(
                    color: RailLiveColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search History Card ────────────────────────────────────────────────────

  Widget _buildSearchHistoryCard(PnrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history,
                      color: RailLiveColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: RailLiveColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear History'),
                      content: const Text(
                          'Remove all recent PNR searches?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.clearHistory();
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                      color: RailLiveColors.error, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // History tiles
          ...provider.searchHistory.map((entry) =>
              _buildHistoryTile(entry, provider)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
      Map<String, dynamic> entry, PnrProvider provider) {
    final pnr = entry['pnr']?.toString() ?? '';
    final trainName = entry['trainName']?.toString() ?? '';
    final trainNumber = entry['trainNumber']?.toString() ?? '';
    final from = entry['from']?.toString() ?? '';
    final to = entry['to']?.toString() ?? '';
    final journeyDate = entry['journeyDate']?.toString() ?? '';
    final currentStatus = entry['currentStatus']?.toString() ?? '';
    final searchedAt = entry['searchedAt']?.toString() ?? '';

    final trainLabel = [trainNumber, trainName]
        .where((e) => e.isNotEmpty)
        .join(' - ');

    String timeAgo = '';
    try {
      final dt = DateTime.parse(searchedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Fill input field and load result
          _controller.text = pnr;
          provider.loadFromHistory(entry);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RailLiveColors.primary4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.confirmation_number_outlined,
                    color: RailLiveColors.primary2, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pnr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: RailLiveColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (currentStatus.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusBgColor(currentStatus),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentStatus,
                              style: TextStyle(
                                color: _statusColor(currentStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (trainLabel.isNotEmpty)
                      Text(
                        trainLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: RailLiveColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (from.isNotEmpty && to.isNotEmpty)
                      Text(
                        '$from → $to${journeyDate.isNotEmpty ? ' • $journeyDate' : ''}',
                        style: TextStyle(
                            fontSize: 10,
                            color: RailLiveColors.textHint),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Delete button
                  InkWell(
                    onTap: () => provider.removeHistoryEntry(pnr),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 14,
                          color: RailLiveColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                          fontSize: 10,
                          color: RailLiveColors.textHint),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PNR Result Card ────────────────────────────────────────────────────────

  Widget _buildPnrResultCard(Map<String, dynamic> data) {
    final pnrNumber = data['pnrNumber']?.toString() ?? '';

    final journeyDetails =
    Map<String, dynamic>.from(data['journeyDetails'] as Map? ?? {});
    final otherDetails =
    Map<String, dynamic>.from(data['otherDetails'] as Map? ?? {});
    final passengerDetails =
    (data['passengerDetails'] as List? ?? []).cast<dynamic>();

    final trainNumber = journeyDetails['trainNumber']?.toString() ?? '';
    final trainName = journeyDetails['trainName']?.toString() ?? '';
    final from = journeyDetails['from']?.toString() ?? '';
    final to = journeyDetails['to']?.toString() ?? '';
    final boardingDate = journeyDetails['boardingDate']?.toString() ?? '';
    final travelClass = journeyDetails['class']?.toString() ?? '';
    final boardingPoint = journeyDetails['boardingPoint']?.toString() ?? '';

    final chartingStatus =
        otherDetails['chartingStatus']?.toString() ?? 'Unknown';
    final isChartPrepared =
        chartingStatus.toLowerCase().contains('chart prepared') &&
            !chartingStatus.toLowerCase().contains('not');

    // Use the first passenger's status as a quick-glance summary.
    final firstPassenger = passengerDetails.isNotEmpty
        ? Map<String, dynamic>.from(passengerDetails.first as Map)
        : <String, dynamic>{};
    final bookingStatusRaw =
        firstPassenger['bookingStatus']?.toString() ?? '';
    final currentStatusRaw =
        firstPassenger['currentStatus']?.toString() ?? '';
    final parsedBooking = _parseBookingStatus(bookingStatusRaw);

    final bookingDisplay = bookingStatusRaw.isNotEmpty
        ? bookingStatusRaw.replaceAll('/', ' / ')
        : '—';
    final currentDisplay =
    currentStatusRaw.isNotEmpty ? currentStatusRaw : '—';

    return Container(
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isChartPrepared
                  ? RailLiveColors.alertSuccessBg
                  : RailLiveColors.alertWarnBg,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_outlined,
                    color: isChartPrepared
                        ? RailLiveColors.success
                        : RailLiveColors.warning,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'PNR: $pnrNumber',
                  style: TextStyle(
                    color: isChartPrepared
                        ? RailLiveColors.success
                        : RailLiveColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isChartPrepared
                        ? RailLiveColors.success
                        : RailLiveColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChartPrepared
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chartingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RailLiveColors.surface2,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.train,
                                color: RailLiveColors.textSecondary,
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [trainNumber, trainName]
                                      .where((e) => e.isNotEmpty)
                                      .join(' - '),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: RailLiveColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(from,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: RailLiveColors
                                                .textSecondary)),
                                    Text(' → ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: RailLiveColors
                                                .textSecondary)),
                                    Text(to,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: RailLiveColors
                                                .textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RailLiveColors.surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today,
                              color: RailLiveColors.textSecondary,
                              size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boardingDate,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: RailLiveColors.textPrimary,
                              ),
                            ),
                            Text(
                              [
                                if (travelClass.isNotEmpty) 'Class $travelClass',
                                if (boardingPoint.isNotEmpty)
                                  'From $boardingPoint',
                              ].join(' • '),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: RailLiveColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: RailLiveColors.border),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBox(
                      label: 'Booking Status',
                      value: bookingDisplay,
                      valueColor: _statusColor(parsedBooking['status'] ?? ''),
                      subtitle: passengerDetails.length > 1
                          ? 'Passenger 1 of ${passengerDetails.length}'
                          : 'Passenger 1',
                      subtitleIcon: Icons.people_outline,
                      subtitleColor: RailLiveColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBox(
                      label: 'Current Status',
                      value: currentDisplay,
                      valueColor: _statusColor(currentStatusRaw),
                      subtitle: currentStatusRaw.toUpperCase().startsWith('CNF')
                          ? 'Confirmed'
                          : currentStatusRaw.toUpperCase().startsWith('RAC')
                          ? 'RAC'
                          : currentStatusRaw.toUpperCase().contains('WL')
                          ? 'Waitlisted'
                          : '—',
                      subtitleIcon: currentStatusRaw
                          .toUpperCase()
                          .startsWith('CNF')
                          ? Icons.check_circle
                          : Icons.access_time,
                      subtitleColor: _statusColor(currentStatusRaw),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBox(
                      label: 'Chart Status',
                      value: chartingStatus,
                      valueColor: isChartPrepared
                          ? RailLiveColors.success
                          : RailLiveColors.warning,
                      subtitleIcon: Icons.assignment_turned_in_outlined,
                      subtitleColor: isChartPrepared
                          ? RailLiveColors.success
                          : RailLiveColors.warning,
                      isChart: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox({
    required String label,
    required String value,
    required Color valueColor,
    String? subtitle,
    required IconData subtitleIcon,
    required Color subtitleColor,
    bool isChart = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: RailLiveColors.textSecondary)),
          const SizedBox(height: 4),
          if (isChart) ...[
            Row(
              children: [
                Icon(subtitleIcon, size: 16, color: subtitleColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(subtitleIcon, size: 14, color: subtitleColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle ?? '',
                    style: TextStyle(fontSize: 11, color: subtitleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Passenger Card ─────────────────────────────────────────────────────────

  Widget _buildPassengerCard(Map<String, dynamic> data) {
    final passengers =
    (data['passengerDetails'] as List? ?? []).cast<dynamic>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                'Passenger Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: RailLiveColors.textPrimary,
                ),
              ),
              Text(
                '${passengers.length} Passenger${passengers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: RailLiveColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (passengers.isEmpty)
            Text(
              'No passenger details available.',
              style:
              TextStyle(fontSize: 12, color: RailLiveColors.textSecondary),
            )
          else
            ...passengers.asMap().entries.map((entry) {
              final i = entry.key;
              final p = Map<String, dynamic>.from(entry.value as Map);
              final passengerNo =
                  p['passengerNo']?.toString() ?? 'Passenger ${i + 1}';
              final bookingStatus = p['bookingStatus']?.toString() ?? '';
              final currentStatus = p['currentStatus']?.toString() ?? '';
              final coachNo = p['coachNo']?.toString() ?? '';
              return _buildPassengerTile(
                passengerNo: passengerNo,
                bookingStatus: bookingStatus,
                currentStatus: currentStatus,
                coachNo: coachNo,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPassengerTile({
    required String passengerNo,
    required String bookingStatus,
    required String currentStatus,
    required String coachNo,
  }) {
    final parsed = _parseBookingStatus(bookingStatus);
    final statusForColor =
    currentStatus.isNotEmpty ? currentStatus : parsed['status'] ?? '';
    final statusColor = _statusColor(statusForColor);
    final statusBg = _statusBgColor(statusForColor);

    // Prefer coachNo from the API; otherwise fall back to the coach parsed
    // from bookingStatus (e.g. "B2" from "CNF/B2/54/UB/PT").
    final coach = coachNo.isNotEmpty ? coachNo : (parsed['coach'] ?? '');
    final berth = parsed['berth'] ?? '';
    final berthType = parsed['berthType'] ?? '';

    String seatLabel;
    if (coach.isNotEmpty && berth.isNotEmpty) {
      seatLabel = '$coach / $berth${berthType.isNotEmpty ? ' ($berthType)' : ''}';
    } else if (berth.isNotEmpty) {
      seatLabel = berth;
    } else {
      seatLabel = 'Not Allotted';
    }

    final displayBookingStatus =
    bookingStatus.isNotEmpty ? bookingStatus.replaceAll('/', ' / ') : '—';
    final displayCurrentStatus =
    currentStatus.isNotEmpty ? currentStatus : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RailLiveColors.primary4,
              shape: BoxShape.circle,
            ),
            child:
            Icon(Icons.person, color: RailLiveColors.primary2, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passengerNo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: RailLiveColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Booking: $displayBookingStatus',
                  style: TextStyle(
                      fontSize: 11, color: RailLiveColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayCurrentStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                seatLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fare & Chart Details Card ──────────────────────────────────────────────

  Widget _buildFareDetailsCard(Map<String, dynamic> data) {
    final otherDetails =
    Map<String, dynamic>.from(data['otherDetails'] as Map? ?? {});
    final journeyDetails =
    Map<String, dynamic>.from(data['journeyDetails'] as Map? ?? {});

    final currency = otherDetails['currency']?.toString() ?? 'INR';
    final totalFare = otherDetails['totalFare']?.toString() ?? '';
    final chartingStatus =
        otherDetails['chartingStatus']?.toString() ?? '';
    final remarks = otherDetails['remarksIfAny']?.toString() ?? '';
    final trainStatus = otherDetails['trainStatus']?.toString() ?? '';
    final reservedUpto = journeyDetails['reservedUpto']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: RailLiveColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Fare & Journey Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: RailLiveColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.currency_rupee,
                  label: 'Total Fare',
                  value: totalFare.isNotEmpty
                      ? '$currency $totalFare'
                      : 'Not Available',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.flag_outlined,
                  label: 'Reserved Upto',
                  value: reservedUpto.isNotEmpty ? reservedUpto : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Charting Status',
                  value: chartingStatus.isNotEmpty ? chartingStatus : '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.train_outlined,
                  label: 'Train Status',
                  value: trainStatus.isNotEmpty ? trainStatus : 'On Time',
                ),
              ),
            ],
          ),
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RailLiveColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: RailLiveColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      remarks,
                      style: TextStyle(
                          fontSize: 11, color: RailLiveColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RailLiveColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10, color: RailLiveColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: RailLiveColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── AI Assistant Banner ────────────────────────────────────────────────────

  Widget _buildAiAssistantBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RailLiveColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Travel Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Will my ticket get confirmed?',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Providers/pnr_provider.dart';
import '../../app_constant.dart';

class PnrScreen extends StatefulWidget {
  const PnrScreen({super.key});

  @override
  State<PnrScreen> createState() => _PnrScreenState();
}

class _PnrScreenState extends State<PnrScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _pnrError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    if (status.startsWith('CNF')) return RailLiveColors.success;
    if (status.startsWith('RAC')) return RailLiveColors.accent2;
    if (status.startsWith('WL')) return RailLiveColors.warning;
    return RailLiveColors.textHint;
  }

  Color _statusBgColor(String status) {
    if (status.startsWith('CNF')) return RailLiveColors.alertSuccessBg;
    if (status.startsWith('RAC')) return RailLiveColors.accent2;
    if (status.startsWith('WL')) return RailLiveColors.alertWarnBg;
    return RailLiveColors.surface2;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PnrProvider>(context);
    final Map<String, dynamic>? pnrData = provider.data;

    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.train, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PNR Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Track your booking instantly',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(provider),
          const SizedBox(height: 16),

          // ── Error ──────────────────────────────────────────────────────────
          if (provider.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RailLiveColors.alertErrorBg,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: RailLiveColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: RailLiveColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style:
                      TextStyle(color: RailLiveColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── PNR Result ─────────────────────────────────────────────────────
          if (pnrData != null) ...[
            _buildPnrResultCard(pnrData),
            const SizedBox(height: 16),
            _buildPassengerCard(pnrData),
            const SizedBox(height: 16),
            _buildCoachPositionCard(pnrData),
            const SizedBox(height: 16),
            _buildAiAssistantBanner(),
            const SizedBox(height: 16),
          ],

          // ── Recent Searches ────────────────────────────────────────────────
          if (provider.searchHistory.isNotEmpty)
            _buildSearchHistoryCard(provider),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Input Card ─────────────────────────────────────────────────────────────

  Widget _buildInputCard(PnrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined,
                  color: RailLiveColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter 10 Digit PNR',
                      style: TextStyle(
                          color: RailLiveColors.textHint, fontSize: 11),
                    ),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (value) {
                        if (_pnrError != null) {
                          setState(() => _pnrError = null);
                        }
                      },
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: RailLiveColors.textPrimary,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '0000000000',
                        errorText: _pnrError,
                        hintStyle: TextStyle(
                          color: RailLiveColors.textHint.withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Divider(
                        height: 4,
                        thickness: 1.5,
                        color: RailLiveColors.primary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    final digits =
                    data!.text!.replaceAll(RegExp(r'\D'), '');
                    _controller.text = digits.length > 10
                        ? digits.substring(0, 10)
                        : digits;
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: RailLiveColors.primary3.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.content_paste,
                          size: 14, color: RailLiveColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Paste',
                        style: TextStyle(
                          color: RailLiveColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                FocusScope.of(context).unfocus();
                final pnr = _controller.text.trim();

                if (pnr.isEmpty) {
                  setState(() =>
                  _pnrError = 'Please enter PNR number');
                  return;
                }
                if (pnr.length != 10) {
                  setState(() =>
                  _pnrError = 'PNR must be exactly 10 digits');
                  return;
                }
                if (!RegExp(r'^\d{10}$').hasMatch(pnr)) {
                  setState(
                          () => _pnrError = 'Invalid PNR Number');
                  return;
                }

                setState(() => _pnrError = null);
                await provider.fetchPnr(pnr);

                if (provider.error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error!
                            .toLowerCase()
                            .contains('pnr')
                            ? provider.error!
                            : 'Invalid PNR Number',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RailLiveColors.primary,
                disabledBackgroundColor:
                RailLiveColors.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Check PNR Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security,
                  size: 14, color: RailLiveColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Your data is safe and secure with us',
                style: TextStyle(
                    color: RailLiveColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search History Card ────────────────────────────────────────────────────

  Widget _buildSearchHistoryCard(PnrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history,
                      color: RailLiveColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: RailLiveColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear History'),
                      content: const Text(
                          'Remove all recent PNR searches?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.clearHistory();
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                      color: RailLiveColors.error, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // History tiles
          ...provider.searchHistory.map((entry) =>
              _buildHistoryTile(entry, provider)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
      Map<String, dynamic> entry, PnrProvider provider) {
    final pnr = entry['pnr']?.toString() ?? '';
    final trainName = entry['trainName']?.toString() ?? '';
    final from = entry['from']?.toString() ?? '';
    final to = entry['to']?.toString() ?? '';
    final journeyDate = entry['journeyDate']?.toString() ?? '';
    final currentStatus = entry['currentStatus']?.toString() ?? '';
    final searchedAt = entry['searchedAt']?.toString() ?? '';

    String timeAgo = '';
    try {
      final dt = DateTime.parse(searchedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Fill input field and load result
          _controller.text = pnr;
          provider.loadFromHistory(entry);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RailLiveColors.primary4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.confirmation_number_outlined,
                    color: RailLiveColors.primary2, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pnr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: RailLiveColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (currentStatus.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusBgColor(currentStatus),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentStatus,
                              style: TextStyle(
                                color: _statusColor(currentStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (trainName.isNotEmpty)
                      Text(
                        trainName,
                        style: TextStyle(
                            fontSize: 11,
                            color: RailLiveColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (from.isNotEmpty && to.isNotEmpty)
                      Text(
                        '$from → $to${journeyDate.isNotEmpty ? ' • $journeyDate' : ''}',
                        style: TextStyle(
                            fontSize: 10,
                            color: RailLiveColors.textHint),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Delete button
                  InkWell(
                    onTap: () => provider.removeHistoryEntry(pnr),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 14,
                          color: RailLiveColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                          fontSize: 10,
                          color: RailLiveColors.textHint),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PNR Result Card ────────────────────────────────────────────────────────

  Widget _buildPnrResultCard(Map<String, dynamic> data) {
    final pnrNumber = data['pnrNumber'] ?? '1234567890';
    final trainName = data['trainName'] ?? '12124 Deccan Queen';
    final from = data['from'] ?? 'Mumbai CSMT';
    final to = data['to'] ?? 'Pune Jn';
    final journeyDate = data['journeyDate'] ?? '08 Jun 2026';
    final journeyDay = data['journeyDay'] ?? 'Mon, 10:30 AM';
    final bookingStatus = data['bookingStatus'] ?? 'WL 12';
    final currentStatus = data['currentStatus'] ?? 'CNF B2 45';
    final chartStatus = data['chartStatus'] ?? 'Chart Prepared';

    return Container(
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: RailLiveColors.alertSuccessBg,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_outlined,
                    color: RailLiveColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PNR: $pnrNumber',
                  style: TextStyle(
                    color: RailLiveColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RailLiveColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Chart Prepared',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RailLiveColors.surface2,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.train,
                                color: RailLiveColors.textSecondary,
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: RailLiveColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(from,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: RailLiveColors
                                              .textSecondary)),
                                  Text(' → ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: RailLiveColors
                                              .textSecondary)),
                                  Text(to,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: RailLiveColors
                                              .textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RailLiveColors.surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today,
                              color: RailLiveColors.textSecondary,
                              size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journeyDate,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: RailLiveColors.textPrimary,
                              ),
                            ),
                            Text(journeyDay,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: RailLiveColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: RailLiveColors.border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatusBox(
                      label: 'Booking Status',
                      value: bookingStatus,
                      valueColor: RailLiveColors.warning,
                      subtitle: 'Waitlist',
                      subtitleIcon: Icons.people_outline,
                      subtitleColor: RailLiveColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBox(
                      label: 'Current Status',
                      value: currentStatus,
                      valueColor: RailLiveColors.success,
                      subtitle: 'Confirmed',
                      subtitleIcon: Icons.check_circle,
                      subtitleColor: RailLiveColors.success,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBox(
                      label: 'Chart Status',
                      value: chartStatus,
                      valueColor: RailLiveColors.primary,
                      subtitleIcon: Icons.assignment_turned_in_outlined,
                      subtitleColor: RailLiveColors.primary,
                      isChart: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox({
    required String label,
    required String value,
    required Color valueColor,
    String? subtitle,
    required IconData subtitleIcon,
    required Color subtitleColor,
    bool isChart = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: RailLiveColors.textSecondary)),
          const SizedBox(height: 4),
          if (isChart) ...[
            Row(
              children: [
                Icon(subtitleIcon, size: 16, color: subtitleColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(subtitleIcon, size: 14, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  subtitle ?? '',
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Passenger Card ─────────────────────────────────────────────────────────

  Widget _buildPassengerCard(Map<String, dynamic> data) {
    final passengers = data['passengers'] as List? ?? [
      {
        'name': 'RAJESH KUMAR',
        'gender': 'Male',
        'age': 28,
        'status': 'CNF',
        'seat': 'B2 / 45'
      },
      {
        'name': 'SUNITA KUMARI',
        'gender': 'Female',
        'age': 25,
        'status': 'CNF',
        'seat': 'B2 / 46'
      },
      {
        'name': 'AMIT KUMAR',
        'gender': 'Male',
        'age': 30,
        'status': 'RAC',
        'seat': 'B2 / 23'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                'Passenger Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: RailLiveColors.textPrimary,
                ),
              ),
              Text(
                '${passengers.length} Passengers',
                style: TextStyle(
                  color: RailLiveColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...passengers.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value as Map;
            final status = p['status']?.toString() ?? 'WL';
            final seat = p['seat']?.toString() ?? '';
            return _buildPassengerTile(
              index: i + 1,
              name: p['name']?.toString() ?? '',
              gender: p['gender']?.toString() ?? '',
              age: p['age']?.toString() ?? '',
              status: status,
              seat: seat,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPassengerTile({
    required int index,
    required String name,
    required String gender,
    required String age,
    required String status,
    required String seat,
  }) {
    final statusColor = _statusColor(status);
    final statusBg = _statusBgColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RailLiveColors.primary4,
              shape: BoxShape.circle,
            ),
            child:
            Icon(Icons.person, color: RailLiveColors.primary2, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. $name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: RailLiveColors.textPrimary,
                  ),
                ),
                Text(
                  '$gender • $age years',
                  style: TextStyle(
                      fontSize: 11, color: RailLiveColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                seat,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Coach Position Card ────────────────────────────────────────────────────

  Widget _buildCoachPositionCard(Map<String, dynamic> data) {
    final yourCoach = data['coach'] ?? 'B2';
    final platform = data['platform'] ?? '5';
    final coaches = ['B1', 'B2', 'B3', 'A1', 'A2', 'S1', 'S2', 'S3'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.train, color: RailLiveColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Coach Position',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: RailLiveColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.train, color: RailLiveColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Platform: $platform',
                    style: TextStyle(
                      color: RailLiveColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RailLiveColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.electric_bolt,
                          color: RailLiveColors.textSecondary, size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text('Engine',
                        style: TextStyle(
                            fontSize: 9, color: RailLiveColors.textHint)),
                  ],
                ),
                const SizedBox(width: 4),
                ...coaches.map((coach) {
                  final isSelected = coach == yourCoach;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? RailLiveColors.primary
                                : RailLiveColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? RailLiveColors.primary
                                  : RailLiveColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: RailLiveColors.primary
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              coach,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : RailLiveColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 2),
                          Icon(Icons.arrow_drop_up,
                              color: RailLiveColors.primary, size: 16),
                        ] else
                          const SizedBox(height: 18),
                      ],
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RailLiveColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.stop,
                          color: RailLiveColors.textSecondary, size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text('End',
                        style: TextStyle(
                            fontSize: 9, color: RailLiveColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Your Coach: $yourCoach',
              style: TextStyle(
                color: RailLiveColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Assistant Banner ────────────────────────────────────────────────────

  Widget _buildAiAssistantBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RailLiveColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Travel Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Will my ticket get confirmed?',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

 */