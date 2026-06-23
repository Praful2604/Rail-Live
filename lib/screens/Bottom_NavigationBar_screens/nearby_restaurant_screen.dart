import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/screens/restaurant/my_orders_screen.dart';
import 'package:rail_live/screens/train_details/widgets/restaurant_card.dart';


import '../../Providers/restaurant_provider.dart';
import '../../app_constant.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  State<NearbyRestaurantsScreen> createState() =>
      _NearbyRestaurantsScreenState();
}

class _NearbyRestaurantsScreenState extends State<NearbyRestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadNearbyRestaurants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: RailLiveColors.primary,
            onRefresh: provider.loadNearbyRestaurants,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App bar ──────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: RailLiveColors.primary,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 40,
                      ),
                      tooltip: 'My Orders',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>MyOrdersScreen()));
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nearby Restaurants',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (provider.nearestStation != null)
                              Text(
                                provider.nearestStation!.stationName,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                          ],
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
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40, right: 16),
                          child: Icon(
                            Icons.train_rounded,
                            color: Colors.white.withOpacity(0.08),
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Station info banner ───────────────────────────────────
                if (provider.status == NearbyRestaurantStatus.loaded)
                  SliverToBoxAdapter(
                    child: _StationInfoBanner(provider: provider),
                  ),

                // ── Search bar ────────────────────────────────────────────
                if (provider.status == NearbyRestaurantStatus.loaded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: provider.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search restaurants or dishes…',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: RailLiveColors.primary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: RailLiveColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: RailLiveColors.primary2,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Body content ──────────────────────────────────────────
                _buildBody(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(RestaurantProvider provider) {
    switch (provider.status) {
      case NearbyRestaurantStatus.initial:
      case NearbyRestaurantStatus.locating:
        return SliverFillRemaining(child: _LoadingState());

      case NearbyRestaurantStatus.error:
        return SliverFillRemaining(
          child: _ErrorState(
            message: provider.errorMessage,
            isPermanentlyDenied: provider.isPermanentlyDenied,
            onRetry: provider.loadNearbyRestaurants,
          ),
        );

      case NearbyRestaurantStatus.noStationNearby:
        return const SliverFillRemaining(child: _NoStationState());

      case NearbyRestaurantStatus.loaded:
        final list = provider.restaurants;
        if (list.isEmpty) {
          return const SliverFillRemaining(child: _EmptySearchState());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == list.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Showing all nearby restaurants • Sorted by distance',
                      style: TextStyle(
                        color: RailLiveColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return RestaurantCard(restaurant: list[index]);
            },
            childCount: list.length + 1,
          ),
        );
    }
  }
}

// ── Auxiliary widgets ─────────────────────────────────────────────────────────

class _StationInfoBanner extends StatelessWidget {
  final RestaurantProvider provider;
  const _StationInfoBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RailLiveColors.primary, Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: RailLiveColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.train_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.nearestStation!.stationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You are ${provider.stationDistanceKm!.toStringAsFixed(2)} km away',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.restaurants.length} places',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: RailLiveColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: RailLiveColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Finding your location…',
            style: TextStyle(
              color: RailLiveColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Detecting nearest railway station',
            style: TextStyle(
              color: RailLiveColors.textHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isPermanentlyDenied;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.isPermanentlyDenied,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.location_off_rounded,
                size: 40,
                color: RailLiveColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Error',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: RailLiveColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RailLiveColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (isPermanentlyDenied)
              ElevatedButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RailLiveColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RailLiveColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoStationState extends StatelessWidget {
  const _NoStationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.train_outlined,
                size: 40,
                color: RailLiveColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Nearby Station Found',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: RailLiveColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You are more than 5 km from any known railway station. Move closer to a station to discover nearby restaurants.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RailLiveColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: RailLiveColors.textHint),
          SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(
              color: RailLiveColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different dish or restaurant name',
            style: TextStyle(
              color: RailLiveColors.textHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}