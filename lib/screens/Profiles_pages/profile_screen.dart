import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';

import '../setting_pages/setting_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                actions: [Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                            icon:  Icon(Icons.settings, color: RailLiveColors.warning, size: 28)),
                )
          ],
                expandedHeight: 260,
                pinned: true,
                elevation: 0,
                backgroundColor: RailLiveColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          RailLiveColors.primary,
                          RailLiveColors.primary2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: user["photoUrl"] != null
                                ? NetworkImage(user["photoUrl"])
                                : null,
                            child: user["photoUrl"] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: RailLiveColors.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user["name"] ?? "Rail Live User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user["email"] ?? "",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// Stats
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              "Trips",
                              "${user["trips"] ?? 0}",
                              Icons.train,
                              RailLiveColors.qaBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              "Bookings",
                              "${user["bookings"] ?? 0}",
                              Icons.confirmation_number,
                              RailLiveColors.qaAmber,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _menuTile(Icons.edit, "Edit Profile", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(userData: user),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.logout),
                          label: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RailLiveColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RailLiveColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: bg, child: Icon(icon)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
