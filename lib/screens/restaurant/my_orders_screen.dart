import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_constant.dart'; // RailLiveColors

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: RailLiveColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'My Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [RailLiveColors.primary, Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white.withOpacity(0.08),
                      size: 90,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────
          if (user == null)
            const SliverFillRemaining(child: _NotLoggedIn())
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _OrdersList(userId: user.uid),
            ),
        ],
      ),
    );
  }
}

// ── Orders List ───────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final String userId;
  const _OrdersList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('placedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: ordersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: _LoadingState());
        }

        if (snapshot.hasError) {
          return const SliverFillRemaining(child: _ErrorState());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _OrderCard(
                data: data,
                docId: docs[index].id,
                userId: FirebaseAuth.instance.currentUser!.uid,
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _OrderCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isCancelling = false;

  // ── Cancel Order ──────────────────────────────────────────────────

  Future<void> _cancelOrder() async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: RailLiveColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will cancel your order. This action cannot be undone.',
          style: TextStyle(
            color: RailLiveColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Order',
              style: TextStyle(
                color: RailLiveColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RailLiveColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update in users/{uid}/orders/{docId}
      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('orders')
            .doc(widget.docId),
        {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        },
      );

      // Mirror update in top-level orders/{docId}
      batch.update(
        FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.docId),
        {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Order cancelled successfully.'),
              ],
            ),
            backgroundColor: RailLiveColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to cancel order. Try again.'),
            backgroundColor: RailLiveColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.data['items'] as List<dynamic>? ?? []);
    final placedAt = (widget.data['placedAt'] as Timestamp?)?.toDate();
    final status = widget.data['status'] as String? ?? 'placed';
    final isCancellable = status == 'placed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [RailLiveColors.primary, Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data['restaurantName'] ?? '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.train_rounded,
                              color: Colors.white60, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.data['stationName'] ?? '—',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // ── Passenger Info Row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _InfoPill(
                  icon: Icons.person_outline_rounded,
                  label: widget.data['passengerName'] ?? '—',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.train_rounded,
                  label: widget.data['trainNumber'] ?? '—',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.event_seat_rounded,
                  label:
                  '${widget.data['coach'] ?? '—'} · ${widget.data['seatNumber'] ?? '—'}',
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, color: RailLiveColors.border),
          ),

          // ── Items List ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: items.map((item) {
                final i = item as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: RailLiveColors.success, width: 1.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: RailLiveColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${i['name']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: RailLiveColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${i['quantity']}x',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RailLiveColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${i['subtotal']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RailLiveColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Footer: Total + timestamp ────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: RailLiveColors.primary4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Placed on',
                      style: TextStyle(
                        fontSize: 10,
                        color: RailLiveColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      placedAt != null ? _formatDate(placedAt) : '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RailLiveColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: RailLiveColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${widget.data['totalAmount'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: RailLiveColors.primary,
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: RailLiveColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RailLiveColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: RailLiveColors.background,
                    border: Border(
                      bottom: BorderSide(color: RailLiveColors.border, width: 0.5),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 18, color: RailLiveColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'DELIVERY OTP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RailLiveColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share this code with the delivery\nperson when your order arrives.',
                        style: TextStyle(
                          fontSize: 13,
                          color: RailLiveColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── OTP digit boxes ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.data['deliveryOtp']
                            .toString()
                            .split('')
                            .map<Widget>((digit) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: RailLiveColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: RailLiveColors.border, width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: RailLiveColors.textPrimary,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),

                      const SizedBox(height: 14),

                      // ── Warning note ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: RailLiveColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: RailLiveColors.warning.withOpacity(0.25),
                              width: 0.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15, color: RailLiveColors.warning),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Do not share until food is delivered.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: RailLiveColors.warning,
                                  height: 1.4,
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
            ),
          ),
          // ── Cancel Button (only for 'placed' orders) ─────────────────
          if (isCancellable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _cancelOrder,
                  icon: _isCancelling
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: RailLiveColors.error,
                    ),
                  )
                      : const Icon(Icons.cancel_outlined, size: 16),
                  label: Text(_isCancelling ? 'Cancelling…' : 'Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RailLiveColors.error,
                    side: const BorderSide(
                        color: RailLiveColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $period';
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'delivered':
        return RailLiveColors.success;
      case 'cancelled':
        return RailLiveColors.error;
      default:
        return RailLiveColors.accent;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Pill ─────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: RailLiveColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RailLiveColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: RailLiveColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RailLiveColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error / Loading / Not Logged In states ────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RailLiveColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 38, color: RailLiveColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: RailLiveColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your food orders will appear here\nafter you place them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: RailLiveColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: RailLiveColors.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RailLiveColors.alertErrorBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 38, color: RailLiveColors.error),
          ),
          const SizedBox(height: 16),
          const Text(
            'Could not load orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: RailLiveColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(
              fontSize: 13,
              color: RailLiveColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RailLiveColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 38, color: RailLiveColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not logged in',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: RailLiveColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please log in to view your orders.',
            style: TextStyle(
              fontSize: 13,
              color: RailLiveColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}