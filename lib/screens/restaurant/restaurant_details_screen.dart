import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rail_live/models/restaurant_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../app_constant.dart';
import '../../config/env.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETUP INSTRUCTIONS
// ─────────────────────────────────────────────────────────────────────────────
// 1. Add to pubspec.yaml:
//      razorpay_flutter: ^1.3.6
//
// 2. Android — android/app/build.gradle:
//      minSdkVersion 21
//
// 3. iOS — ios/Podfile:
//      platform :ios, '10.0'
//
// 4. Replace 'YOUR_RAZORPAY_KEY_ID' below with your actual key from
//    https://dashboard.razorpay.com/app/website-app-settings/api-keys
// ─────────────────────────────────────────────────────────────────────────────



// ── Main Screen ───────────────────────────────────────────────────────────────

class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final Map<String, int> _cart = {};

  int get _totalItems => _cart.values.fold(0, (sum, q) => sum + q);

  int get _totalPrice {
    int total = 0;
    for (final entry in _cart.entries) {
      final menuItem =
      widget.restaurant.menu.firstWhere((m) => m.item == entry.key);
      total += menuItem.price * entry.value;
    }
    return total;
  }

  void _increment(MenuItem item) =>
      setState(() => _cart[item.item] = (_cart[item.item] ?? 0) + 1);

  void _decrement(MenuItem item) {
    setState(() {
      final current = _cart[item.item] ?? 0;
      if (current <= 1) {
        _cart.remove(item.item);
      } else {
        _cart[item.item] = current - 1;
      }
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  void _placeOrder() {
    if (_cart.isEmpty) return;

    final lines = _cart.entries.map((e) {
      final menuItem =
      widget.restaurant.menu.firstWhere((m) => m.item == e.key);
      return '${e.value}x ${e.key} — ₹${menuItem.price * e.value}';
    }).join('\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderConfirmSheet(
        restaurant: widget.restaurant,
        cart: Map.from(_cart),
        orderLines: lines,
        total: _totalPrice,
        onConfirm: (String otp, String paymentId) {
          _clearCart();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Payment successful! Order placed.'),
                ],
              ),
              backgroundColor: RailLiveColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
          // Show delivery OTP dialog
          _showDeliveryOtpDialog(otp, paymentId);
        },
      ),
    );
  }

  // ── Delivery OTP Dialog ───────────────────────────────────────────────────

  void _showDeliveryOtpDialog(String otp, String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: RailLiveColors.surface,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: RailLiveColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: RailLiveColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: RailLiveColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this OTP with the delivery person when your order arrives.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: RailLiveColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: RailLiveColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: RailLiveColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'DELIVERY OTP',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: RailLiveColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otp,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: RailLiveColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Payment ID reference
            Text(
              'Payment ID: $paymentId',
              style: const TextStyle(
                fontSize: 11,
                color: RailLiveColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RailLiveColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    final gradients = [
      [RailLiveColors.primary, RailLiveColors.primary2],
      [RailLiveColors.success, const Color(0xFF00695C)],
      [RailLiveColors.languageIcon, const Color(0xFF6A1B9A)],
      [RailLiveColors.primary2, RailLiveColors.primary3],
      [const Color(0xFF880E4F), const Color(0xFFAD1457)],
    ];
    final grad = gradients[restaurant.id % gradients.length];

    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero App Bar ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: RailLiveColors.primary2,
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
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: grad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white.withOpacity(0.12),
                            size: 120,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.train_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    restaurant.stationName,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _ratingColor(restaurant.rating),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 3),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Info chips ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: restaurant.openingHours,
                      ),
                      _InfoChip(
                        icon: Icons.currency_rupee_rounded,
                        label: restaurant.priceRange,
                      ),
                      _InfoChip(
                        icon: Icons.location_on_rounded,
                        label:
                        '${restaurant.distanceFromStationKm.toStringAsFixed(1)} km from station',
                      ),
                      if (restaurant.distanceFromUserKm != null)
                        _InfoChip(
                          icon: Icons.near_me_rounded,
                          label:
                          '${restaurant.distanceFromUserKm!.toStringAsFixed(1)} km from you',
                          color: RailLiveColors.success,
                        ),
                    ],
                  ),
                ),
              ),

              // ── Contact ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${restaurant.contact}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text(restaurant.contact),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RailLiveColors.primary,
                      side: const BorderSide(
                          color: RailLiveColors.primary2, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              // ── Menu header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: RailLiveColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RailLiveColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${restaurant.menu.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: RailLiveColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Menu list ───────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = restaurant.menu[index];
                    final qty = _cart[item.item] ?? 0;
                    return _MenuItemTile(
                      item: item,
                      quantity: qty,
                      onIncrement: () => _increment(item),
                      onDecrement: () => _decrement(item),
                    );
                  },
                  childCount: restaurant.menu.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Sticky Order Bar ────────────────────────────────────────
          if (_totalItems > 0)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _OrderBar(
                totalItems: _totalItems,
                totalPrice: _totalPrice,
                onClear: _clearCart,
                onPlaceOrder: _placeOrder,
              ),
            ),
        ],
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 4.5) return RailLiveColors.success;
    if (rating >= 4.0) return const Color(0xFF388E3C);
    if (rating >= 3.5) return RailLiveColors.notifIcon;
    return RailLiveColors.warning;
  }
}

