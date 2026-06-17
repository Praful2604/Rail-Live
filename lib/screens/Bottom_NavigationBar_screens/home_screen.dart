import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_live/app_constant.dart';
import 'package:rail_live/screens/Profiles_pages/profile_screen.dart';

import '../../Providers/train_provider.dart';
import '../Profiles_pages/edit_profile_screen.dart';
import '../train_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _trainError;
  @override
  void dispose() {
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchTrain({String? trainNumber, String? trainName}) {
    final trainNo = trainNumber ?? searchController.text.trim();

    // Empty validation
    if (trainNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Train Number"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Train number validation (5 digits)
    if (RegExp(r'^\d+$').hasMatch(trainNo) && trainNo.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Train Number"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    searchController.text = trainNo;
    _focusNode.unfocus();

    context.read<TrainProvider>().clearSuggestions();
    context.read<TrainProvider>().fetchTrain(trainNo, trainName: trainName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: RailLiveColors.primary2,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.directions_railway_filled),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "RailLive",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: "PlusJakartaSans",
              ),
            ),
            Text(
              "Track Your Train in Real Time",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.notifications_active),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_2_rounded),
          ),


        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Consumer<TrainProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search bar ──────────────────────────────────────
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => provider.searchTrain(value),
                    onSubmitted: (_) => _searchTrain(),
                    decoration: InputDecoration(
                      hintText: "Search Train Name or Number",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                        ),
                        onPressed: _searchTrain,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // ── Suggestion dropdown ─────────────────────────────
                if (provider.suggestions.isNotEmpty)
                  Material(
                    elevation: 0,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: provider.suggestions.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final train = provider.suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.train,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              title: Text(
                                train['train_name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "No: ${train['train_number']}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () => _searchTrain(
                                trainNumber: train['train_number'],
                                trainName: train['train_name'],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                // ── Main scrollable content ─────────────────────────
              Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Train result
                          _buildTrainResult(provider),

                          const SizedBox(height: 20),

                          // Recent searches
                          _buildRecentSearches(provider),

                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),


                _buildAiBanner(),
                const SizedBox(height: 55),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrainResult(TrainProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (provider.trainData == null) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Search a train to see details",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (provider.trainData == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainDetailScreen(
              trainData: provider.trainData!,
              trainNumber: provider.trainData?['trainNumber']?.toString() ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.trainData!['trainName']?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Train No: ${provider.trainData!['trainNumber'] ?? 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.train_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${provider.trainData!['origin'] ?? 'N/A'} → ${provider.trainData!['destination'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RailLiveColors.primary2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Tap to view route details",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(TrainProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Searches",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: provider.clearRecentSearches,
              child: Text(
                "Clear all",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 0,
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.recentSearches.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = provider.recentSearches[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: RailLiveColors.primary2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: RailLiveColors.primary2,
                      ),
                    ),
                    title: Text(
                      item['train_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    trailing: Icon(
                      Icons.north_west_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () => _searchTrain(
                      trainNumber: item['train_number'],
                      trainName: item['train_name'],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiBanner() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: RailLiveColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.smart_toy_rounded, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Travel Assistant",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Will my train reach on time?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
