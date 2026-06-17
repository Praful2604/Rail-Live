import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_constant.dart';

Color _avatarColor(String senderId) {
  final colors = [
    RailLiveColors.primary,
    RailLiveColors.success,
    RailLiveColors.accent,
    RailLiveColors.error,
    RailLiveColors.primary2,
    RailLiveColors.primary3,
    RailLiveColors.warning,
  ];
  return colors[senderId.hashCode.abs() % colors.length];
}

enum CoachType { reservation, general }

class _ReplyTo {
  final String senderId;
  final String text;
  final String messageId;

  const _ReplyTo({
    required this.senderId,
    required this.text,
    required this.messageId,
  });
}

// ─── TrainChatScreen ───────────────────────────────────────────────────────────
class TrainChatScreen extends StatefulWidget {
  final String trainNumber;
  final String trainName;

  const TrainChatScreen({
    super.key,
    required this.trainNumber,
    required this.trainName,
  });

  @override
  State<TrainChatScreen> createState() => _TrainChatScreenState();
}

class _TrainChatScreenState extends State<TrainChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final Map<String, GlobalKey> _messageKeys = {};

  late final CollectionReference _messagesRef;

  String? _passengerId;
  String? _senderKey;
  bool _sending = false;

  bool _onboardingDone = false;
  bool? _isInsideTrain;
  CoachType? _selectedCoach;

  _ReplyTo? _replyTo;

  static const List<String> _suggestions = [
    '📍 Where is the train now?',
    '🚂 Is the train on time?',
    '💺 Any seats available?',
    '🍽️ Is pantry car open?',
    '🔋 Charging points working?',
    '🚻 Is washroom clean?',
  ];

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseFirestore.instance
        .collection('train_chats')
        .doc(widget.trainNumber)
        .collection('messages');
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_key_${widget.trainNumber}';
    final existing = prefs.getString(key);

    if (existing != null) {
      _passengerId = existing;
      _senderKey = existing;
      final coach = prefs.getString('chat_coach_${widget.trainNumber}');
      if (coach != null) {
        _selectedCoach =
        coach == 'reservation' ? CoachType.reservation : CoachType.general;
      }
      if (mounted) setState(() => _onboardingDone = true);
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showOnboardingModal());
    }
  }

  void _showOnboardingModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OnboardingSheet(
        trainNumber: widget.trainNumber,
        trainName: widget.trainName,
        onCompleted: (isInside, coach) async {
          Navigator.of(context).pop();
          await _completeOnboarding(isInside, coach);
        },
      ),
    );
  }

  Future<void> _completeOnboarding(bool isInside, CoachType? coach) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_key_${widget.trainNumber}';
    final count = await _getParticipantCount();
    final identity = 'Passenger #${count + 1}';
    await prefs.setString(key, identity);

    if (coach != null) {
      await prefs.setString(
        'chat_coach_${widget.trainNumber}',
        coach == CoachType.reservation ? 'reservation' : 'general',
      );
    }

    await FirebaseFirestore.instance
        .collection('train_chats')
        .doc(widget.trainNumber)
        .collection('participants')
        .add({
      'name': identity,
      'isInsideTrain': isInside,
      'coachType': isInside
          ? (coach == CoachType.reservation ? 'reservation' : 'general')
          : null,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _passengerId = identity;
        _senderKey = identity;
        _isInsideTrain = isInside;
        _selectedCoach = coach;
        _onboardingDone = true;
      });
    }
  }

  Future<int> _getParticipantCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('train_chats')
        .doc(widget.trainNumber)
        .collection('participants')
        .get();
    return snap.docs.length;
  }

  void _setReply(_ReplyTo reply) {
    HapticFeedback.lightImpact();
    setState(() => _replyTo = reply);
    _focusNode.requestFocus();
  }

  void _clearReply() => setState(() => _replyTo = null);

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  Future<void> _sendMessage({String? preset}) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _senderKey == null || _sending) return;

    setState(() => _sending = true);
    if (preset == null) _controller.clear();

    final replySnapshot = _replyTo;
    _clearReply();

    try {
      final payload = <String, dynamic>{
        'senderId': _senderKey,
        'text': text,
        'coachType': _selectedCoach != null
            ? (_selectedCoach == CoachType.reservation
            ? 'reservation'
            : 'general')
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (replySnapshot != null) {
        payload['replyTo'] = {
          'messageId': replySnapshot.messageId,
          'senderId': replySnapshot.senderId,
          'text': replySnapshot.text,
        };
      }

      await _messagesRef.add(payload);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
        if (preset == null) _controller.text = text;
        setState(() => _replyTo = replySnapshot);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          if (_onboardingDone) _buildPassengerStats(),
          if (_onboardingDone && _passengerId != null) _buildParticipantBanner(),
          Expanded(
            child: _onboardingDone
                ? _buildMessageList()
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_onboardingDone) _buildSuggestionChips(),
          if (_onboardingDone) _buildReplyPreviewBar(),
          if (_onboardingDone) _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _headerBtn(
                  Icons.arrow_back, () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.train, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trainNumber} Group Chat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.trainName,
                      style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildOnlineCount(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
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

  Widget _buildOnlineCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('train_chats')
          .doc(widget.trainNumber)
          .collection('participants')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: RailLiveColors.liveGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Passenger stats bar ───────────────────────────────────────────────────────
  Widget _buildPassengerStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('train_chats')
          .doc(widget.trainNumber)
          .collection('participants')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int reservation = 0, general = 0, outside = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final isInside = data['isInsideTrain'] as bool? ?? false;
          if (!isInside) {
            outside++;
          } else if (data['coachType'] == 'reservation') {
            reservation++;
          } else if (data['coachType'] == 'general') {
            general++;
          }
        }
        return Container(
          color: const Color(0xFF1a237e).withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _statChip(
                icon: Icons.chair_alt_outlined,
                label: 'Reserved',
                count: reservation,
                color: const Color(0xFF3949AB),
              ),
              const SizedBox(width: 8),
              _statChip(
                icon: Icons.people_outline,
                label: 'General',
                count: general,
                color: RailLiveColors.success,
              ),
              const SizedBox(width: 8),
              _statChip(
                icon: Icons.location_off_outlined,
                label: 'Outside',
                count: outside,
                color: RailLiveColors.textHint,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$count $label',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Participant banner ────────────────────────────────────────────────────────
  Widget _buildParticipantBanner() {
    if (_passengerId == null) return const SizedBox();
    final coachLabel = _isInsideTrain == true
        ? (_selectedCoach == CoachType.reservation
        ? '· Reserved Coach'
        : '· General Coach')
        : '· Not on train';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF3949AB).withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _avatarColor(_passengerId!),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You: $_passengerId $coachLabel · Anonymous',
              style: const TextStyle(
                color: RailLiveColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.shield_outlined,
              size: 13, color: RailLiveColors.primary),
        ],
      ),
    );
  }

  // ── Suggestion chips ──────────────────────────────────────────────────────────
  Widget _buildSuggestionChips() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _sendMessage(preset: _suggestions[i]),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: RailLiveColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                _suggestions[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: RailLiveColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reply preview bar ─────────────────────────────────────────────────────────
  Widget _buildReplyPreviewBar() {
    if (_replyTo == null) return const SizedBox();
    final isMine = _replyTo!.senderId == _senderKey;
    final nameColor =
    isMine ? const Color(0xFF3949AB) : _avatarColor(_replyTo!.senderId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: RailLiveColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: nameColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMine ? 'You' : _replyTo!.senderId,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _replyTo!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RailLiveColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearReply,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: RailLiveColors.surface2,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: RailLiveColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
      _messagesRef.orderBy('timestamp', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final senderId = data['senderId']?.toString() ?? 'Unknown';
            final text = data['text']?.toString() ?? '';
            final ts = data['timestamp'] as Timestamp?;
            final coachType = data['coachType']?.toString();
            final isMine = senderId == _senderKey;
            final replyData = data['replyTo'] as Map<String, dynamic>?;

            _messageKeys.putIfAbsent(doc.id, () => GlobalKey());

            Widget? separator;
            if (index == 0 ||
                _isDifferentDay(
                  (docs[index - 1].data()
                  as Map<String, dynamic>)['timestamp'] as Timestamp?,
                  ts,
                )) {
              separator = _buildDateSeparator(ts);
            }

            return Column(
              key: _messageKeys[doc.id],
              children: [
                if (separator != null) separator,
                _SwipeToReply(
                  onSwipe: () => _setReply(_ReplyTo(
                    senderId: senderId,
                    text: text,
                    messageId: doc.id,
                  )),
                  child: _buildMessageBubble(
                    docId: doc.id,
                    senderId: senderId,
                    text: text,
                    timestamp: ts,
                    isMine: isMine,
                    coachType: coachType,
                    replyData: replyData,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined,
                color: Color(0xFF3949AB), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start the conversation',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: RailLiveColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to message fellow\npassengers on this train.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RailLiveColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Try a suggestion below 👇',
            style: TextStyle(
                color: RailLiveColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────────
  Widget _buildMessageBubble({
    required String docId,
    required String senderId,
    required String text,
    required Timestamp? timestamp,
    required bool isMine,
    String? coachType,
    Map<String, dynamic>? replyData,
  }) {
    final color = _avatarColor(senderId);
    final initial = senderId.contains('#')
        ? '#${senderId.split('#').last}'
        : senderId[0].toUpperCase();
    final timeStr =
    timestamp != null ? _formatTime(timestamp.toDate()) : '';

    Widget? coachBadge;
    if (coachType != null) {
      final isReservation = coachType == 'reservation';
      coachBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: (isReservation
              ? const Color(0xFF3949AB)
              : RailLiveColors.success)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isReservation ? '🪑 Reserved' : '👥 General',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isReservation
                ? const Color(0xFF3949AB)
                : RailLiveColors.success,
          ),
        ),
      );
    }

    Widget? replyBlock;
    if (replyData != null) {
      final replyText = replyData['text']?.toString() ?? '';
      final replySender = replyData['senderId']?.toString() ?? '';
      final replyMsgId = replyData['messageId']?.toString() ?? '';
      final isReplySenderMe = replySender == _senderKey;

      replyBlock = GestureDetector(
        onTap: () => _scrollToMessage(replyMsgId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFF3949AB).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isMine
                    ? Colors.white54
                    : const Color(0xFF3949AB),
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReplySenderMe ? 'You' : replySender,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isMine
                      ? Colors.white
                      : const Color(0xFF3949AB),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                replyText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.8)
                      : RailLiveColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      senderId,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                if (coachBadge != null)
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMine ? 0 : 4, right: isMine ? 4 : 0),
                    child: coachBadge,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                    isMine ? const Color(0xFF3949AB) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyBlock != null) replyBlock,
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMine
                              ? Colors.white
                              : RailLiveColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                        fontSize: 10, color: RailLiveColors.textHint),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 6),
              decoration: const BoxDecoration(
                  color: Color(0xFF3949AB), shape: BoxShape.circle),
              child: const Center(
                child: Text('Me',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Date separator ────────────────────────────────────────────────────────────
  Widget _buildDateSeparator(Timestamp? ts) {
    final label = ts != null ? _formatDate(ts.toDate()) : 'Today';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: RailLiveColors.textHint,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: RailLiveColors.surface2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: RailLiveColors.border),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 14, color: RailLiveColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _passengerId == null
                      ? 'Setting up identity…'
                      : 'Message as $_passengerId…',
                  hintStyle: const TextStyle(
                      color: RailLiveColors.textHint, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _sending
                    ? const Color(0xFF3949AB).withValues(alpha: 0.5)
                    : const Color(0xFF3949AB),
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  bool _isDifferentDay(Timestamp? a, Timestamp? b) {
    if (a == null || b == null) return false;
    final da = a.toDate();
    final db = b.toDate();
    return da.day != db.day ||
        da.month != db.month ||
        da.year != db.year;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) return 'Yesterday';
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _SwipeToReply
// ═══════════════════════════════════════════════════════════════════════════════
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;

  const _SwipeToReply({required this.child, required this.onSwipe});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _triggered = false;
  static const double _threshold = 60.0;

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (d.delta.dx < 0 && _dragX == 0) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, _threshold * 1.2);
    });
    if (_dragX >= _threshold && !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (_triggered) widget.onSwipe();
    _triggered = false;
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          if (_dragX > 8)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: (_dragX / _threshold).clamp(0.0, 1.0),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _OnboardingSheet
// ═══════════════════════════════════════════════════════════════════════════════
class _OnboardingSheet extends StatefulWidget {
  final String trainNumber;
  final String trainName;
  final void Function(bool isInside, CoachType? coach) onCompleted;

  const _OnboardingSheet({
    required this.trainNumber,
    required this.trainName,
    required this.onCompleted,
  });

  @override
  State<_OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<_OnboardingSheet> {
  int _step = 0;
  bool? _isInside;
  CoachType? _coach;

  void _selectInside(bool value) {
    setState(() => _isInside = value);
    if (!value) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onCompleted(false, null);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _step = 1);
      });
    }
  }

  void _selectCoach(CoachType type) {
    setState(() => _coach = type);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onCompleted(true, type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      // ← FIX: wrap in SingleChildScrollView so keyboard doesn't overflow
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Train info pill
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1a237e).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.train,
                      size: 16, color: Color(0xFF1a237e)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${widget.trainNumber} · ${widget.trainName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a237e),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Are you currently on this train?',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1a237e)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps us show live info from fellow passengers.',
          style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _bigChoiceBtn(
                icon: '🚆',
                label: 'Yes, I\'m on\nthe train',
                selected: _isInside == true,
                selectedColor: const Color(0xFF3949AB),
                onTap: () => _selectInside(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigChoiceBtn(
                icon: '📍',
                label: 'No, tracking\nfrom outside',
                selected: _isInside == false,
                selectedColor: RailLiveColors.textHint,
                onTap: () => _selectInside(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '🔒 You\'ll be assigned an anonymous identity',
          style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Which coach are you in?',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1a237e)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Helps fellow passengers know seat availability.',
          style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _bigChoiceBtn(
                icon: '🪑',
                label: 'Reservation\n(Sleeper/AC)',
                selected: _coach == CoachType.reservation,
                selectedColor: const Color(0xFF3949AB),
                onTap: () => _selectCoach(CoachType.reservation),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigChoiceBtn(
                icon: '👥',
                label: 'General\n(Unreserved)',
                selected: _coach == CoachType.general,
                selectedColor: RailLiveColors.success,
                onTap: () => _selectCoach(CoachType.general),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _step = 0),
          child: const Text(
            '← Go back',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bigChoiceBtn({
    required String icon,
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.1)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? selectedColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? selectedColor
                    : const Color(0xFF424242),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}