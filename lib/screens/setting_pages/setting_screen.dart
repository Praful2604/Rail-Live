import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../app_constant.dart'; // adjust path if needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Notification toggles ──────────────────────────────────────────────────
  bool _trainAlerts     = true;
  bool _pnrUpdates      = true;
  bool _delayAlerts     = true;
  bool _platformChanges = false;

  // ── App info ──────────────────────────────────────────────────────────────
  String _appVersion  = '';
  String _buildNumber = '';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kTrainAlerts     = 'notif_train_alerts';
  static const _kPnrUpdates      = 'notif_pnr_updates';
  static const _kDelayAlerts     = 'notif_delay_alerts';
  static const _kPlatformChanges = 'notif_platform_changes';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadAppInfo();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _trainAlerts     = prefs.getBool(_kTrainAlerts)     ?? true;
      _pnrUpdates      = prefs.getBool(_kPnrUpdates)      ?? true;
      _delayAlerts     = prefs.getBool(_kDelayAlerts)      ?? true;
      _platformChanges = prefs.getBool(_kPlatformChanges) ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion  = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _onToggle({
    required String key,
    required bool value,
    required String label,
  }) async {
    await _savePref(key, value);
    _showSnack(value ? '$label enabled' : '$label disabled');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open link');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: RailLiveColors.primary2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: RailLiveColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RailLiveColors.primary2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.train_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'RailLive',
              style: TextStyle(
                color: RailLiveColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RailLiveColors.primary4,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Version $_appVersion  •  Build $_buildNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RailLiveColors.primary2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Indian Railways companion — live train tracking, PNR status, station food ordering, and more.',
              style: TextStyle(
                fontSize: 13,
                color: RailLiveColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Built with Flutter & Firebase.',
              style: TextStyle(fontSize: 12, color: RailLiveColors.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: RailLiveColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary2,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── NOTIFICATIONS ─────────────────────────────────────────────────
          _sectionHeader('Notifications', Icons.notifications_outlined),
          _card(
            children: [
              _switchTile(
                icon: Icons.train_rounded,
                iconBg: RailLiveColors.qaBlue,
                iconColor: RailLiveColors.primary,
                title: 'Train Alerts',
                subtitle: 'Live status updates for tracked trains',
                value: _trainAlerts,
                onChanged: (v) {
                  setState(() => _trainAlerts = v);
                  _onToggle(key: _kTrainAlerts, value: v, label: 'Train Alerts');
                },
              ),
              _divider(),
              _switchTile(
                icon: Icons.confirmation_number_outlined,
                iconBg: RailLiveColors.qaGreen,
                iconColor: RailLiveColors.success,
                title: 'PNR Updates',
                subtitle: 'Booking status and chart preparation alerts',
                value: _pnrUpdates,
                onChanged: (v) {
                  setState(() => _pnrUpdates = v);
                  _onToggle(key: _kPnrUpdates, value: v, label: 'PNR Updates');
                },
              ),
              _divider(),
              _switchTile(
                icon: Icons.timer_outlined,
                iconBg: RailLiveColors.accent3,
                iconColor: RailLiveColors.warning,
                title: 'Delay Alerts',
                subtitle: 'Notify when your train is running late',
                value: _delayAlerts,
                onChanged: (v) {
                  setState(() => _delayAlerts = v);
                  _onToggle(key: _kDelayAlerts, value: v, label: 'Delay Alerts');
                },
              ),
              _divider(),
              _switchTile(
                icon: Icons.swap_horiz_rounded,
                iconBg: RailLiveColors.qaPurple,
                iconColor: RailLiveColors.languageIcon,
                title: 'Platform Changes',
                subtitle: 'Alert when train platform is updated',
                value: _platformChanges,
                onChanged: (v) {
                  setState(() => _platformChanges = v);
                  _onToggle(
                    key: _kPlatformChanges,
                    value: v,
                    label: 'Platform Changes',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── APP INFO ──────────────────────────────────────────────────────
          _sectionHeader('App Info', Icons.info_outline),
          _card(
            children: [
              _tappableTile(
                icon: Icons.info_outline,
                iconBg: RailLiveColors.qaBlue,
                iconColor: RailLiveColors.primary,
                title: 'About RailLive',
                subtitle: 'Version $_appVersion',
                onTap: _showAboutDialog,
              ),
              _divider(),
              _tappableTile(
                icon: Icons.star_outline_rounded,
                iconBg: RailLiveColors.qaAmber,
                iconColor: RailLiveColors.accent,
                title: 'Rate Us',
                subtitle: 'Enjoying the app? Leave a review',
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.yourapp.raillive',
                ),
              ),
              _divider(),
              _tappableTile(
                icon: Icons.bug_report_outlined,
                iconBg: RailLiveColors.alertErrorBg,
                iconColor: RailLiveColors.error,
                title: 'Report a Bug',
                subtitle: 'Help us improve RailLive',
                onTap: () => _launchUrl(
                  'mailto:support@raillive.app?subject=Bug%20Report%20-%20RailLive',
                ),
              ),
              _divider(),
              _tappableTile(
                icon: Icons.privacy_tip_outlined,
                iconBg: RailLiveColors.alertSuccessBg,
                iconColor: RailLiveColors.success,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _launchUrl('https://raillive.app/privacy'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Footer ────────────────────────────────────────────────────────
          Center(
            child: Text(
              'RailLive v$_appVersion • Build $_buildNumber',
              style: TextStyle(fontSize: 12, color: RailLiveColors.textHint),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: RailLiveColors.primary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: RailLiveColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RailLiveColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: RailLiveColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: RailLiveColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: RailLiveColors.primary,
            activeTrackColor: RailLiveColors.primary4,
          ),
        ],
      ),
    );
  }

  Widget _tappableTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: RailLiveColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: RailLiveColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: RailLiveColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 58,
    endIndent: 16,
    color: RailLiveColors.border,
  );
}