// ── Menu Item Tile ────────────────────────────────────────────────────────────

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MenuItemTile({
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border:
              Border.all(color: RailLiveColors.success, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: RailLiveColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RailLiveColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.price}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RailLiveColors.primary,
                  ),
                ),
              ],
            ),
          ),
          quantity == 0
              ? _AddButton(onTap: onIncrement)
              : _QuantityStepper(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: RailLiveColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: RailLiveColors.primary.withOpacity(0.3), width: 1),
        ),
        child: const Text(
          'ADD',
          style: TextStyle(
            color: RailLiveColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RailLiveColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Order Bar ─────────────────────────────────────────────────────────────────

class _OrderBar extends StatelessWidget {
  final int totalItems;
  final int totalPrice;
  final VoidCallback onClear;
  final VoidCallback onPlaceOrder;

  const _OrderBar({
    required this.totalItems,
    required this.totalPrice,
    required this.onClear,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RailLiveColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalItems ${totalItems == 1 ? 'item' : 'items'} added',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹$totalPrice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white60, size: 22),
            tooltip: 'Clear cart',
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onPlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: RailLiveColors.surface,
              foregroundColor: RailLiveColors.primary,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Place Order',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Confirm Sheet ───────────────────────────────────────────────────────

class _OrderConfirmSheet extends StatefulWidget {
  final RestaurantModel restaurant;
  final Map<String, int> cart;
  final String orderLines;
  final int total;

  /// Called with (otp, razorpayPaymentId) after successful payment + Firestore save
  final void Function(String otp, String paymentId) onConfirm;

  const _OrderConfirmSheet({
    required this.restaurant,
    required this.cart,
    required this.orderLines,
    required this.total,
    required this.onConfirm,
  });

  @override
  State<_OrderConfirmSheet> createState() => _OrderConfirmSheetState();
}

class _OrderConfirmSheetState extends State<_OrderConfirmSheet> {
  // ── Form controllers ──────────────────────────────────────────────────────
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _coachCtrl = TextEditingController();
  final TextEditingController _seatCtrl = TextEditingController();
  final TextEditingController _trainnoCtrl = TextEditingController();

  // ── Razorpay ──────────────────────────────────────────────────────────────
  late final Razorpay _razorpay;
  bool _isSaving = false;

  // Stored temporarily between Razorpay open → success handler
  String? _pendingOtp;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _coachCtrl.dispose();
    _seatCtrl.dispose();
    _trainnoCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ── OTP generator ─────────────────────────────────────────────────────────

  String _generateOtp() {
    final rand = Random.secure();
    return (1000 + rand.nextInt(9000)).toString();
  }

  // ── Firestore save (called AFTER payment succeeds) ────────────────────────

  Future<void> _saveOrderToFirestore({
    required String otp,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final List<Map<String, dynamic>> items = widget.cart.entries.map((e) {
      final menuItem =
      widget.restaurant.menu.firstWhere((m) => m.item == e.key);
      return {
        'name': e.key,
        'quantity': e.value,
        'unitPrice': menuItem.price,
        'subtotal': menuItem.price * e.value,
      };
    }).toList();

    final orderData = {
      // ── Passenger ──────────────────────────────────────────────────
      'passengerName': _nameCtrl.text.trim(),
      'trainNumber': _trainnoCtrl.text.trim(),
      'coach': _coachCtrl.text.trim().toUpperCase(),
      'seatNumber': _seatCtrl.text.trim(),

      // ── Restaurant ─────────────────────────────────────────────────
      'restaurantId': widget.restaurant.id,
      'restaurantName': widget.restaurant.name,
      'stationName': widget.restaurant.stationName,

      // ── Order ──────────────────────────────────────────────────────
      'items': items,
      'totalAmount': widget.total,

      // ── Payment (Razorpay) ─────────────────────────────────────────
      'payment': {
        'method': 'razorpay',
        'paymentId': razorpayPaymentId,
        'orderId': razorpayOrderId,
        'signature': razorpaySignature,
        'status': 'paid',
        'amountPaid': widget.total,
        'currency': 'INR',
        'paidAt': FieldValue.serverTimestamp(),
      },

      // ── User ───────────────────────────────────────────────────────
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? '',

      // ── Delivery OTP ───────────────────────────────────────────────
      'deliveryOtp': otp,
      'otpVerified': false,

      // ── Meta ───────────────────────────────────────────────────────
      'status': 'paid',
      'placedAt': FieldValue.serverTimestamp(),
    };

    final docId = FirebaseFirestore.instance.collection('orders').doc().id;
    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(docId),
      orderData,
    );

    batch.set(
      FirebaseFirestore.instance.collection('orders').doc(docId),
      orderData,
    );

    await batch.commit();
  }

  // ── Razorpay event handlers ───────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      await _saveOrderToFirestore(
        otp: _pendingOtp!,
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // close sheet
      widget.onConfirm(_pendingOtp!, response.paymentId ?? '');
    } catch (e) {
      _showError('Payment succeeded but order save failed. Contact support.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
      _pendingOtp = null;
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    _pendingOtp = null;

    final msg = response.message ?? 'Payment failed. Please try again.';
    _showError(msg);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Open Razorpay checkout ────────────────────────────────────────────────

  void _openRazorpay() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in to place an order.');
      return;
    }

    // Generate OTP before opening Razorpay so it's ready on success
    _pendingOtp = _generateOtp();

    final options = <String, dynamic>{
      'key': Env.razorpayKeyId,

      // Amount in paise (₹1 = 100 paise)
      'amount': widget.total * 100,
      'currency': 'INR',

      'name': 'RailLive Food',
      'description': 'Order at ${widget.restaurant.name}',

      // Pre-fill user info
      'prefill': {
        'name': _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : (user.displayName ?? ''),
        'email': user.email ?? '',
        'contact': user.phoneNumber ?? '',
      },

      // Theme
      'theme': {
        'color': '#1565C0', // matches RailLiveColors.primary — change if needed
      },

      // Notes stored with the payment on Razorpay dashboard
      'notes': {
        'restaurantName': widget.restaurant.name,
        'stationName': widget.restaurant.stationName,
        'trainNumber': _trainnoCtrl.text.trim(),
        'coach': _coachCtrl.text.trim().toUpperCase(),
        'seat': _seatCtrl.text.trim(),
      },

      // External wallets to support
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showError('Could not open payment gateway. Please try again.');
      _pendingOtp = null;
    }
  }

  // ── Validate and trigger payment ──────────────────────────────────────────

  void _onConfirmTapped() {
    if (_nameCtrl.text.trim().isEmpty ||
        _trainnoCtrl.text.trim().isEmpty ||
        _coachCtrl.text.trim().isEmpty ||
        _seatCtrl.text.trim().isEmpty) {
      _showError('Please fill all passenger details.');
      return;
    }
    _openRazorpay();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: RailLiveColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Text field builder ────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: RailLiveColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: RailLiveColors.primary2, width: 2),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: RailLiveColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Confirm Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: RailLiveColors.primary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.restaurant.name,
              style: const TextStyle(
                color: RailLiveColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            // ── Passenger Details ─────────────────────────────────────
            const Text(
              'Passenger Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RailLiveColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller: _nameCtrl,
              label: 'Passenger Name',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller: _trainnoCtrl,
              label: 'Train Number',
              icon: Icons.train_rounded,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _coachCtrl,
                    label: 'Coach',
                    icon: Icons.directions_railway_rounded,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _seatCtrl,
                    label: 'Seat No',
                    icon: Icons.event_seat_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Payment method banner ─────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF072654).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF072654).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  // Razorpay "R" badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF072654),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay via Razorpay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: RailLiveColors.textPrimary,
                          ),
                        ),
                        Text(
                          'UPI · Cards · Wallets · Net Banking',
                          style: TextStyle(
                            fontSize: 11,
                            color: RailLiveColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: RailLiveColors.textHint),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Divider(color: RailLiveColors.border),
            const SizedBox(height: 10),

            // ── Order Summary ─────────────────────────────────────────
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RailLiveColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            ...widget.orderLines.split('\n').map(
                  (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 6, color: RailLiveColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: RailLiveColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: RailLiveColors.border),
            const SizedBox(height: 10),

            // ── Total ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: RailLiveColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${widget.total}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: RailLiveColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Secure payment via Razorpay',
              style: const TextStyle(
                color: RailLiveColors.textHint,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            // ── Pay button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onConfirmTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RailLiveColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  RailLiveColors.primary.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ₹${widget.total}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = RailLiveColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}