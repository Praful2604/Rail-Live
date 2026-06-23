import 'package:flutter/material.dart';
import 'package:rail_live/models/restaurant_model.dart';


import '../../../app_constant.dart';
import '../../restaurant/restaurant_details_screen.dart';

/// A rich card displaying restaurant details in a railway-themed design.
class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  // Gradient image placeholder colours cycling through 8 options.
  static const List<List<Color>> _gradients = [
    [RailLiveColors.primary, Color(0xFF283593)],
    [RailLiveColors.success, Color(0xFF00695C)],
    [RailLiveColors.languageIcon, Color(0xFF6A1B9A)],
    [RailLiveColors.warning, Color(0xFFD84315)],
    [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    [Color(0xFF880E4F), Color(0xFFAD1457)],
    [RailLiveColors.primary2, Color(0xFF1565C0)],
    [Color(0xFF33691E), Color(0xFF558B2F)],
  ];

  List<Color> get _gradient =>
      _gradients[restaurant.id % _gradients.length];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: RailLiveColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / banner ───────────────────────────────────────────
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white30,
                        size: 56,
                      ),
                    ),
                  ),
                  // Distance badge – top right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _DistanceBadge(
                      label:
                      '${restaurant.distanceFromStationKm.toStringAsFixed(1)} km\nfrom station',
                    ),
                  ),
                  // User distance badge – top left
                  if (restaurant.distanceFromUserKm != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _DistanceBadge(
                        label:
                        '${restaurant.distanceFromUserKm!.toStringAsFixed(1)} km\nfrom you',
                        color: RailLiveColors.success,
                      ),
                    ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: RailLiveColors.primary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingChip(rating: restaurant.rating),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Station row
                  Row(
                    children: [
                      const Icon(
                        Icons.train,
                        size: 14,
                        color: RailLiveColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.stationName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: RailLiveColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Hours + price row
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: RailLiveColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.openingHours,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: RailLiveColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RailLiveColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.priceRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: RailLiveColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Divider(height: 1, color: RailLiveColors.border),
                  const SizedBox(height: 10),

                  // Popular items label
                  Text(
                    'Popular Items',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: RailLiveColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: restaurant.menu
                        .take(3)
                        .map((m) => _MenuChip(item: m.item, price: m.price))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
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
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: Text(restaurant.contact),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RailLiveColors.primary,
                        side: const BorderSide(color: RailLiveColors.primary2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _DistanceBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DistanceBadge({
    required this.label,
    this.color = RailLiveColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  Color get _ratingColor {
    if (rating >= 4.5) return RailLiveColors.success;
    if (rating >= 4.0) return const Color(0xFF388E3C);
    if (rating >= 3.5) return RailLiveColors.notifIcon;
    return RailLiveColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _ratingColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  final String item;
  final int price;
  const _MenuChip({required this.item, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RailLiveColors.surface2,
        border: Border.all(color: RailLiveColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$item • ₹$price',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: RailLiveColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}